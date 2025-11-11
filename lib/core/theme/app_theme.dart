import 'package:flutter/material.dart';

/// Defines application-wide color palettes and typography.
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF8B2CF5);
  static const Color darkBackground = Color(0xFF232B36);
  static const Color darkSurface = Color(0xFF1B252E);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: Colors.blue.shade700,
        onPrimary: Colors.white,
        secondary: Colors.blue.shade200,
        onSecondary: Colors.white,
        error: Colors.red.shade400,
        onError: Colors.white,
        surface: darkBackground,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(backgroundColor: darkBackground),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
    );
  }
}
