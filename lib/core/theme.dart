import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extension to add custom color tokens to the theme.
class AppColors extends ThemeExtension<AppColors> {
  final Color forest;
  final Color forestLight;
  final Color offWhite;
  final Color earthLight;
  final Color earthBorder;
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color forestDark;
  final Color forestVibrant;

  const AppColors({
    required this.forest,
    required this.forestLight,
    required this.offWhite,
    required this.earthLight,
    required this.earthBorder,
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.forestDark,
    required this.forestVibrant,
  });

  @override
  AppColors copyWith({
    Color? forest,
    Color? forestLight,
    Color? offWhite,
    Color? earthLight,
    Color? earthBorder,
    Color? cardBackground,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? forestDark,
    Color? forestVibrant,
  }) {
    return AppColors(
      forest: forest ?? this.forest,
      forestLight: forestLight ?? this.forestLight,
      offWhite: offWhite ?? this.offWhite,
      earthLight: earthLight ?? this.earthLight,
      earthBorder: earthBorder ?? this.earthBorder,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      forestDark: forestDark ?? this.forestDark,
      forestVibrant: forestVibrant ?? this.forestVibrant,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      forest: Color.lerp(forest, other.forest, t)!,
      forestLight: Color.lerp(forestLight, other.forestLight, t)!,
      offWhite: Color.lerp(offWhite, other.offWhite, t)!,
      earthLight: Color.lerp(earthLight, other.earthLight, t)!,
      earthBorder: Color.lerp(earthBorder, other.earthBorder, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      forestDark: Color.lerp(forestDark, other.forestDark, t)!,
      forestVibrant: Color.lerp(forestVibrant, other.forestVibrant, t)!,
    );
  }
}

class AppTheme {
  // Brand Colors
  static const Color forest = Color(0xFF324E4C);
  static const Color forestLight = Color(0xFF456966);

  // Light Mode Tokens
  static const Color offWhite = Color(0xFFF8F9F8);
  static const Color backgroundLight = offWhite; // Missing token
  static const Color surfaceColor = Colors.white; // Missing token
  static const Color surface = Colors.white; // Missing token
  static const Color earthLight = Color(0xFFEAE7E2);
  static const Color earth = earthLight; // Missing token
  static const Color earthBorder = Color(0xFFE5E7EB);
  static const Color border = earthBorder; // Missing token
  static const Color textMain = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color forestDark = Color(0xFF243A38); // Missing token
  static const Color forestVibrant = Color(0xFF219653); // Missing token

  // Dark Mode Tokens (Premium Aesthetic)
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color cardDark = Color(0xFF1A2B28); // forest-deep
  static const Color cardBorderDark = Color(0xFF2D4A45); // forest-accent
  static const Color emeraldAccent = Color(0xFF10B981); // mint-glow
  static const Color textSecondaryDark = Color(0xFF64748B); // Slate 500

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: forest,
        brightness: Brightness.light,
        primary: forest,
        onPrimary: Colors.white,
        secondary: forestLight,
        surface: offWhite,
        onSurface: textMain,
        surfaceContainer: Colors.white,
        outline: earthBorder,
      ),
      scaffoldBackgroundColor: offWhite,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: TextStyle(color: textMain, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: textMain, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textMain),
        bodyMedium: TextStyle(color: textMuted),
      ),
      extensions: [
        AppColors(
          forest: forest,
          forestLight: forestLight,
          offWhite: offWhite,
          earthLight: earthLight,
          earthBorder: earthBorder,
          cardBackground: Colors.white,
          cardBorder: earthBorder,
          textPrimary: textMain,
          textSecondary: textMuted,
          textTertiary: textTertiary,
          forestDark: forestDark,
          forestVibrant: forestVibrant,
        ),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: emeraldAccent,
        brightness: Brightness.dark,
        primary: emeraldAccent,
        onPrimary: darkBg,
        secondary: forestLight,
        surface: darkBg,
        onSurface: Colors.white,
        surfaceContainer: cardDark,
        outline: cardBorderDark.withValues(alpha: 0.4),
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ).copyWith(
            displayLarge: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            displayMedium: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            titleLarge: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: textSecondaryDark),
          ),
      extensions: [
        AppColors(
          forest: emeraldAccent,
          forestLight: forestLight,
          offWhite: darkBg,
          earthLight: Color(0xFF0F172A), // Very dark slate for contrast
          earthBorder: cardBorderDark.withValues(alpha: 0.3),
          cardBackground: cardDark,
          cardBorder: cardBorderDark.withValues(alpha: 0.4),
          textPrimary: Colors.white,
          textSecondary: textSecondaryDark,
          textTertiary: Color(0xFF94A3B8), // Slate 400
          forestDark: Color(0xFF1A2B28),
          forestVibrant: emeraldAccent,
        ),
      ],
    );
  }
}

/// Extension to easily access the theme and specialized tokens from the context.
extension ThemeHelper on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
