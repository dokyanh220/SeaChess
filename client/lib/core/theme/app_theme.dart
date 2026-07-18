import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF3C94D4);
  static const Color secondaryBlue = Color(0xFF9ED8FF);
  static const Color backgroundLight = Color(0xFFF5F8FC);
  static const Color accentGold = Color(0xFFF5C542);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1B2430);
  static const Color textSecondary = Color.fromARGB(255, 66, 66, 66);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color dangerRed = Color(0xFFE74C3C);

  // Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0A192F);
  static const Color surfaceDark = Color(0xFF112240);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Border Radius
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXXl = 100.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceWhite,
        background: backgroundLight,
        error: dangerRed,
        onPrimary: surfaceWhite,
        onSecondary: textDark,
        onSurface: textDark,
        onBackground: textDark,
        onError: surfaceWhite,
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.bold, color: textDark),
        displayMedium: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: textDark),
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: textDark),
        titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: textDark),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: textDark),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: textDark),
        labelSmall: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: surfaceWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold).copyWith(inherit: false),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          side: const BorderSide(color: Color(0xFFE1E8F0), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(color: textSecondary),
        hintStyle: GoogleFonts.manrope(color: textSecondary),
        prefixIconColor: textSecondary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.manrope(color: surfaceWhite, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceDark,
        background: backgroundDark,
        error: dangerRed,
        onPrimary: surfaceWhite,
        onSecondary: textLight,
        onSurface: textLight,
        onBackground: textLight,
        onError: surfaceWhite,
      ),
      textTheme: GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.bold, color: textLight),
        displayMedium: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.bold, color: textLight),
        titleLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w600, color: textLight),
        titleMedium: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: textLight),
        bodyLarge: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: textLight),
        bodyMedium: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: textLight),
        labelSmall: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondaryDark),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: surfaceWhite,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingLg, vertical: spacingMd),
          textStyle: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold).copyWith(inherit: false),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMd),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: GoogleFonts.manrope(color: textSecondaryDark),
        hintStyle: GoogleFonts.manrope(color: textSecondaryDark),
        prefixIconColor: textSecondaryDark,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceWhite,
        contentTextStyle: GoogleFonts.manrope(color: textDark, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusSm)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
