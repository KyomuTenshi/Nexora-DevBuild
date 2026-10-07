import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nexora/data/api/response_cache.dart';
import 'package:nexora/domain/errors/app_exception.dart';

class _CacheEntry {
  _CacheEntry(this.savedAt, this.future);

  final DateTime savedAt;
  final Future<Map<String, dynamic>> future;
}

/// Универсальный HTTP-клиент для REST API с JSON-ответами. Он знает про сеть,
/// но ничего не знает про экраны и модели приложения.
///
/// Что делает:
/// - таймаут запроса, чтобы экран не «крутился» вечно;
/// - переводит сбои сети и коды ответа в наши [AppException];
/// - не даёт слать запросы чаще, чем раз в [minGap] (защита от лимитов API);
/// - на HTTP 429 повторяет запрос после паузы;
/// - кэширует успешные ответы в памяти на [cacheTtl];
/// - offline-first: каждый удачный ответ сохраняется в [cache] (на диск), а
///   если сети нет или сервер недоступен, отдаёт последний сохранённый ответ
///   и сообщает об этом через [onStaleData].
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? client,
    this.headers = const {'Accept': 'application/json'},
    this.timeout = const Duration(seconds: 12),
    this.minGap = const Duration(milliseconds: 150),
    this.retryDelay = const Duration(seconds: 1),
    this.maxRetries = 1,
    this.cacheTtl = const Duration(minutes: 5),
    this.cache,
    this.onStaleData,
    this.onFreshData,
  }) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;
  final Map<String, String> headers;
  final Duration timeout;
  final Duration minGap;
  final Duration retryDelay;
  final int maxRetries;
  final Duration cacheTtl;

  /// Постоянное хранилище ответов (на диске). Если null, офлайн-режима нет.
  final ResponseCache? cache;

  /// Вызывается, когда вместо свежего ответа отдан сохранённый.
  final void Function()? onStaleData;

  /// Вызывается, когда получен свежий ответ от сервера.
  final void Function()? onFreshData;

  final Map<String, _CacheEntry> _memory = {};
  DateTime _nextSlot = DateTime.fromMillisecondsSinceEpoch(0);

  /// GET-запрос, который возвращает уже разобранный JSON-объект.
  Future<Map<String, dynamic>> getJson(
      String path, [
        Map<String, String>? query,
      ]) {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final key = uri.toString();

    final hit = _memory[key];
    if (hit != null && DateTime.now().difference(hit.savedAt) < cacheTtl) {
      return hit.future;
    }

    final future = _fetch(uri);
    _memory[key] = _CacheEntry(DateTime.now(), future);
    // Неудачный ответ в кэше не храним, иначе «Повторить» вернёт ту же ошибку
    future.then<void>((_) {}, onError: (Object _) {
      if (_memory[key]?.future == future) _memory.remove(key);
    });
    return future;
  }

  /// Забывает кэш в памяти. Сохранённые на диске ответы остаются: они нужны
  /// как раз на случай, если после этого сети не окажется.
  void clearCache() => _memory.clear();

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

  /// Сначала сеть. Если она не помогла, берём сохранённый на диске ответ.
  Future<Map<String, dynamic>> _fetch(Uri uri) async {
    final key = uri.toString();
    try {
      final text = await _fetchLive(uri);
      final json = _decode(text);
      await _save(key, text);
      onFreshData?.call();
      return json;
    } on AppException catch (error) {
      if (!_canUseSaved(error)) rethrow;
      final saved = cache?.read(key);
      if (saved == null) rethrow;
      try {
        final json = _decode(saved);
        onStaleData?.call();
        return json;
      } on AppException {
        // Сохранённые данные оказались повреждены: показываем исходную ошибку
        throw error;
      }
    }
  }

  /// Сохранённые данные годятся, когда виновата сеть или сервер, а не формат.
  bool _canUseSaved(AppException error) => switch (error) {
    NetworkException() || RateLimitException() => true,
    ServerException(:final statusCode) => statusCode >= 500,
    ParseException() => false,
  };

  Future<void> _save(String key, String body) async {
    try {
      await cache?.write(key, body);
    } catch (_) {
      // Не удалось записать на диск: это не должно ломать показ данных
    }
  }

  Future<String> _fetchLive(Uri uri) async {
    for (var attempt = 0;; attempt++) {
      await _waitForSlot();

      final http.Response response;
      try {
        response = await _http.get(uri, headers: headers).timeout(timeout);
      } on TimeoutException {
        throw const NetworkException('Сервер не ответил вовремя');
      } catch (_) {
        // SocketException, обрыв, нет DNS и т. п.
        throw const NetworkException('Нет подключения к интернету');
      }

      final code = response.statusCode;
      if (code == 200) {
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      }

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

  Map<String, dynamic> _decode(String text) {
    try {
      final body = jsonDecode(text);
      if (body is Map<String, dynamic>) return body;
      throw const ParseException('Ожидался JSON-объект');
    } on FormatException {
      throw const ParseException('Ответ не является корректным JSON');
    }
  }
}