import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/video_source.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/units_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Открывает плеер серии.
void openWatch(BuildContext context, MediaItem item, {required int episode}) {
  context.pushNamed(
    AppRoute.watch,
    pathParameters: {'id': '${item.id}', 'episode': '$episode'},
    extra: item,
  );
}

const List<double> _speeds = [0.5, 0.75, 1, 1.25, 1.5, 2];

/// Плеер серии: перемотка, ±10 секунд двойным касанием, скорость,
/// поворот экрана, продолжение с того же места, переход между сериями.
/// Серия засчитывается, когда просмотрено 90 %.
class WatchPage extends ConsumerStatefulWidget {
  const WatchPage({super.key, required this.item, required this.episode});

  final MediaItem item;
  final int episode;

  @override
  ConsumerState<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends ConsumerState<WatchPage> {
  late int _episode;
  late final SharedPreferences _prefs;

  VideoPlayerController? _controller;
  VideoSource? _source;
  Object? _error;

  bool _controlsVisible = true;
  bool _landscape = false;
  double _speed = 1;

  /// Серия уже засчитана, и принесло ли это очки.
  bool _counted = false;
  bool _rewarded = false;

  /// Положение ползунка, пока его тянут пальцем (миллисекунды).
  double? _dragMs;

  /// Подсказка перемотки по двойному касанию: «−10» или «+10».
  String? _seekHint;
  Offset? _doubleTapAt;

  /// Номер загрузки: ответ устаревшей загрузки (после смены серии) игнорируется.
  int _loadId = 0;
  Timer? _hideTimer;
  Timer? _hintTimer;
  Timer? _saveTimer;

  MediaItem get _item => widget.item;

  String get _positionKey => 'watch_pos_${_item.id}_$_episode';

  bool get _isFinished {
    final v = _controller?.value;
    return v != null &&
        v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration;
  }

  bool get _hasNext {
    final total = ref.read(unitsTotalProvider(_item));
    return total == 0 || _episode < total;
  }

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _prefs = ref.read(prefsProvider);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable().catchError((Object _) {});
    _saveTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _savePosition(),
    );
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hintTimer?.cancel();
    _saveTimer?.cancel();
    _savePosition();
    _controller?.removeListener(_onVideo);
    unawaited(_controller?.dispose());
    WakelockPlus.disable().catchError((Object _) {});
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final id = ++_loadId;

    final old = _controller;
    old?.removeListener(_onVideo);
    unawaited(old?.dispose());
    setState(() {
      _controller = null;
      _error = null;
      _counted = false;
      _rewarded = false;
    });

    VideoPlayerController? controller;
    try {
      final source = await ref
          .read(videoSourceRepositoryProvider)
          .getSource(_item, _episode);
      if (!mounted || id != _loadId) return;

      controller = VideoPlayerController.networkUrl(source.url);
      await controller.initialize();
      if (!mounted || id != _loadId) {
        await controller.dispose();
        return;
      }

      // Продолжаем с того места, где остановились
      final saved = _prefs.getInt(_positionKey);
      if (saved != null &&
          saved > 10 &&
          controller.value.duration.inSeconds - saved > 20) {
        await controller.seekTo(Duration(seconds: saved));
      }
      await controller.setPlaybackSpeed(_speed);
      controller.addListener(_onVideo);
      await controller.play();

      // При первом запуске кладём тайтл в список «Смотрю»
      if (ref.read(libraryProvider)[_item.id] == null) {
        ref
            .read(libraryProvider.notifier)
            .setStatus(_item, LibraryStatus.inProgress);
      }

      if (!mounted || id != _loadId) return;
      setState(() {
        _source = source;
        _controller = controller;
      });
      _scheduleHide();
    } catch (e) {
      await controller?.dispose();
      if (mounted && id == _loadId) setState(() => _error = e);
    }
  }

  void _onVideo() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final value = controller.value;

    if (value.hasError) {
      setState(
        () => _error = value.errorDescription ?? 'Ошибка воспроизведения',
      );
      return;
    }

    final total = value.duration.inMilliseconds;
    if (total > 0 && value.position.inMilliseconds / total >= 0.9) {
      _countEpisode();
    }
    if (_isFinished) {
      unawaited(_prefs.remove(_positionKey)); // пересмотр начнётся с начала
      _hideTimer?.cancel();
      _controlsVisible = true;
    }
    // Ползунок и время обновляются вместе с видео
    if (_dragMs == null) setState(() {});
  }

  /// Засчитать серию. Прогресс только растёт: пересмотр старой серии его не снижает.
  void _countEpisode() {
    if (_counted) return;
    _counted = true;
    final current = ref.read(libraryProvider)[_item.id]?.progress ?? 0;
    if (_episode > current) {
      _rewarded = true;
      ref.read(libraryProvider.notifier).setProgress(_item, _episode);
    }
  }

  void _savePosition() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isFinished) {
      return;
    }
    unawaited(_prefs.setInt(_positionKey, controller.value.position.inSeconds));
  }

  void _goTo(int episode) {
    if (episode < 1) return;
    _savePosition();
    setState(() => _episode = episode);
    _load();
  }

  void _exit() {
    _savePosition();
    Navigator.of(context).pop();
  }

  // --- управление ---

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;
    if (_isFinished) {
      _counted = false;
      await controller.seekTo(Duration.zero);
      await controller.play();
    } else if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) {
      setState(() {});
      _scheduleHide();
    }
  }

  Future<void> _seekBy(Duration delta) async {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    final target = value.position + delta;
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(
        0,
        value.duration.inMilliseconds,
      ),
    );
    await controller.seekTo(clamped);
    _hintTimer?.cancel();
    setState(() => _seekHint = delta.isNegative ? '−10' : '+10');
    _hintTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _seekHint = null);
    });
  }

  void _onDoubleTap(double width) {
    final left = (_doubleTapAt?.dx ?? width / 2) < width / 2;
    _seekBy(Duration(seconds: left ? -10 : 10));
  }

  Future<void> _setSpeed(double speed) async {
    await _controller?.setPlaybackSpeed(speed);
    if (mounted) setState(() => _speed = speed);
  }

  void _toggleOrientation() {
    setState(() => _landscape = !_landscape);
    SystemChrome.setPreferredOrientations(
      _landscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
  }

  static String _speedLabel(double s) =>
      s == s.roundToDouble() ? '${s.toInt()}x' : '${s}x';

  String _time(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // --- экран ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(backgroundColor: Colors.black, body: _buildBody()),
    );
  }

  Widget _buildBody() {
    final controller = _controller;

    if (_error != null) {
      return _Message(
        title: 'Не удалось запустить серию',
        text: 'Проверьте интернет и попробуйте ещё раз.',
        onRetry: _load,
        onBack: _exit,
      );
    }
    if (controller == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const Center(child: CircularProgressIndicator()),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: _exit,
                color: Colors.white,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
        ],
      );
    }

    final value = controller.value;
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
        onDoubleTap: () => _onDoubleTap(box.maxWidth),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
                child: VideoPlayer(controller),
              ),
            ),
            if (value.isBuffering)
              const Center(child: CircularProgressIndicator()),
            if (_seekHint != null)
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      _seekHint!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _buildControls(value),
              ),
            ),
            if (_isFinished) _buildFinishedCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(VideoPlayerValue value) {
    final scheme = Theme.of(context).colorScheme;
    final unit = ref.watch(unitProvider((item: _item, number: _episode)));
    final duration = value.duration;
    final maxMs = math.max(1, duration.inMilliseconds).toDouble();
    final positionMs = (_dragMs ?? value.position.inMilliseconds.toDouble())
        .clamp(0, maxMs)
        .toDouble();

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.4),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _exit,
                    color: Colors.white,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          unit?.title == null
                              ? 'Серия $_episode'
                              : 'Серия $_episode · ${unit!.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (_source?.credit != null)
                          Text(
                            _source!.credit!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<double>(
                    tooltip: 'Скорость',
                    initialValue: _speed,
                    onSelected: _setSpeed,
                    itemBuilder: (_) => [
                      for (final s in _speeds)
                        PopupMenuItem(value: s, child: Text(_speedLabel(s))),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _speedLabel(_speed),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Повернуть экран',
                    color: Colors.white,
                    onPressed: _toggleOrientation,
                    icon: Icon(
                      _landscape
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  color: Colors.white,
                  tooltip: 'Предыдущая серия',
                  onPressed: _episode > 1 ? () => _goTo(_episode - 1) : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
                IconButton(
                  iconSize: 36,
                  color: Colors.white,
                  tooltip: 'Назад на 10 секунд',
                  onPressed: () => _seekBy(const Duration(seconds: -10)),
                  icon: const Icon(Icons.replay_10_rounded),
                ),
                const SizedBox(width: 8),
                Material(
                  color: scheme.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _togglePlay,
                    child: SizedBox(
                      width: 68,
                      height: 68,
                      child: Icon(
                        value.isPlaying && !_isFinished
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 36,
                  color: Colors.white,
                  tooltip: 'Вперёд на 10 секунд',
                  onPressed: () => _seekBy(const Duration(seconds: 10)),
                  icon: const Icon(Icons.forward_10_rounded),
                ),
                IconButton(
                  iconSize: 36,
                  color: Colors.white,
                  tooltip: 'Следующая серия',
                  onPressed: _hasNext ? () => _goTo(_episode + 1) : null,
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: positionMs,
                      max: maxMs,
                      onChangeStart: (_) => _hideTimer?.cancel(),
                      onChanged: (v) => setState(() => _dragMs = v),
                      onChangeEnd: (v) async {
                        await _controller?.seekTo(
                          Duration(milliseconds: v.round()),
                        );
                        if (!mounted) return;
                        setState(() => _dragMs = null);
                        _scheduleHide();
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _time(Duration(milliseconds: positionMs.round())),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      Text(
                        _time(duration),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedCard() {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Серия $_episode просмотрена',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_rewarded) ...[
                const SizedBox(height: 4),
                Text('+10 очков', style: TextStyle(color: scheme.primary)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _exit,
                      child: const Text('Закрыть'),
                    ),
                  ),
                  if (_hasNext) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _goTo(_episode + 1),
                        child: const Text('Следующая'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Экран ошибки плеера.
class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.text,
    required this.onRetry,
    required this.onBack,
  });

  final String title;
  final String text;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: onBack,
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
