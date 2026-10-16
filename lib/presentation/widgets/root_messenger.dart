import 'package:flutter/material.dart';

/// Ключ верхнего уровня: через него показываем плашки не из виджета,
/// а из провайдера (например, когда пришёл push).
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
GlobalKey<ScaffoldMessengerState>();