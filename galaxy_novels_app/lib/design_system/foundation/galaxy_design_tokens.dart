import 'package:flutter/material.dart';

enum AppThemePreset {
  starlightPaper,
  neutralDark,
  galaxyNoir,
  cosmicNight,
  lightNature,
  oceanAsh,
  moonForest,
  garnetVelvet,
  copperDusk,
  midnightTide,
}

@immutable
class GalaxyDesignTokens extends ThemeExtension<GalaxyDesignTokens> {
  const GalaxyDesignTokens({
    required this.preset,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.brand,
    required this.onBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.outline,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  final AppThemePreset preset;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color brand;
  final Color onBrand;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color outline;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  Color get background => canvas;
  Color get surfaceSoft => surfaceRaised;
  Color get primary => brand;
  Color get accent => brand;
  Color get gold => warning;
  Color get border => outline;
  Color get textPrimary => contentPrimary;
  Color get textSecondary => contentSecondary;

  static GalaxyDesignTokens of(BuildContext context) {
    return Theme.of(context).extension<GalaxyDesignTokens>() ??
        fallback(Theme.of(context).colorScheme);
  }

  static GalaxyDesignTokens fallback(ColorScheme scheme) {
    final dark = scheme.brightness == Brightness.dark;
    return GalaxyDesignTokens(
      preset: dark ? AppThemePreset.galaxyNoir : AppThemePreset.starlightPaper,
      canvas: scheme.surface,
      surface: scheme.surfaceContainerLow,
      surfaceRaised: scheme.surfaceContainerHigh,
      contentPrimary: scheme.onSurface,
      contentSecondary: scheme.onSurfaceVariant,
      brand: scheme.primary,
      onBrand: scheme.onPrimary,
      brandContainer: scheme.primaryContainer,
      onBrandContainer: scheme.onPrimaryContainer,
      outline: scheme.outlineVariant,
      success: dark ? const Color(0xFF7FAE91) : const Color(0xFF557C62),
      successContainer: dark
          ? const Color(0xFF20382A)
          : const Color(0xFFDCEADF),
      onSuccessContainer: dark
          ? const Color(0xFFC2E6CE)
          : const Color(0xFF1A3924),
      warning: dark ? const Color(0xFFC5A568) : const Color(0xFF8A6C2D),
      warningContainer: dark
          ? const Color(0xFF3B311D)
          : const Color(0xFFF2E5C1),
      onWarningContainer: dark
          ? const Color(0xFFE8D4A3)
          : const Color(0xFF3A2B0C),
      danger: dark ? const Color(0xFFD18484) : const Color(0xFFA85252),
      dangerContainer: dark ? const Color(0xFF442326) : const Color(0xFFF3DDDD),
      onDangerContainer: dark
          ? const Color(0xFFF0C3C3)
          : const Color(0xFF46191D),
    );
  }

  @override
  GalaxyDesignTokens copyWith({
    AppThemePreset? preset,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? brand,
    Color? onBrand,
    Color? brandContainer,
    Color? onBrandContainer,
    Color? outline,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? onDangerContainer,
  }) {
    return GalaxyDesignTokens(
      preset: preset ?? this.preset,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandContainer: brandContainer ?? this.brandContainer,
      onBrandContainer: onBrandContainer ?? this.onBrandContainer,
      outline: outline ?? this.outline,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  @override
  GalaxyDesignTokens lerp(
    covariant ThemeExtension<GalaxyDesignTokens>? other,
    double t,
  ) {
    if (other is! GalaxyDesignTokens) return this;
    return GalaxyDesignTokens(
      preset: t < 0.5 ? preset : other.preset,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary: Color.lerp(
        contentSecondary,
        other.contentSecondary,
        t,
      )!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      brandContainer: Color.lerp(brandContainer, other.brandContainer, t)!,
      onBrandContainer: Color.lerp(
        onBrandContainer,
        other.onBrandContainer,
        t,
      )!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
    );
  }
}

@Deprecated('Use GalaxyDesignTokens instead.')
typedef AppThemeTokens = GalaxyDesignTokens;
