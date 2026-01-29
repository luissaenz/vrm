import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Estandarizada y Mínima (Con colores exactos del diseño)
  static const Color forest = Color(0xFF2D423F);
  static const Color forestVibrant = Color(0xFF219653);
  static const Color forestDark = Color(0xFF162210);
  static const Color earth = Color(0xFF8D7B6D);
  static const Color accent = Color(0xFF4A6663);
  static const Color backgroundLight = Color(0xFFF8F9F8);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color accentOrange = Color(0xFFF97316);

  static const Color primaryGreen = forest;
  static const Color background = backgroundLight;
  static const Color surface = surfaceColor;
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE5E7EB);
  static const Color earthBorder = Color(0xFFE5E7EB);
  static const Color offWhite = backgroundLight;
  static const Color earthLight = Color(0xFFEAE7E2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentOrange,
        surface: surface,
      ),
      textTheme: const TextTheme(
        // Display styles
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.5,
          inherit: true,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -1.0,
          inherit: true,
        ),
        // Headline styles
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.5,
          inherit: true,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textMain,
          inherit: true,
        ),
        // Body styles
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textMain,
          inherit: true,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textMuted,
          inherit: true,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textMuted,
          inherit: true,
        ),
        // Label styles
        labelLarge: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textMuted,
          letterSpacing: 0.5,
          inherit: true,
        ),
        labelMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textMuted,
          letterSpacing: 1.2,
          inherit: true,
        ),
        labelSmall: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textMuted,
          letterSpacing: 1.0,
          inherit: true,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
