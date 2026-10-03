import 'package:flutter/material.dart';

abstract final class AppColors {
  static const seed = Color(0xFF315CFF);
  static const lightBackground = Color(0xFFF7F8FC);
  static const darkBackground = Color(0xFF11131A);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF1A1D26);
  static const lightText = Color(0xFF151821);
  static const darkText = Color(0xFFF3F4F8);
  static const priorityHighDefault = Color(0xFFE5484D);
  static const priorityMediumDefault = Color(0xFFF5B301);
  static const priorityLowDefault = Color(0xFF8E4EC6);
}

abstract final class AppSpacing {
  static const xSmall = 4.0;
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const page = 20.0;
  static const section = 32.0;
}

abstract final class AppRadii {
  static const small = 8.0;
  static const medium = 14.0;
  static const large = 22.0;
}

abstract final class AppDimensions {
  static const minimumTouchTarget = 48.0;
  static const appBarHeight = 64.0;
  static const composerRestingInset = 20.0;
}

abstract final class AppTypography {
  static const display = TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
  );
  static const title = TextStyle(
    fontSize: 20,
    height: 26 / 20,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );
  static const label = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
}
