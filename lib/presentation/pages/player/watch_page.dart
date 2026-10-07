import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/widgets/media_cover.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

/// Открывает демо-плеер. Настоящего видео пока нет: плеер имитирует просмотр
/// серии (24 минуты проходят за ~24 секунды), чтобы работал весь сценарий
/// «посмотрел серию → прогресс сохранился → очки начислены».
void openWatch(BuildContext context, MediaItem item, {required int episode}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => WatchPage(item: item, episode: episode),
    ),
  );
}

class WatchPage extends ConsumerStatefulWidget {
  const WatchPage({super.key, required this.item, required this.episode});

  final MediaItem item;
  final int episode;

  @override
  ConsumerState<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends ConsumerState<WatchPage> {
  static const double _duration = 24 * 60; // длина серии в секундах
  static const double _tickSeconds = 12; // сколько секунд «видео» за один тик

  late int _episode;
  double _position = 0;
  bool _playing = true;
  bool _controlsVisible = true;
  bool _counted = false; // серия уже засчитана
  Timer? _timer;

  bool get _finished => _position >= _duration;

  int? get _total =>
      widget.item.totalUnits > 0 ? widget.item.totalUnits : null;

  bool get _hasNext => _total == null || _episode < _total!;

  @override
  void initState() {
    super.initState();
    _episode = widget.episode;
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!_playing || _finished || !mounted) return;
    setState(() => _position = math.min(_position + _tickSeconds, _duration));

    // При первом запуске кладём тайтл в список «Смотрю»
    final entry = ref.read(libraryProvider)[widget.item.id];
    if (entry == null) {
      ref.read(libraryProvider.notifier).setStatus(
        widget.item,
        LibraryStatus.inProgress,
      );
    }
    if (_finished) {
      _playing = false;
      _countEpisode();
    }
  }

  /// Засчитать серию. Прогресс только растёт: пересмотр старой серии его не снижает.
  void _countEpisode() {
    if (_counted) return;
    _counted = true;
    final current = ref.read(libraryProvider)[widget.item.id]?.progress ?? 0;
    if (_episode > current) {
      ref.read(libraryProvider.notifier).setProgress(widget.item, _episode);
    }
  }

  void _goTo(int episode) {
    if (episode < 1 || (_total != null && episode > _total!)) return;
    if (_position / _duration >= 0.9) _countEpisode();
    setState(() {
      _episode = episode;
      _position = 0;
      _playing = true;
      _counted = false;
    });
  }

  void _exit() {
    if (_position / _duration >= 0.9) _countEpisode();
    Navigator.of(context).pop();
  }

  String _time(double seconds) {
    final s = seconds.round();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _controlsVisible = !_controlsVisible),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(opacity: 0.85, child: MediaCover(item: item)),
              ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
              AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
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
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Серия $_episode',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Отметить просмотренной',
                                color: Colors.white,
                                icon: const Icon(Icons.done_all_rounded),
                                onPressed: () {
                                  setState(() => _position = _duration);
                                  _playing = false;
                                  _countEpisode();
                                  showInfo(context, 'Серия $_episode отмечена');
                                },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 40,
                              color: Colors.white,
                              onPressed: _episode > 1
                                  ? () => _goTo(_episode - 1)
                                  : null,
                              icon: const Icon(Icons.skip_previous_rounded),
                            ),
                            const SizedBox(width: 16),
                            Material(
                              color: scheme.primary,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  if (_finished) {
                                    setState(() {
                                      _position = 0;
                                      _counted = false;
                                    });
                                  }
                                  setState(() => _playing = !_playing || _finished);
                                },
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Icon(
                                    _playing && !_finished
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              iconSize: 40,
                              color: Colors.white,
                              onPressed:
                              _hasNext ? () => _goTo(_episode + 1) : null,
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
                                  value: math.min(math.max(_position, 0.0), _duration),
                                  max: _duration,
                                  onChanged: (v) =>
                                      setState(() => _position = v),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    _time(_position),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _time(_duration),
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
                ),
              ),
              if (_finished)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
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
                          const SizedBox(height: 4),
                          Text(
                            '+10 очков',
                            style: TextStyle(color: scheme.primary),
                          ),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}