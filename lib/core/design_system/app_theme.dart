import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: const TextTheme(
        displaySmall: AppTypography.display,
        titleLarge: AppTypography.title,
        bodyLarge: AppTypography.body,
        labelLarge: AppTypography.label,
      ).apply(
        bodyColor: isDark ? AppColors.darkText : AppColors.lightText,
        displayColor: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        foregroundColor: isDark ? AppColors.darkText : AppColors.lightText,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: AppDimensions.appBarHeight,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.medium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
        sizeConstraints: const BoxConstraints(
          minWidth: AppDimensions.minimumTouchTarget,
          minHeight: AppDimensions.minimumTouchTarget,
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(
              AppDimensions.minimumTouchTarget,
              AppDimensions.minimumTouchTarget,
            ),
          ),
        ),
      ),
      visualDensity: VisualDensity.standard,
      useMaterial3: true,
    );
  }
}
