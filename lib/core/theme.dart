import 'package:flutter/material.dart';

class AppTheme {
  // Paleta Estandarizada y Mínima (Con colores exactos del diseño)
  static const Color primaryGreen = Color(0xFF2A4844); // Forest Muted
  static const Color accentOrange = Color(0xFFF97316); // Flame
  static const Color accentTeal = Color(0xFF0D9488); // Mic / Ready
  static const Color accentTealDark = Color(
    0xFF324E4C,
  ); // "Ver todos" (Exacto: RGB 50, 78, 76)

  static const Color background = Color(0xFFF8F9FB);
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'Segoe UI',
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: accentOrange,
        surface: surface,
        background: background,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: textMain,
          letterSpacing: -0.5,
          inherit: true,
        ),
        headlineMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textMain,
          inherit: true,
        ),
        bodyMedium: TextStyle(
          fontSize: 12, // Refinado
          color: textMuted,
          inherit: true,
        ),
        labelSmall: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: textMuted,
          letterSpacing: 0.5,
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
