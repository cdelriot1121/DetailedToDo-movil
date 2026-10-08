import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Construye el [ThemeData] de la app a partir de una [AppPalette].
///
/// Todos los temas (claro y oscuros) pasan por aquí, así que cualquier ajuste
/// visual se hace en un solo lugar.
class AppTheme {
  AppTheme._();

  /// ThemeData del tema indicado.
  static ThemeData build(AppThemeId themeId) => fromPalette(themeId.palette);

  /// ThemeData a partir de una paleta concreta.
  ///
  /// Útil para previsualizar un tema sin aplicarlo (ej. panel de
  /// personalización).
  static ThemeData fromPalette(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;

    final colorScheme = p.isDark
        ? ColorScheme.dark(
            primary: p.accent,
            onPrimary: p.onAccent,
            secondary: p.accent,
            onSecondary: p.onAccent,
            surface: p.surface,
            onSurface: p.primaryText,
            surfaceContainerHighest: p.surfaceSecondary,
            onSurfaceVariant: p.secondaryText,
            outline: p.border,
            outlineVariant: p.divider,
            error: AppColors.error,
            onError: AppColors.pureBlack,
            inverseSurface: p.primaryText,
            onInverseSurface: p.surface,
            surfaceTint: Colors.transparent,
          )
        : ColorScheme.light(
            primary: p.accent,
            onPrimary: p.onAccent,
            secondary: p.accent,
            onSecondary: p.onAccent,
            surface: p.surface,
            onSurface: p.primaryText,
            surfaceContainerHighest: p.surfaceSecondary,
            onSurfaceVariant: p.secondaryText,
            outline: p.border,
            outlineVariant: p.divider,
            error: AppColors.error,
            onError: AppColors.pureWhite,
            inverseSurface: p.primaryText,
            onInverseSurface: p.surface,
            surfaceTint: Colors.transparent,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.scaffoldBackground,
      extensions: <ThemeExtension<dynamic>>[p],
      iconTheme: IconThemeData(color: p.primaryText),
      appBarTheme: AppBarTheme(
        backgroundColor: p.scaffoldBackground,
        foregroundColor: p.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: p.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: p.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.border, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputBackground,
        hintStyle: TextStyle(color: p.placeholder, fontSize: 15),
        labelStyle: TextStyle(
          color: p.secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.track,
        circularTrackColor: p.track,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.25),
        selectionHandleColor: p.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.primaryText,
        contentTextStyle: TextStyle(color: p.surface, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: p.primaryText,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
        displayMedium: TextStyle(
          color: p.primaryText,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          color: p.primaryText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          color: p.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: p.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: p.primaryText, fontSize: 15),
        bodyMedium: TextStyle(color: p.secondaryText, fontSize: 15),
        bodySmall: TextStyle(color: p.secondaryText, fontSize: 13),
        labelLarge: TextStyle(
          color: p.primaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
