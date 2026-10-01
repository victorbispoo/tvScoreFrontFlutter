import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const scaffoldBackground = Color(0xFF091426);
  static const surface = Color(0xFF13243E);
  static const surfaceHighlight = Color(0xFF25446E);
  static const pagePadding = EdgeInsets.all(20);
  static const formPadding = EdgeInsets.all(24);
  static const fieldRadius = 12.0;
  static const primary = Color(0xFF4F8DF7);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scaffoldBackground,
      indicatorColor: primary.withValues(alpha: .15),

    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
    (states) {
      final selecionado = states.contains(WidgetState.selected);

      return IconThemeData(
        color: selecionado ? primary : Colors.white60,
      );
    },
  ),


  labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
    (states) {
      final selecionado = states.contains(WidgetState.selected);

      return GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
        color: selecionado ? primary : Colors.white60,
      );
    },
  ),

  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
),
    textTheme: GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: scaffoldBackground,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .08),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(fieldRadius)),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
