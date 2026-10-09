import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const choc = Color(0xFF4E342E);
const ivory = Color(0xFFF8F4E7);
const orange = Color(0xFFCC5500);
const cream = Color(0xFFFFFDF7);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: orange).copyWith(
    primary: orange,
    onPrimary: Colors.white,
    secondary: choc,
    surface: ivory,
    onSurface: choc,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: ivory);
  final text = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: choc, displayColor: choc);
  return base.copyWith(
    textTheme: text.copyWith(
      headlineSmall: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: choc),
      titleLarge: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: choc),
      titleMedium: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: choc),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ivory,
      foregroundColor: choc,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: choc),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: choc,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        side: const BorderSide(color: choc, width: 1.5),
      ),
    ),
  );
}

TextStyle script({double size = 30, Color color = orange}) =>
    GoogleFonts.greatVibes(fontSize: size, color: color);
