import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Accent palette — each entry: [normal, light, dark]
const Map<String, List<Color>> accents = {
  'periwinkle': [Color(0xFF8B8FF4), Color(0xFFB8BBF8), Color(0xFF6366D4)],
  'rose':       [Color(0xFFEF4444), Color(0xFFFCA5A5), Color(0xFFDC2626)],
  'emerald':    [Color(0xFF10B981), Color(0xFF6EE7B7), Color(0xFF059669)],
  'amber':      [Color(0xFFF59E0B), Color(0xFFFCD34D), Color(0xFFD97706)],
  'sky':        [Color(0xFF0EA5E9), Color(0xFF7DD3FC), Color(0xFF0284C7)],
  'violet':     [Color(0xFF8B5CF6), Color(0xFFC4B5FD), Color(0xFF7C3AED)],
};

Color accentOf(String key) => accents[key]?[0] ?? accents['periwinkle']![0];
Color accentLightOf(String key) => accents[key]?[1] ?? accents['periwinkle']![1];
Color accentDarkOf(String key) => accents[key]?[2] ?? accents['periwinkle']![2];

// Note colors
const Map<String, Color> noteLightColors = {
  'default': Color(0xFFFFFFFF),
  'butter':  Color(0xFFFFFDE7),
  'mint':    Color(0xFFE8F5E9),
  'sky':     Color(0xFFE3F2FD),
  'rose':    Color(0xFFFCE4EC),
  'lavender':Color(0xFFF3E5F5),
  'peach':   Color(0xFFFFF3E0),
  'slate':   Color(0xFFF1F5F9),
};

const Map<String, Color> noteDarkColors = {
  'default': Color(0xFF1E1E2E),
  'butter':  Color(0xFF2A2810),
  'mint':    Color(0xFF0D2110),
  'sky':     Color(0xFF0A1929),
  'rose':    Color(0xFF2D0A14),
  'lavender':Color(0xFF1A0D24),
  'peach':   Color(0xFF2A1800),
  'slate':   Color(0xFF1A2030),
};

Color noteColor(String key, bool dark) =>
    (dark ? noteDarkColors : noteLightColors)[key] ?? (dark ? noteDarkColors['default']! : noteLightColors['default']!);

class AppTheme {
  static TextTheme _textTheme(Color base) {
    final jb = GoogleFonts.jetBrainsMono;
    return TextTheme(
      displayLarge:  jb(fontSize: 32, fontWeight: FontWeight.w700, color: base),
      displayMedium: jb(fontSize: 26, fontWeight: FontWeight.w700, color: base),
      displaySmall:  jb(fontSize: 22, fontWeight: FontWeight.w600, color: base),
      headlineLarge: jb(fontSize: 20, fontWeight: FontWeight.w700, color: base),
      headlineMedium:jb(fontSize: 18, fontWeight: FontWeight.w600, color: base),
      headlineSmall: jb(fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleLarge:    jb(fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleMedium:   jb(fontSize: 14, fontWeight: FontWeight.w500, color: base),
      titleSmall:    jb(fontSize: 12, fontWeight: FontWeight.w500, color: base),
      bodyLarge:     jb(fontSize: 15, fontWeight: FontWeight.w400, color: base),
      bodyMedium:    jb(fontSize: 14, fontWeight: FontWeight.w400, color: base),
      bodySmall:     jb(fontSize: 12, fontWeight: FontWeight.w400, color: base),
      labelLarge:    jb(fontSize: 14, fontWeight: FontWeight.w600, color: base),
      labelMedium:   jb(fontSize: 12, fontWeight: FontWeight.w500, color: base),
      labelSmall:    jb(fontSize: 10, fontWeight: FontWeight.w500, color: base),
    );
  }

  static ThemeData light(String accentKey) {
    final accent = accentOf(accentKey);
    const bg = Color(0xFFF8F8FC);
    const surface = Color(0xFFFFFFFF);
    const onBg = Color(0xFF1A1A2E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentLightOf(accentKey),
        onSecondary: onBg,
        surface: surface,
        onSurface: onBg,
        background: bg,
        onBackground: onBg,
        outline: const Color(0xFFDDDDE8),
      ),
      textTheme: _textTheme(onBg),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onBg,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEEEEF5), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintStyle: GoogleFonts.jetBrainsMono(
          color: const Color(0xFFAAAAAF),
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentLightOf(accentKey).withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: accent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEF5),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEEEF5),
        selectedColor: accentLightOf(accentKey),
        labelStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide.none,
      ),
    );
  }

  static ThemeData dark(String accentKey) {
    final accent = accentOf(accentKey);
    const bg = Color(0xFF0F0F18);
    const surface = Color(0xFF1A1A28);
    const onBg = Color(0xFFECECF4);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accentDarkOf(accentKey),
        onSecondary: onBg,
        surface: surface,
        onSurface: onBg,
        background: bg,
        onBackground: onBg,
        outline: const Color(0xFF2E2E44),
      ),
      textTheme: _textTheme(onBg),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFECECF4)),
        titleTextStyle: GoogleFonts.jetBrainsMono(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onBg,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A2A40), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintStyle: GoogleFonts.jetBrainsMono(
          color: const Color(0xFF5A5A7A),
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentDarkOf(accentKey).withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: accent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A40),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF252538),
        selectedColor: accentDarkOf(accentKey),
        labelStyle: GoogleFonts.jetBrainsMono(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide.none,
      ),
    );
  }
}
