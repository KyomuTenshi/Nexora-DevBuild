import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Единые радиусы скругления: любой новый виджет берёт значение отсюда.
class AppRadius {
  AppRadius._();

  /// Кнопки, поля ввода, меню и всплывающие сообщения.
  static const double control = 16;

  /// Карточки и блоки настроек.
  static const double card = 20;

  /// Нижние панели и диалоги.
  static const double sheet = 24;
}

/// Тема собирается под выбранный пользователем акцентный цвет.
/// Здесь заданы вид кнопок, полей, чипов и панелей, поэтому экраны
/// используют обычные виджеты Material и выглядят одинаково.
class AppTheme {
  AppTheme._();

  static ThemeData light(Color accent) => _build(Brightness.light, accent);
  static ThemeData dark(Color accent) => _build(Brightness.dark, accent);

  /// Цвет значков статус-бара и системной навигации под яркость темы.
  /// Без этого при ручном выборе темы значки сливаются с фоном.
  static SystemUiOverlayStyle overlayStyle(ThemeData theme) =>
      _overlay(theme.brightness == Brightness.dark, theme.colorScheme.surface);

  static SystemUiOverlayStyle _overlay(bool isDark, Color navigationColor) {
    final icons = isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: navigationColor,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }

  static ThemeData _build(Brightness brightness, Color accent) {
    final isDark = brightness == Brightness.dark;

    // fromSeed даёт основу палитры, а copyWith принудительно задаёт цвета макета.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: Colors.white,
          surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          surfaceContainerHighest: isDark
              ? AppColors.darkSurfaceHigh
              : AppColors.lightSurfaceHigh,
          onSurface: isDark ? AppColors.darkText : AppColors.lightText,
          onSurfaceVariant: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );

    // Общий вид кнопок: одна высота и один шрифт на всех экранах
    const buttonText = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
    const buttonSize = Size(64, 52);

    OutlineInputBorder inputBorder(BorderSide side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: side,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      // Переходы между экранами как в iOS: свайп от края возвращает назад.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: _overlay(isDark, scheme.surface),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 26,
            color: selected ? accent : scheme.onSurfaceVariant,
          );
        }),
      ),
      // Боковая панель на планшете выглядит так же, как нижняя на телефоне
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        selectedIconTheme: IconThemeData(size: 26, color: accent),
        unselectedIconTheme: IconThemeData(
          size: 26,
          color: scheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: controlShape,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: controlShape,
      ),
      // Поля ввода: заливка без рамки, при фокусе рамка акцентного цвета
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: inputBorder(BorderSide.none),
        enabledBorder: inputBorder(BorderSide.none),
        focusedBorder: inputBorder(BorderSide(color: accent, width: 1.6)),
        errorBorder: inputBorder(BorderSide(color: scheme.error, width: 1.2)),
        focusedErrorBorder: inputBorder(
          BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: buttonText,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: buttonText,
          shape: controlShape,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: buttonText, shape: controlShape),
      ),
      // Переключатель вида (тема, язык): выбранный сегмент залит акцентом
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      // Чипы: такие же «таблетки», как фильтры в каталоге и библиотеке
      chipTheme: ChipThemeData(
        showCheckmark: false,
        shape: const StadiumBorder(),
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: accent.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? accent
                : Colors.transparent,
            width: 1.4,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.4),
        space: 1,
      ),
    );
  }
}
