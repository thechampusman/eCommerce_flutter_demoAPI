import 'package:flutter/material.dart';

class AppTheme {
  
  static const Color _lightPrimary = Color(0xFF1565C0);
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightSurface = Colors.white;
  static const Color _lightText = Color(0xFF232F3E);
  static const Color _lightSecondaryText = Color(0xFF757575);

  
  static const Color _darkPrimary = Color(0xFF1976D2);
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkText = Color(0xFFFFFFFF);
  static const Color _darkSecondaryText = Color(0xFFB0B0B0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: _lightPrimary,
      scaffoldBackgroundColor: _lightBackground,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: _lightPrimary,
        surface: _lightSurface,
        background: _lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _lightText,
        onBackground: _lightText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _lightText,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: _lightText,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: _lightText,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: _lightText),
        bodyMedium: TextStyle(color: _lightText),
        bodySmall: TextStyle(color: _lightSecondaryText),
      ),
      iconTheme: const IconThemeData(color: _lightPrimary),
      dividerColor: Colors.grey[300],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: _darkPrimary,
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: _darkPrimary,
        surface: _darkSurface,
        background: _darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _darkText,
        onBackground: _darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: _darkText, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(color: _darkText, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: _darkText),
        bodyMedium: TextStyle(color: _darkText),
        bodySmall: TextStyle(color: _darkSecondaryText),
      ),
      iconTheme: const IconThemeData(color: _darkPrimary),
      dividerColor: Colors.grey[700],
    );
  }

  
  static Color primaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _lightPrimary
        : _darkPrimary;
  }

  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _lightBackground
        : _darkBackground;
  }

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _lightSurface
        : _darkSurface;
  }

  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _lightText
        : _darkText;
  }

  static Color secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _lightSecondaryText
        : _darkSecondaryText;
  }
}
