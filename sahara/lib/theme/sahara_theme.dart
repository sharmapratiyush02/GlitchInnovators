import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaharaTheme {
  // ── Palette ──────────────────────────────────────────────────────────
  static const Color sand       = Color(0xFFF5E6C8);   // primary bg (light)
  static const Color sandDeep   = Color(0xFFEDD9A3);   // card surface (light)
  static const Color ember      = Color(0xFFD4633C);   // primary action
  static const Color emberDark  = Color(0xFFB84E2A);   // pressed / accent
  static const Color warmWhite  = Color(0xFFFDF8F0);   // text on dark
  static const Color inkBrown   = Color(0xFF3B2212);   // primary text (light)
  static const Color mutedBrown = Color(0xFF7A5C45);   // secondary text
  static const Color sage       = Color(0xFF7A9E7E);   // success / calm
  static const Color crisisRed  = Color(0xFFCC3333);   // crisis accent

  // Dark equivalents
  static const Color darkBg     = Color(0xFF1A1208);
  static const Color darkSurface = Color(0xFF2A1E0E);
  static const Color darkCard   = Color(0xFF3A2A18);

  // ── Light Theme ───────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ember,
        onPrimary: warmWhite,
        secondary: sage,
        onSecondary: warmWhite,
        error: crisisRed,
        onError: warmWhite,
        background: sand,
        onBackground: inkBrown,
        surface: sandDeep,
        onSurface: inkBrown,
      ),
      scaffoldBackgroundColor: sand,
      textTheme: _buildTextTheme(inkBrown),
      cardTheme: CardTheme(
        color: sandDeep,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: sand,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: inkBrown,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: inkBrown),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: sand,
        selectedItemColor: ember,
        unselectedItemColor: mutedBrown,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ember,
          foregroundColor: warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.nunito(color: mutedBrown, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: sandDeep,
        selectedColor: ember.withOpacity(0.2),
        labelStyle: GoogleFonts.nunito(
          color: inkBrown,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: ember,
        onPrimary: warmWhite,
        secondary: sage,
        onSecondary: darkBg,
        error: crisisRed,
        onError: warmWhite,
        background: darkBg,
        onBackground: warmWhite,
        surface: darkSurface,
        onSurface: warmWhite,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: _buildTextTheme(warmWhite),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: warmWhite,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: warmWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: ember,
        unselectedItemColor: Colors.white54,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ember,
          foregroundColor: warmWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.nunito(color: Colors.white38, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: ember.withOpacity(0.3),
        labelStyle: GoogleFonts.nunito(
          color: warmWhite,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor.withOpacity(0.7),
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
  }
}
