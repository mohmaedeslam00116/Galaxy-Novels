import 'package:flutter/material.dart';

enum AppThemePreset { galaxyNoir, starlightPaper }

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.preset,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSoft,
    required this.primary,
    required this.accent,
    required this.gold,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.danger,
  });

  final AppThemePreset preset;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSoft;
  final Color primary;
  final Color accent;
  final Color gold;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color danger;

  @override
  AppThemeTokens copyWith({
    AppThemePreset? preset,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSoft,
    Color? primary,
    Color? accent,
    Color? gold,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? danger,
  }) {
    return AppThemeTokens(
      preset: preset ?? this.preset,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      gold: gold ?? this.gold,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) {
      return this;
    }

    return AppThemeTokens(
      preset: t < 0.5 ? preset : other.preset,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class AppTheme {
  static const AppThemeTokens galaxyNoir = AppThemeTokens(
    preset: AppThemePreset.galaxyNoir,
    background: Color(0xFF0B0911),
    surface: Color(0xFF15121C),
    surfaceRaised: Color(0xFF211C2A),
    surfaceSoft: Color(0xFF2C2636),
    primary: Color(0xFFDCCBFF),
    accent: Color(0xFF55D6E8),
    gold: Color(0xFFF2C66D),
    border: Color(0xFF342D40),
    textPrimary: Color(0xFFF7F3FF),
    textSecondary: Color(0xFFAFA7BC),
    success: Color(0xFF55D6E8),
    danger: Color(0xFFE83F68),
  );

  static const AppThemeTokens starlightPaper = AppThemeTokens(
    preset: AppThemePreset.starlightPaper,
    background: Color(0xFFF8F6FC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0ECF7),
    surfaceSoft: Color(0xFFE7E0F1),
    primary: Color(0xFF5C3EA5),
    accent: Color(0xFF087C8E),
    gold: Color(0xFF9A6815),
    border: Color(0xFFDAD1E7),
    textPrimary: Color(0xFF17111F),
    textSecondary: Color(0xFF5B5268),
    success: Color(0xFF087C8E),
    danger: Color(0xFFC72552),
  );

  static ThemeData light() => _base(tokens: starlightPaper);

  static ThemeData dark() => _base(tokens: galaxyNoir);

  static ThemeData _base({required AppThemeTokens tokens}) {
    final brightness = tokens.preset == AppThemePreset.galaxyNoir
        ? Brightness.dark
        : Brightness.light;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: tokens.primary,
          brightness: brightness,
        ).copyWith(
          primary: tokens.primary,
          onPrimary: tokens.preset == AppThemePreset.galaxyNoir
              ? const Color(0xFF181020)
              : Colors.white,
          secondary: tokens.accent,
          onSecondary: tokens.preset == AppThemePreset.galaxyNoir
              ? const Color(0xFF031416)
              : Colors.white,
          surface: tokens.surface,
          onSurface: tokens.textPrimary,
          surfaceContainerHighest: tokens.surfaceRaised,
          onSurfaceVariant: tokens.textSecondary,
          outline: tokens.border,
          error: tokens.danger,
        );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      extensions: const [],
    );

    final textTheme = baseTheme.textTheme
        .apply(bodyColor: tokens.textPrimary, displayColor: tokens.textPrimary)
        .copyWith(
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
          titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(height: 1.55),
        );

    return baseTheme.copyWith(
      extensions: [tokens],
      textTheme: textTheme,
      dividerColor: tokens.border,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.background,
        foregroundColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.primary : tokens.textSecondary,
            size: selected ? 25 : 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? tokens.primary : tokens.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.surface,
        scrimColor: Colors.black.withValues(alpha: 0.55),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.border),
        ),
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        selectedColor: tokens.primary.withValues(alpha: 0.12),
        backgroundColor: tokens.surfaceRaised,
        side: BorderSide(color: tokens.border.withValues(alpha: 0.86)),
        labelStyle: TextStyle(color: tokens.textPrimary),
        secondaryLabelStyle: TextStyle(
          color: tokens.primary,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.textSecondary,
        textColor: tokens.textPrimary,
        titleTextStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: tokens.textSecondary,
          height: 1.4,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceRaised,
        hintStyle: TextStyle(color: tokens.textSecondary),
        prefixIconColor: tokens.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tokens.accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.preset == AppThemePreset.galaxyNoir
              ? const Color(0xFF181020)
              : Colors.white,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: tokens.preset == AppThemePreset.galaxyNoir ? 1 : 0,
          shadowColor: tokens.primary.withValues(alpha: 0.24),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: tokens.accent,
          side: BorderSide(color: tokens.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.textPrimary,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
