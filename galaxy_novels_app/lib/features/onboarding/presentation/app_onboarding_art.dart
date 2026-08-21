import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';

enum AppOnboardingArtVariant { discovery, reading, offline }

class AppOnboardingArt extends StatelessWidget {
  const AppOnboardingArt({required this.variant, super.key});

  final AppOnboardingArtVariant variant;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return RepaintBoundary(
      child: AspectRatio(
        aspectRatio: 1.35,
        child: CustomPaint(
          painter: _GalaxyBackdropPainter(
            brand: tokens.brand,
            outline: tokens.outline,
          ),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.62,
              heightFactor: 0.76,
              child: switch (variant) {
                AppOnboardingArtVariant.discovery => _DiscoveryArt(
                  tokens: tokens,
                ),
                AppOnboardingArtVariant.reading => _ReadingArt(tokens: tokens),
                AppOnboardingArtVariant.offline => _OfflineArt(tokens: tokens),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryArt extends StatelessWidget {
  const _DiscoveryArt({required this.tokens});

  final GalaxyDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 142,
          height: 142,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [
                tokens.brand.withValues(alpha: 0.88),
                tokens.brandContainer,
                tokens.surfaceRaised,
              ],
              stops: const [0, 0.42, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.brand.withValues(alpha: 0.18),
                blurRadius: 42,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
        Transform.rotate(
          angle: -0.22,
          child: Container(
            width: 220,
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tokens.brand.withValues(alpha: 0.58)),
            ),
          ),
        ),
        _BookTile(tokens: tokens),
        PositionedDirectional(
          top: 4,
          end: 3,
          child: _OrbitDot(color: tokens.warning, size: 13),
        ),
        PositionedDirectional(
          bottom: 18,
          start: 0,
          child: _OrbitDot(color: tokens.brand, size: 9),
        ),
      ],
    );
  }
}

class _ReadingArt extends StatelessWidget {
  const _ReadingArt({required this.tokens});

  final GalaxyDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 205,
          height: 174,
          decoration: BoxDecoration(
            color: tokens.brandContainer.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        Transform.rotate(
          angle: -0.05,
          child: Icon(
            Icons.menu_book_rounded,
            size: 142,
            color: tokens.contentPrimary,
          ),
        ),
        PositionedDirectional(
          top: 14,
          start: 12,
          child: _ArtChip(label: 'Aa', tokens: tokens),
        ),
        PositionedDirectional(
          bottom: 10,
          end: 2,
          child: _ArtChip(
            icon: Icons.format_line_spacing_rounded,
            tokens: tokens,
          ),
        ),
      ],
    );
  }
}

class _OfflineArt extends StatelessWidget {
  const _OfflineArt({required this.tokens});

  final GalaxyDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (var index = 2; index >= 0; index--)
          Transform.translate(
            offset: Offset(-index * 12, index * 12),
            child: Container(
              width: 158,
              height: 190,
              decoration: BoxDecoration(
                color: Color.lerp(
                  tokens.surfaceRaised,
                  tokens.brandContainer,
                  0.24 + index * 0.12,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: tokens.outline.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: tokens.brand,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tokens.brand.withValues(alpha: 0.24),
                blurRadius: 32,
              ),
            ],
          ),
          child: Icon(Icons.download_rounded, size: 46, color: tokens.onBrand),
        ),
        PositionedDirectional(
          bottom: 2,
          end: 0,
          child: _ArtChip(icon: Icons.history_rounded, tokens: tokens),
        ),
      ],
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.tokens});

  final GalaxyDesignTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.06,
      child: Container(
        width: 86,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [tokens.surfaceRaised, tokens.brandContainer],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.brand.withValues(alpha: 0.74)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_stories_rounded,
          color: tokens.contentPrimary,
          size: 38,
        ),
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 9),
      ],
    ),
  );
}

class _ArtChip extends StatelessWidget {
  const _ArtChip({this.label, this.icon, required this.tokens});

  final String? label;
  final IconData? icon;
  final GalaxyDesignTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
    width: 56,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tokens.surfaceRaised,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: tokens.outline),
    ),
    child: label != null
        ? Text(
            label!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: tokens.brand,
              fontWeight: FontWeight.w800,
            ),
          )
        : Icon(icon, color: tokens.brand, size: 28),
  );
}

class _GalaxyBackdropPainter extends CustomPainter {
  const _GalaxyBackdropPainter({required this.brand, required this.outline});

  final Color brand;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      math.min(size.width, size.height) * 0.43,
      Paint()
        ..shader = RadialGradient(
          colors: [brand.withValues(alpha: 0.13), brand.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    final dotPaint = Paint()..color = outline.withValues(alpha: 0.72);
    const points = [
      Offset(0.08, 0.25),
      Offset(0.18, 0.76),
      Offset(0.35, 0.1),
      Offset(0.72, 0.13),
      Offset(0.86, 0.35),
      Offset(0.91, 0.78),
      Offset(0.62, 0.9),
    ];
    for (final point in points) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        1.7,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyBackdropPainter oldDelegate) =>
      oldDelegate.brand != brand || oldDelegate.outline != outline;
}
