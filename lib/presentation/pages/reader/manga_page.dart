import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Одна «страница манги». Настоящих сканов пока нет, поэтому страница
/// рисуется кодом: рамки панелей, штриховка, реплики. Для одной и той же
/// пары (глава, страница) рисунок всегда одинаковый.
class MangaPage extends StatelessWidget {
  const MangaPage({super.key, required this.seed, this.dark = false});

  final int seed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MangaPainter(seed, dark),
    );
  }
}

class _MangaPainter extends CustomPainter {
  _MangaPainter(this.seed, this.dark);

  final int seed;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final ink = dark ? const Color(0xFFD9D4C7) : const Color(0xFF1B1B1F);
    final paper = dark ? const Color(0xFF16161C) : const Color(0xFFE9E5D8);

    canvas.drawRect(Offset.zero & size, Paint()..color = paper);

    const margin = 10.0;
    const gutter = 8.0;
    final area = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    final rows = 3 + rnd.nextInt(2);
    final rowWeights = List.generate(rows, (_) => 0.6 + rnd.nextDouble());
    final rowTotal = rowWeights.fold<double>(0, (a, b) => a + b);

    var y = area.top;
    for (var r = 0; r < rows; r++) {
      final h = (area.height - gutter * (rows - 1)) * rowWeights[r] / rowTotal;
      final cols = 1 + rnd.nextInt(3);
      final colWeights = List.generate(cols, (_) => 0.7 + rnd.nextDouble());
      final colTotal = colWeights.fold<double>(0, (a, b) => a + b);

      var x = area.left;
      for (var c = 0; c < cols; c++) {
        final w = (area.width - gutter * (cols - 1)) * colWeights[c] / colTotal;
        _panel(canvas, Rect.fromLTWH(x, y, w, h), rnd, ink, paper);
        x += w + gutter;
      }
      y += h + gutter;
    }
  }

  void _panel(Canvas canvas, Rect rect, math.Random rnd, Color ink, Color paper) {
    final tone = const [0.0, 0.08, 0.16][rnd.nextInt(3)];
    canvas.drawRect(rect, Paint()..color = Color.lerp(paper, ink, tone)!);

    canvas.save();
    canvas.clipRect(rect);

    switch (rnd.nextInt(4)) {
      case 0: // линии скорости
        final line = Paint()
          ..color = ink.withValues(alpha: 0.7)
          ..strokeWidth = 1.2;
        for (var i = -4; i < 14; i++) {
          final x = rect.left + rect.width * i / 12;
          canvas.drawLine(
            Offset(x, rect.top),
            Offset(x - rect.width * 0.25, rect.bottom),
            line,
          );
        }
      case 1: // тёмный треугольник
        final path = Path()
          ..moveTo(rect.left + rect.width * 0.1, rect.bottom - rect.height * 0.1)
          ..lineTo(rect.right, rect.top + rect.height * 0.15)
          ..lineTo(rect.right, rect.top + rect.height * 0.55)
          ..close();
        canvas.drawPath(path, Paint()..color = ink.withValues(alpha: 0.75));
      case 2: // тёмный круг
        canvas.drawCircle(
          rect.center.translate(0, rect.height * 0.15),
          math.min(rect.width, rect.height) * 0.2,
          Paint()..color = ink.withValues(alpha: 0.8),
        );
      default:
        break;
    }

    // Реплика с тремя точками
    if (rnd.nextBool()) {
      final bw = rect.width * 0.6;
      final bh = math.min(rect.height * 0.3, 44.0);
      final center = Offset(
        rect.left + rect.width * (0.35 + rnd.nextDouble() * 0.3),
        rect.top + bh * 0.9,
      );
      final bubble = Rect.fromCenter(center: center, width: bw, height: bh);
      canvas.drawOval(
        bubble,
        Paint()..color = dark ? const Color(0xFF2A2A33) : Colors.white,
      );
      canvas.drawOval(
        bubble,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = ink,
      );
      final dot = Paint()..color = ink;
      for (var i = -1; i <= 1; i++) {
        canvas.drawCircle(center.translate(i * bw * 0.16, 0), 2.6, dot);
      }
    }

    canvas.restore();
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(covariant _MangaPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.dark != dark;
}
