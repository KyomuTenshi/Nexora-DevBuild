import 'package:flutter/material.dart';

/// Набор градиентов. Цвет выбирается по id: id % 8.
class CoverPalette {
  CoverPalette._();

  static const List<List<Color>> _all = [
    [Color(0xFF2CCFC0), Color(0xFF16706B)], // 0 бирюзовый
    [Color(0xFFFFB347), Color(0xFFEF5A5A)], // 1 оранжевый (One Piece)
    [Color(0xFF7B5CFF), Color(0xFF34267F)], // 2 фиолетовый (JJK)
    [Color(0xFF3AA0F5), Color(0xFF1B4A96)], // 3 синий (Solo Leveling)
    [Color(0xFF2FD08A), Color(0xFF15663F)], // 4 зелёный (Vinland)
    [Color(0xFFFF5C8A), Color(0xFF7A2450)], // 5 розовый (Edgerunners)
    [Color(0xFF8E8EA3), Color(0xFF3F3F52)], // 6 серый (Berserk)
    [Color(0xFFF5C040), Color(0xFFA8691A)], // 7 жёлтый
  ];

  static List<Color> forSeed(int seed) => _all[seed.abs() % _all.length];
}

class CoverArt extends StatelessWidget {
  const CoverArt({super.key, required this.seed, this.child});

  final int seed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = CoverPalette.forSeed(seed);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                right: -w * 0.25,
                top: -w * 0.15,
                child: _Circle(size: w * 0.95, color: Colors.white10),
              ),
              Positioned(
                left: -w * 0.2,
                bottom: -w * 0.3,
                child: _Circle(
                  size: w * 0.8,
                  color: Colors.black.withValues(alpha: 0.12),
                ),
              ),
              ?child,
            ],
          ),
        );
      },
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}