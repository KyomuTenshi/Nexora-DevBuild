import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nexora/core/constants/store_catalog.dart';

/// Аватар с инициалами, рамкой из магазина и значком уровня.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.text,
    required this.frameId,
    this.level,
    this.size = 96,
  });

  final String text;
  final String frameId;
  final int? level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final frame = storeItemById(frameId);
    final ringColor =
        frame.colors.isEmpty ? Colors.transparent : frame.colors.first;
    final hasRing = ringColor != Colors.transparent;
    final inner = hasRing ? size - 16 : size - 4;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (hasRing)
            Container(
              width: size - 8,
              height: size - 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 4),
              ),
            ),
          if (hasRing)
            for (final a in const [
              Alignment.topCenter,
              Alignment.bottomCenter,
              Alignment.centerLeft,
              Alignment.centerRight,
            ])
              Align(
                alignment: a,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(width: 9, height: 9, color: ringColor),
                ),
              ),
          Container(
            width: inner,
            height: inner,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.22),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          if (level != null)
            Positioned(
              right: -2,
              bottom: size * 0.04,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                  border: Border.all(color: scheme.primary, width: 2.5),
                ),
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontSize: size * 0.13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Фон профиля: градиент из магазина и силуэт ночного города.
class BannerArt extends StatelessWidget {
  const BannerArt({super.key, required this.bannerId, this.child});

  final String bannerId;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = storeItemById(bannerId).colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors.length >= 2 ? colors : [colors.first, colors.first],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -70,
            top: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _SkylinePainter())),
          ?child,
        ],
      ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7); // одно и то же зерно: город не «мерцает»
    final building = Paint()..color = Colors.black.withValues(alpha: 0.38);
    final window = Paint()
      ..color = const Color(0xFFFFC53D).withValues(alpha: 0.55);

    var x = 0.0;
    while (x < size.width) {
      final w = 22 + rnd.nextDouble() * 26;
      final h = size.height * (0.16 + rnd.nextDouble() * 0.3);
      canvas.drawRect(Rect.fromLTWH(x, size.height - h, w, h), building);
      for (var wy = size.height - h + 8; wy < size.height - 6; wy += 14) {
        for (var wx = x + 5; wx < x + w - 6; wx += 11) {
          if (rnd.nextDouble() > 0.82) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 3.5, 4.5), window);
          }
        }
      }
      x += w + 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
