import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class SakhiTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SakhiColors.rose,
        primary:   SakhiColors.rose,
        secondary: SakhiColors.gold,
        surface:   SakhiColors.vblush,
        onPrimary: SakhiColors.white,
        onSurface: SakhiColors.black,
      ),
      scaffoldBackgroundColor: SakhiColors.vblush,
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSans(
          fontSize: 32, fontWeight: FontWeight.w700, color: SakhiColors.deep),
        displayMedium: GoogleFonts.dmSans(
          fontSize: 26, fontWeight: FontWeight.w700, color: SakhiColors.deep),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 22, fontWeight: FontWeight.w600, color: SakhiColors.deep),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: SakhiColors.deep),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: SakhiColors.deep),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: SakhiColors.gray),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: SakhiColors.gray),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: SakhiColors.lgray),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: SakhiColors.deep),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  SakhiColors.deep,
        foregroundColor:  SakhiColors.white,
        elevation:        0,
        centerTitle:      true,
        titleTextStyle:   GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: SakhiColors.white, letterSpacing: 0.3),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: SakhiColors.deep,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:      SakhiColors.deep,
        selectedItemColor:    SakhiColors.gold,
        unselectedItemColor:  Color(0xFF9A7090),
        type:                 BottomNavigationBarType.fixed,
        elevation:            0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SakhiColors.rose,
          foregroundColor: SakhiColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color:     SakhiColors.white,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SakhiColors.petal, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   SakhiColors.white,
        border:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SakhiColors.petal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SakhiColors.petal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SakhiColors.rose, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(color: SakhiColors.lgray, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SakhiColors.blush,
        labelStyle: GoogleFonts.dmSans(fontSize: 12, color: SakhiColors.rose),
        side: const BorderSide(color: SakhiColors.petal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }
}
