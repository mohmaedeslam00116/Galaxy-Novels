import 'package:flutter/material.dart';

class AppTheme {
  static const _darkBackground = Color(0xFF020617);
  static const _darkSurface = Color(0xFF0F172A);
  static const _darkSurfaceAlt = Color(0xFF1E293B);
  static const _darkPrimary = Color(0xFF2563EB);
  static const _darkTextPrimary = Color(0xFFF8FAFC);
  static const _darkTextSecondary = Color(0xFFCBD5E1);
  static const _darkBorder = Color(0xFF334155);

  static const _lightBackground = Color(0xFFF8FAFC);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceAlt = Color(0xFFEEF2F7);
  static const _lightPrimary = Color(0xFF1D4ED8);
  static const _lightTextPrimary = Color(0xFF0F172A);
  static const _lightTextSecondary = Color(0xFF475569);
  static const _lightBorder = Color(0xFFCBD5E1);

  static ThemeData light() {
    return _base(
      brightness: Brightness.light,
      background: _lightBackground,
      surface: _lightSurface,
      surfaceAlt: _lightSurfaceAlt,
      primary: _lightPrimary,
      textPrimary: _lightTextPrimary,
      textSecondary: _lightTextSecondary,
      border: _lightBorder,
    );
  }

  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      background: _darkBackground,
      surface: _darkSurface,
      surfaceAlt: _darkSurfaceAlt,
      primary: _darkPrimary,
      textPrimary: _darkTextPrimary,
      textSecondary: _darkTextSecondary,
      border: _darkBorder,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color primary,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(primary: primary, surface: surface, onSurface: textPrimary);

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
    );

    return baseTheme.copyWith(
      dividerColor: border,
      textTheme: baseTheme.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        showUnselectedLabels: true,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        scrimColor: Colors.black.withValues(alpha: 0.55),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        selectedColor: primary.withValues(alpha: 0.12),
        backgroundColor: surfaceAlt,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary),
        secondaryLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: textSecondary,
          fontSize: 13,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        hintStyle: TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
