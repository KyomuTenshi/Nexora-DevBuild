import 'package:flutter/material.dart';

/// Высота большой карточки на Главной: чуть выше ширины, как постер.
double heroHeight(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width - 32;
  return (width * 1.3).clamp(380.0, 560.0);
}