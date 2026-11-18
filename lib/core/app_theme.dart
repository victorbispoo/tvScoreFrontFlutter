import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'system_ui_style.dart';

abstract final class AppTheme {
  static const scaffoldBackground = Color(0xFF091426);
  static const surface = Color(0xFF13243E);
  static const surfaceHighlight = Color(0xFF25446E);
  static const fieldRadius = 12.0;
  static const primary = Color(0xFF4F8DF7);

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: Color(0xFF326DD6),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1A2941),
      onSurfaceVariant: Color(0xFF4E627D),
      surfaceContainerHighest: Color(0xFFDCE8FA),
      primaryContainer: Color(0xFFDCE8FA),
      onPrimaryContainer: Color(0xFF193D79),
      outline: Color(0xFF657994),
      outlineVariant: Color(0xFFD5E0EF),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF2F6FC),
      textTheme: GoogleFonts.workSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF2F6FC),
        systemOverlayStyle: appSystemUiStyle(ThemeData.light()),
      ),
      cardTheme: dark.cardTheme.copyWith(color: scheme.surface),
      inputDecorationTheme: dark.inputDecorationTheme.copyWith(
        fillColor: scheme.surfaceContainerHighest,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      chipTheme: dark.chipTheme.copyWith(
        backgroundColor: scheme.surface,
        selectedColor: scheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: scheme.onSurface),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: scaffoldBackground,
      indicatorColor: primary.withValues(alpha: .15),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),

      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        final isSelected = states.contains(WidgetState.selected);

        return IconThemeData(color: isSelected ? primary : Colors.white60);
      }),

      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        final isSelected = states.contains(WidgetState.selected);

        return GoogleFonts.workSans(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? primary : Colors.white60,
        );
      }),

      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    textTheme: GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white60,
          surface: surface,
          surfaceContainerHighest: surfaceHighlight,
        ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: primary,
      side: BorderSide(color: Colors.white.withValues(alpha: .1)),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      showCheckmark: false,

      elevation: 0,
      pressElevation: 0,
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
