import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/domain/errors/app_exception.dart';

class _CacheEntry {
  _CacheEntry(this.savedAt, this.future);

  final DateTime savedAt;
  final Future<Map<String, dynamic>> future;
}

/// Низкоуровневый HTTP-клиент для Jikan. Он знает про сеть, но ничего не знает
/// про экраны и модели приложения.
///
/// Что делает:
/// - таймаут запроса, чтобы экран не «крутился» вечно;
/// - переводит сбои сети и коды ответа в наши [AppException];
/// - соблюдает лимит Jikan (около 3 запросов в секунду): запросы стартуют
///   не чаще, чем раз в [minGap];
/// - на HTTP 429 один раз повторяет запрос после паузы;
/// - кэширует успешные ответы на [cacheTtl], одинаковые запросы не ходят в сеть.
class JikanClient {
  JikanClient({
    http.Client? client,
    this.baseUrl = kJikanBaseUrl,
    this.timeout = const Duration(seconds: 12),
    this.minGap = const Duration(milliseconds: 350),
    this.retryDelay = const Duration(seconds: 1),
    this.maxRetries = 1,
    this.cacheTtl = const Duration(minutes: 5),
  }) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;
  final Duration timeout;
  final Duration minGap;
  final Duration retryDelay;
  final int maxRetries;
  final Duration cacheTtl;

  final Map<String, _CacheEntry> _cache = {};
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  /// GET-запрос, который возвращает уже разобранный JSON-объект.
  Future<Map<String, dynamic>> getJson(
      String path, [
        Map<String, String>? query,
      ]) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final key = uri.toString();

    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.savedAt) < cacheTtl) {
      return hit.future;
    }

    final future = _fetch(uri);
    _cache[key] = _CacheEntry(DateTime.now(), future);
    // Неудачный ответ в кэше не храним, иначе «Повторить» вернёт ту же ошибку
    future.then<void>((_) {}, onError: (Object _) {
      if (_cache[key]?.future == future) _cache.remove(key);
    });
    return future;
  }

  void clearCache() => _cache.clear();

  void close() => _http.close();

  /// Резервируем «слот» старта запроса: следующий запрос стартует не раньше,
  /// чем через [minGap] после предыдущего. Параллельность при этом сохраняется.
  Future<void> _waitForSlot() async {
    final now = DateTime.now();
    final start = _nextSlot.isAfter(now) ? _nextSlot : now;
    _nextSlot = start.add(minGap);
    final wait = start.difference(now);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  Future<Map<String, dynamic>> _fetch(Uri uri) async {
    for (var attempt = 0;; attempt++) {
      await _waitForSlot();

      final http.Response response;
      try {
        response = await _http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(timeout);
      } on TimeoutException {
        dev.log('Таймаут: $uri', name: 'JikanClient');
        throw const NetworkException('Сервер не ответил вовремя');
      } catch (e) {
        // SocketException, обрыв, нет DNS и т. п.
        dev.log('Сбой запроса $uri: $e', name: 'JikanClient');
        throw const NetworkException('Нет подключения к интернету');
      }

      final code = response.statusCode;
      if (code == 200) return _decode(response);

      if (code == 429) {
        if (attempt < maxRetries) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        throw const RateLimitException();
      }
      throw ServerException(code);
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) return body;
      throw const ParseException('Ожидался JSON-объект');
    } on FormatException {
      throw const ParseException('Ответ не является корректным JSON');
    }
  }
}