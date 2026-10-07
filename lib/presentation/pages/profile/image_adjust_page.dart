import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/local/profile_images.dart';
import 'package:nexora/domain/entities/image_adjust.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

/// Настройка того, как фото будет выглядеть в профиле: двигаем пальцем,
/// приближаем щипком или ползунком. У фона есть ещё затемнение и размытие.
class ImageAdjustPage extends ConsumerStatefulWidget {
  const ImageAdjustPage({super.key, required this.kind});

  final ProfileImageKind kind;

  @override
  ConsumerState<ImageAdjustPage> createState() => _ImageAdjustPageState();
}

class _ImageAdjustPageState extends ConsumerState<ImageAdjustPage> {
  /// Пропорции рамки фона: примерно как шапка профиля на телефоне.
  static const double _bannerRatio = 1.7;
  static const double _avatarFrame = 280;

  final _controller = TransformationController();
  late ImageAdjust _adjust;
  Size _frame = Size.zero;
  bool _ready = false;

  bool get _isAvatar => widget.kind == ProfileImageKind.avatar;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _adjust = _isAvatar ? p.avatarAdjust : p.bannerAdjust;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;
    final width = MediaQuery.sizeOf(context).width - 32;
    _frame = _isAvatar
        ? const Size(_avatarFrame, _avatarFrame)
        : Size(width, width / _bannerRatio);
    _controller.value = _matrixOf(_adjust);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Matrix4 _matrixOf(ImageAdjust a) =>
      Matrix4.translationValues(a.tx * _frame.width, a.ty * _frame.height, 0) *
          Matrix4.diagonal3Values(a.scale, a.scale, 1);

  /// Запоминаем текущее положение фото из жестов.
  void _capture() {
    final m = _controller.value;
    final t = m.getTranslation();
    setState(() {
      _adjust = _adjust.copyWith(
        scale: m.getMaxScaleOnAxis().clamp(1.0, ImageAdjust.maxScale).toDouble(),
        tx: t.x / _frame.width,
        ty: t.y / _frame.height,
      );
    });
  }

  /// Приближение ползунком: точка в центре рамки остаётся на месте.
  void _setZoom(double target) {
    final m = _controller.value;
    final s0 = m.getMaxScaleOnAxis();
    final t0 = m.getTranslation();
    final s1 = target.clamp(1.0, ImageAdjust.maxScale).toDouble();
    final cx = _frame.width / 2;
    final cy = _frame.height / 2;

    var tx = cx - (cx - t0.x) / s0 * s1;
    var ty = cy - (cy - t0.y) / s0 * s1;
    // Край фото не должен заходить внутрь рамки
    tx = tx.clamp(_frame.width * (1 - s1), 0.0).toDouble();
    ty = ty.clamp(_frame.height * (1 - s1), 0.0).toDouble();

    _controller.value =
        Matrix4.translationValues(tx, ty, 0) * Matrix4.diagonal3Values(s1, s1, 1);
    _capture();
  }

  void _reset() {
    _controller.value = Matrix4.identity();
    setState(() => _adjust = const ImageAdjust());
  }

  void _save() {
    final notifier = ref.read(profileProvider.notifier);
    if (_isAvatar) {
      // У аватара нет ни затемнения, ни размытия
      notifier.setAvatarAdjust(_adjust.copyWith(dim: 0, blur: 0));
    } else {
      notifier.setBannerAdjust(_adjust);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final path = _isAvatar ? profile.avatarPath : profile.bannerPath;

    if (path.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Сначала выберите фото')),
      );
    }

    Widget viewer = InteractiveViewer(
      transformationController: _controller,
      minScale: 1,
      maxScale: ImageAdjust.maxScale,
      boundaryMargin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      onInteractionUpdate: (_) => _capture(),
      onInteractionEnd: (_) => _capture(),
      child: Image.file(
        File(path),
        width: _frame.width,
        height: _frame.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );

    // Предпросмотр размытия (у аватара его нет)
    if (!_isAvatar && _adjust.blur > 0) {
      viewer = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: _adjust.blur,
          sigmaY: _adjust.blur,
        ),
        child: viewer,
      );
    }

    final frame = SizedBox(
      width: _frame.width,
      height: _frame.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          viewer,
          if (!_isAvatar && _adjust.dim > 0)
            IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: _adjust.dim),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAvatar ? 'Фото профиля' : 'Фон профиля'),
        actions: [
          TextButton(onPressed: _reset, child: const Text('Сбросить')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: const Text('Готово'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Двигайте фото пальцем, приближайте щипком или ползунком. '
                'Так оно будет выглядеть в профиле.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          Center(
            child: _isAvatar
                ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 3),
              ),
              child: ClipOval(child: frame),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: frame,
            ),
          ),
          const SizedBox(height: 24),
          _SliderRow(
            icon: Icons.zoom_in_rounded,
            label: 'Масштаб',
            valueText: '${(_adjust.scale * 100).round()}%',
            value: _adjust.scale,
            min: 1,
            max: ImageAdjust.maxScale,
            onChanged: _setZoom,
          ),
          if (!_isAvatar) ...[
            _SliderRow(
              icon: Icons.brightness_6_rounded,
              label: 'Затемнение',
              valueText: '${(_adjust.dim * 100).round()}%',
              value: _adjust.dim,
              min: 0,
              max: ImageAdjust.maxDim,
              onChanged: (v) => setState(() => _adjust = _adjust.copyWith(dim: v)),
            ),
            _SliderRow(
              icon: Icons.blur_on_rounded,
              label: 'Размытие',
              valueText: _adjust.blur.round().toString(),
              value: _adjust.blur,
              min: 0,
              max: ImageAdjust.maxBlur,
              onChanged: (v) =>
                  setState(() => _adjust = _adjust.copyWith(blur: v)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            valueText,
            textAlign: TextAlign.end,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}