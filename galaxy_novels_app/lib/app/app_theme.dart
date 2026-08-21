import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/foundation/galaxy_design_tokens.dart';
import '../design_system/foundation/galaxy_metrics.dart';

export '../design_system/foundation/galaxy_design_tokens.dart'
    show AppThemePreset, AppThemeTokens, GalaxyDesignTokens;
export '../design_system/foundation/galaxy_metrics.dart'
    show AppVisualMetrics, GalaxyMetrics;

class AppTheme {
  static const galaxyNoir = AppThemeTokens(
    preset: AppThemePreset.galaxyNoir,
    canvas: Color(0xFF0E1520),
    surface: Color(0xFF141E2B),
    surfaceRaised: Color(0xFF1B2838),
    contentPrimary: Color(0xFFE8EDF4),
    contentSecondary: Color(0xFFA8B3C2),
    brand: Color(0xFF8EA9D1),
    onBrand: Color(0xFF101820),
    brandContainer: Color(0xFF263A52),
    onBrandContainer: Color(0xFFDCE8F7),
    outline: Color(0xFF34475D),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const starlightPaper = AppThemeTokens(
    preset: AppThemePreset.starlightPaper,
    canvas: Color(0xFFF3EFE7),
    surface: Color(0xFFFAF7F0),
    surfaceRaised: Color(0xFFFFFDF8),
    contentPrimary: Color(0xFF252B33),
    contentSecondary: Color(0xFF5E6872),
    brand: Color(0xFF536C8C),
    onBrand: Color(0xFFF7FAFF),
    brandContainer: Color(0xFFDCE5F0),
    onBrandContainer: Color(0xFF26384E),
    outline: Color(0xFFBFC4C7),
    success: Color(0xFF557C62),
    successContainer: Color(0xFFDCEADF),
    onSuccessContainer: Color(0xFF1A3924),
    warning: Color(0xFF8A6C2D),
    warningContainer: Color(0xFFF2E5C1),
    onWarningContainer: Color(0xFF3D2D08),
    danger: Color(0xFFA85F61),
    dangerContainer: Color(0xFFF3DADB),
    onDangerContainer: Color(0xFF482022),
  );

  static const neutralDark = AppThemeTokens(
    preset: AppThemePreset.neutralDark,
    canvas: Color(0xFF111315),
    surface: Color(0xFF181B1E),
    surfaceRaised: Color(0xFF22262A),
    contentPrimary: Color(0xFFECEEEF),
    contentSecondary: Color(0xFFAEB4B8),
    brand: Color(0xFF9DABB7),
    onBrand: Color(0xFF11171B),
    brandContainer: Color(0xFF2C343B),
    onBrandContainer: Color(0xFFE1E7EB),
    outline: Color(0xFF41494F),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const cosmicNight = AppThemeTokens(
    preset: AppThemePreset.cosmicNight,
    canvas: Color(0xFF14131B),
    surface: Color(0xFF1B1924),
    surfaceRaised: Color(0xFF252232),
    contentPrimary: Color(0xFFEEEAF2),
    contentSecondary: Color(0xFFB7AEBD),
    brand: Color(0xFFA99AC8),
    onBrand: Color(0xFF1B1724),
    brandContainer: Color(0xFF332D47),
    onBrandContainer: Color(0xFFE7DFF1),
    outline: Color(0xFF4A435B),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const lightNature = AppThemeTokens(
    preset: AppThemePreset.lightNature,
    canvas: Color(0xFFF1EBDD),
    surface: Color(0xFFF8F3E9),
    surfaceRaised: Color(0xFFFFFAF2),
    contentPrimary: Color(0xFF2D332F),
    contentSecondary: Color(0xFF5E685F),
    brand: Color(0xFF5E7864),
    onBrand: Color(0xFFF8FCF7),
    brandContainer: Color(0xFFDCE7D8),
    onBrandContainer: Color(0xFF263A2B),
    outline: Color(0xFFC1C8BD),
    success: Color(0xFF557C62),
    successContainer: Color(0xFFDCEADF),
    onSuccessContainer: Color(0xFF1A3924),
    warning: Color(0xFF8A6C2D),
    warningContainer: Color(0xFFF2E5C1),
    onWarningContainer: Color(0xFF3D2D08),
    danger: Color(0xFFA85F61),
    dangerContainer: Color(0xFFF3DADB),
    onDangerContainer: Color(0xFF482022),
  );

  static const oceanAsh = AppThemeTokens(
    preset: AppThemePreset.oceanAsh,
    canvas: Color(0xFF181E25),
    surface: Color(0xFF222B34),
    surfaceRaised: Color(0xFF2D3843),
    contentPrimary: Color(0xFFEDF2F6),
    contentSecondary: Color(0xFFABB8C5),
    brand: Color(0xFF91AFC8),
    onBrand: Color(0xFF12202B),
    brandContainer: Color(0xFF33495D),
    onBrandContainer: Color(0xFFE3EDF5),
    outline: Color(0xFF485A69),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const moonForest = AppThemeTokens(
    preset: AppThemePreset.moonForest,
    canvas: Color(0xFF101915),
    surface: Color(0xFF17231D),
    surfaceRaised: Color(0xFF213129),
    contentPrimary: Color(0xFFE7EEE9),
    contentSecondary: Color(0xFFA6B6AA),
    brand: Color(0xFF86A98D),
    onBrand: Color(0xFF102017),
    brandContainer: Color(0xFF294232),
    onBrandContainer: Color(0xFFD9E9DD),
    outline: Color(0xFF3A5645),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const garnetVelvet = AppThemeTokens(
    preset: AppThemePreset.garnetVelvet,
    canvas: Color(0xFF1A1216),
    surface: Color(0xFF24191E),
    surfaceRaised: Color(0xFF302228),
    contentPrimary: Color(0xFFF1E8EB),
    contentSecondary: Color(0xFFC0AAB1),
    brand: Color(0xFFC28F9C),
    onBrand: Color(0xFF2A1118),
    brandContainer: Color(0xFF4A2C35),
    onBrandContainer: Color(0xFFF0DDE3),
    outline: Color(0xFF62404A),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const copperDusk = AppThemeTokens(
    preset: AppThemePreset.copperDusk,
    canvas: Color(0xFF1A1511),
    surface: Color(0xFF241D17),
    surfaceRaised: Color(0xFF31271E),
    contentPrimary: Color(0xFFF2ECE6),
    contentSecondary: Color(0xFFBFAFA0),
    brand: Color(0xFFC39A72),
    onBrand: Color(0xFF27170C),
    brandContainer: Color(0xFF493522),
    onBrandContainer: Color(0xFFF2DEC8),
    outline: Color(0xFF604A38),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static const midnightTide = AppThemeTokens(
    preset: AppThemePreset.midnightTide,
    canvas: Color(0xFF0E191A),
    surface: Color(0xFF152426),
    surfaceRaised: Color(0xFF1E3134),
    contentPrimary: Color(0xFFE6EFF0),
    contentSecondary: Color(0xFFA4B7B9),
    brand: Color(0xFF79AAA8),
    onBrand: Color(0xFF0D2222),
    brandContainer: Color(0xFF294447),
    onBrandContainer: Color(0xFFD8EAEB),
    outline: Color(0xFF3C5B5E),
    success: Color(0xFF7FAE91),
    successContainer: Color(0xFF20382A),
    onSuccessContainer: Color(0xFFC2E6CE),
    warning: Color(0xFFC5A568),
    warningContainer: Color(0xFF3B311D),
    onWarningContainer: Color(0xFFE8D4A3),
    danger: Color(0xFFD18484),
    dangerContainer: Color(0xFF442326),
    onDangerContainer: Color(0xFFF0C3C3),
  );

  static ThemeData light() => _base(tokens: starlightPaper);

  static ThemeData dark() => _base(tokens: galaxyNoir);

  static ThemeData neutralDarkTheme() => _base(tokens: neutralDark);

  static ThemeData cosmicNightTheme() => _base(tokens: cosmicNight);

  static ThemeData lightNatureTheme() => _base(tokens: lightNature);

  static ThemeData oceanAshTheme() => _base(tokens: oceanAsh);

  static ThemeData moonForestTheme() => _base(tokens: moonForest);

  static ThemeData garnetVelvetTheme() => _base(tokens: garnetVelvet);

  static ThemeData copperDuskTheme() => _base(tokens: copperDusk);

  static ThemeData midnightTideTheme() => _base(tokens: midnightTide);

  static SystemUiOverlayStyle systemOverlayStyleFor(ThemeData theme) {
    final tokens = theme.extension<AppThemeTokens>();
    final isLight = theme.brightness == Brightness.light;
    final base = isLight
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return base.copyWith(
      statusBarColor: tokens?.canvas ?? theme.scaffoldBackgroundColor,
      systemNavigationBarColor: tokens?.surface ?? theme.colorScheme.surface,
      systemNavigationBarDividerColor:
          tokens?.outline ?? theme.colorScheme.outline,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness: isLight
          ? Brightness.dark
          : Brightness.light,
    );
  }

  static ThemeData _base({required AppThemeTokens tokens}) {
    final brightness = switch (tokens.preset) {
      AppThemePreset.starlightPaper ||
      AppThemePreset.lightNature => Brightness.light,
      AppThemePreset.neutralDark ||
      AppThemePreset.galaxyNoir ||
      AppThemePreset.cosmicNight ||
      AppThemePreset.oceanAsh ||
      AppThemePreset.moonForest ||
      AppThemePreset.garnetVelvet ||
      AppThemePreset.copperDusk ||
      AppThemePreset.midnightTide => Brightness.dark,
    };
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: tokens.brand,
          brightness: brightness,
        ).copyWith(
          primary: tokens.brand,
          onPrimary: tokens.onBrand,
          primaryContainer: tokens.brandContainer,
          onPrimaryContainer: tokens.onBrandContainer,
          secondary: tokens.brand,
          onSecondary: tokens.onBrand,
          secondaryContainer: tokens.brandContainer,
          onSecondaryContainer: tokens.onBrandContainer,
          surface: tokens.surface,
          onSurface: tokens.contentPrimary,
          surfaceDim: tokens.canvas,
          surfaceBright: tokens.surfaceRaised,
          surfaceContainerLowest: tokens.canvas,
          surfaceContainerLow: tokens.surface,
          surfaceContainer: tokens.surface,
          surfaceContainerHigh: tokens.surfaceRaised,
          surfaceContainerHighest: tokens.surfaceRaised,
          onSurfaceVariant: tokens.contentSecondary,
          outline: tokens.outline,
          outlineVariant: tokens.outline.withValues(alpha: 0.65),
          error: tokens.danger,
          onError: brightness == Brightness.dark
              ? const Color(0xFF2A1114)
              : Colors.white,
          errorContainer: tokens.dangerContainer,
          onErrorContainer: tokens.onDangerContainer,
          shadow: Colors.black.withValues(
            alpha: brightness == Brightness.dark ? 0.28 : 0.14,
          ),
          scrim: Colors.black.withValues(alpha: 0.58),
        );
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      canvasColor: tokens.canvas,
      fontFamily: 'Readex Pro',
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
    );
    final textTheme = baseTheme.textTheme
        .copyWith(
          displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
            fontSize: 30,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
            fontSize: 26,
            height: 1.3,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.55,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        )
        .apply(
          fontFamily: 'Readex Pro',
          bodyColor: tokens.contentPrimary,
          displayColor: tokens.contentPrimary,
        );
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppVisualMetrics.radiusControl),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppVisualMetrics.radiusCard),
      side: BorderSide(color: tokens.outline.withValues(alpha: 0.72)),
    );
    final overlayColor = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed)) {
        return tokens.brand.withValues(alpha: 0.14);
      }
      if (states.contains(WidgetState.focused)) {
        return tokens.brand.withValues(alpha: 0.11);
      }
      if (states.contains(WidgetState.hovered)) {
        return tokens.brand.withValues(alpha: 0.07);
      }
      return null;
    });

    return baseTheme.copyWith(
      extensions: [tokens],
      textTheme: textTheme,
      dividerColor: tokens.outline,
      focusColor: tokens.brand.withValues(alpha: 0.12),
      hoverColor: tokens.brand.withValues(alpha: 0.07),
      highlightColor: tokens.brand.withValues(alpha: 0.10),
      splashColor: tokens.brand.withValues(alpha: 0.12),
      appBarTheme: AppBarThemeData(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.contentPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: systemOverlayStyleFor(baseTheme),
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: tokens.surface,
        indicatorColor: tokens.brandContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.onBrandContainer : tokens.contentSecondary,
            size: selected ? 25 : 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? tokens.onBrandContainer : tokens.contentSecondary,
            fontFamily: 'Readex Pro',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.brandContainer,
        useIndicator: true,
        elevation: 0,
        selectedIconTheme: IconThemeData(color: tokens.onBrandContainer),
        unselectedIconTheme: IconThemeData(color: tokens.contentSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: tokens.onBrandContainer,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: tokens.contentSecondary,
        ),
      ),
      bottomAppBarTheme: BottomAppBarThemeData(
        color: tokens.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(
            end: Radius.circular(AppVisualMetrics.radiusOverlay),
          ),
        ),
        scrimColor: colorScheme.scrim,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppVisualMetrics.radiusOverlay),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: cardShape,
      ),
      chipTheme: baseTheme.chipTheme.copyWith(
        selectedColor: tokens.brandContainer,
        backgroundColor: tokens.surfaceRaised,
        side: BorderSide(color: tokens.outline.withValues(alpha: 0.86)),
        labelStyle: TextStyle(color: tokens.contentPrimary),
        secondaryLabelStyle: TextStyle(
          color: tokens.onBrandContainer,
          fontFamily: 'Readex Pro',
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusSmall),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.outline.withValues(alpha: 0.72),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.contentSecondary,
        textColor: tokens.contentPrimary,
        minTileHeight: AppVisualMetrics.minimumTouchTarget,
        shape: controlShape,
        titleTextStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: tokens.contentSecondary,
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: tokens.surfaceRaised,
        hintStyle: TextStyle(color: tokens.contentSecondary),
        prefixIconColor: tokens.contentSecondary,
        suffixIconColor: tokens.contentSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusControl),
          borderSide: BorderSide(color: tokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusControl),
          borderSide: BorderSide(color: tokens.outline.withValues(alpha: 0.78)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusControl),
          borderSide: BorderSide(color: tokens.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusControl),
          borderSide: BorderSide(color: tokens.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusControl),
          borderSide: BorderSide(color: tokens.danger, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppVisualMetrics.minimumTouchTarget),
          ),
          foregroundColor: WidgetStatePropertyAll(tokens.brand),
          overlayColor: overlayColor,
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Readex Pro', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppVisualMetrics.minimumTouchTarget),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return tokens.surfaceRaised;
            }
            return tokens.brand;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return tokens.contentSecondary;
            }
            return tokens.onBrand;
          }),
          overlayColor: WidgetStatePropertyAll(
            tokens.onBrand.withValues(alpha: 0.12),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Readex Pro', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppVisualMetrics.minimumTouchTarget),
          ),
          foregroundColor: WidgetStatePropertyAll(tokens.brand),
          overlayColor: overlayColor,
          side: WidgetStatePropertyAll(BorderSide(color: tokens.outline)),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Readex Pro', fontWeight: FontWeight.w600),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppVisualMetrics.minimumTouchTarget),
          ),
          foregroundColor: WidgetStatePropertyAll(tokens.contentPrimary),
          overlayColor: overlayColor,
          shape: WidgetStatePropertyAll(controlShape),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusOverlay),
          side: BorderSide(color: tokens.outline.withValues(alpha: 0.7)),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.contentPrimary,
        ),
        actionTextColor: tokens.brand,
        elevation: 6,
        shape: controlShape,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: tokens.outline.withValues(alpha: 0.55),
        indicatorColor: tokens.brand,
        labelColor: tokens.brand,
        unselectedLabelColor: tokens.contentSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        overlayColor: overlayColor,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(48, AppVisualMetrics.minimumTouchTarget),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? tokens.brandContainer
                : tokens.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? tokens.onBrandContainer
                : tokens.contentSecondary;
          }),
          overlayColor: overlayColor,
          side: WidgetStatePropertyAll(BorderSide(color: tokens.outline)),
          shape: WidgetStatePropertyAll(controlShape),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.brand
              : tokens.surfaceRaised;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.onBrand
              : tokens.contentSecondary;
        }),
        trackOutlineColor: WidgetStatePropertyAll(tokens.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.brand
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(tokens.onBrand),
        side: BorderSide(color: tokens.outline, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        overlayColor: overlayColor,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? tokens.brand
              : tokens.contentSecondary;
        }),
        overlayColor: overlayColor,
      ),
      sliderTheme: baseTheme.sliderTheme.copyWith(
        activeTrackColor: tokens.brand,
        inactiveTrackColor: tokens.surfaceRaised,
        thumbColor: tokens.brand,
        overlayColor: tokens.brand.withValues(alpha: 0.14),
        trackHeight: 3,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.brand,
        linearTrackColor: tokens.surfaceRaised,
        circularTrackColor: tokens.surfaceRaised,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: tokens.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: colorScheme.shadow,
        shape: controlShape,
        textStyle: textTheme.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          border: Border.all(color: tokens.outline),
          borderRadius: BorderRadius.circular(AppVisualMetrics.radiusSmall),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: tokens.contentPrimary),
        waitDuration: const Duration(milliseconds: 450),
      ),
    );
  }
}
