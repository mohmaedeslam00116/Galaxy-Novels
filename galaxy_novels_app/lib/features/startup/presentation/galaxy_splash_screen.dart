import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GalaxySplashGate extends StatefulWidget {
  const GalaxySplashGate({
    required this.duration,
    required this.child,
    super.key,
  });

  final Duration duration;
  final Widget child;

  @override
  State<GalaxySplashGate> createState() => _GalaxySplashGateState();
}

class _GalaxySplashGateState extends State<GalaxySplashGate> {
  Timer? _timer;
  int _dismissalGeneration = 0;
  late bool _showSplash = widget.duration > Duration.zero;

  @override
  void initState() {
    super.initState();
    _scheduleDismissal();
  }

  @override
  void didUpdateWidget(covariant GalaxySplashGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration == widget.duration) {
      return;
    }

    _timer?.cancel();
    _timer = null;
    _dismissalGeneration += 1;
    if (widget.duration <= Duration.zero) {
      _showSplash = false;
      return;
    }
    if (_showSplash) {
      _scheduleDismissal();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.duration <= Duration.zero) {
      return widget.child;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showSplash
          ? const GalaxySplashScreen(key: ValueKey('galaxy-splash-view'))
          : KeyedSubtree(
              key: const ValueKey('galaxy-splash-child'),
              child: widget.child,
            ),
    );
  }

  void _scheduleDismissal() {
    _timer?.cancel();
    _timer = null;
    if (!_showSplash || widget.duration <= Duration.zero) {
      return;
    }

    final generation = ++_dismissalGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _dismissalGeneration ||
          !_showSplash ||
          widget.duration <= Duration.zero) {
        return;
      }

      _timer = Timer(widget.duration, () {
        _timer = null;
        if (!mounted || generation != _dismissalGeneration) {
          return;
        }
        setState(() => _showSplash = false);
      });
    });
  }

  @override
  void dispose() {
    _dismissalGeneration += 1;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

class GalaxySplashScreen extends StatefulWidget {
  const GalaxySplashScreen({super.key});

  @override
  State<GalaxySplashScreen> createState() => _GalaxySplashScreenState();
}

class _GalaxySplashScreenState extends State<GalaxySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();
  late final Animation<double> _entrance = CurvedAnimation(
    parent: _entranceController,
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _SplashPalette.background,
        systemNavigationBarDividerColor: _SplashPalette.background,
      ),
      child: Scaffold(
        key: const ValueKey('galaxy-splash-screen'),
        backgroundColor: _SplashPalette.background,
        body: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                key: ValueKey('splash-background-pattern'),
                painter: _CosmicBackdropPainter(),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 600;
                  final markSize = (constraints.maxHeight * 0.30).clamp(
                    132.0,
                    220.0,
                  );
                  final sectionGap = compact ? 12.0 : 18.0;

                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: compact ? 12 : 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (compact ? 24 : 48),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: AnimatedBuilder(
                            animation: _entrance,
                            child: _SplashContent(
                              markSize: markSize,
                              sectionGap: sectionGap,
                              compact: compact,
                            ),
                            builder: (context, child) {
                              final progress = disableAnimations
                                  ? 1.0
                                  : _entrance.value;
                              return Opacity(
                                opacity: progress,
                                child: Transform.scale(
                                  scale: 0.96 + (0.04 * progress),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.markSize,
    required this.sectionGap,
    required this.compact,
  });

  final double markSize;
  final double sectionGap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: markSize * 0.82,
                height: markSize * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _SplashPalette.indigo.withValues(alpha: 0.16),
                      _SplashPalette.blue.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _SplashPalette.indigo.withValues(alpha: 0.12),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/branding/galaxy_novels_splash_mark.png',
                key: const ValueKey('splash-brand-mark'),
                width: markSize,
                height: markSize,
                fit: BoxFit.contain,
                semanticLabel: 'شعار مجرة الروايات',
                filterQuality: FilterQuality.high,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 8 : 14),
        Text(
          'مجرة الروايات',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: _SplashPalette.text,
            fontFamily: 'El Messiri',
            fontSize: compact ? 29 : 34,
            fontWeight: FontWeight.w800,
            height: 1.22,
          ),
        ),
        SizedBox(height: compact ? 6 : 9),
        Text(
          'كل حكاية تبدأ من نجمة',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: _SplashPalette.textMuted,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
        SizedBox(height: sectionGap),
        const _StellarOrbitLoader(key: ValueKey('stellar-orbit-loader')),
        SizedBox(height: compact ? 4 : 7),
        Text(
          'نُهيّئ لك عالماً من الحكايات...',
          key: const ValueKey('splash-status-copy'),
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: _SplashPalette.textMuted.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _StellarOrbitLoader extends StatefulWidget {
  const _StellarOrbitLoader({super.key});

  @override
  State<_StellarOrbitLoader> createState() => _StellarOrbitLoaderState();
}

class _StellarOrbitLoaderState extends State<_StellarOrbitLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _controller
        ..stop()
        ..value = 0.18;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 56,
        height: 40,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _StellarOrbitPainter(progress: _controller.value),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _StellarOrbitPainter extends CustomPainter {
  const _StellarOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radiusX = 19.0;
    const radiusY = 9.0;
    final orbitRect = Rect.fromCenter(
      center: center,
      width: radiusX * 2,
      height: radiusY * 2,
    );
    canvas.drawOval(
      orbitRect,
      Paint()
        ..color = _SplashPalette.blue.withValues(alpha: 0.20)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = _SplashPalette.gold.withValues(alpha: 0.20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(center, 2.2, Paint()..color = _SplashPalette.gold);

    const colors = [
      _SplashPalette.blue,
      _SplashPalette.indigo,
      _SplashPalette.gold,
    ];
    for (var index = 0; index < 3; index += 1) {
      final angle = (progress * math.pi * 2) + (index * math.pi * 2 / 3);
      final point = center.translate(
        math.cos(angle) * radiusX,
        math.sin(angle) * radiusY,
      );
      final color = colors[index];
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = color.withValues(alpha: 0.24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(point, 2.3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _StellarOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CosmicBackdropPainter extends CustomPainter {
  const _CosmicBackdropPainter();

  static const _stars = <(double, double, double)>[
    (0.08, 0.12, 1.3),
    (0.19, 0.23, 0.9),
    (0.31, 0.10, 1.0),
    (0.47, 0.18, 1.5),
    (0.65, 0.09, 0.8),
    (0.82, 0.20, 1.2),
    (0.92, 0.11, 0.7),
    (0.12, 0.42, 0.8),
    (0.24, 0.56, 1.1),
    (0.76, 0.49, 0.8),
    (0.90, 0.58, 1.4),
    (0.08, 0.74, 0.7),
    (0.21, 0.87, 1.2),
    (0.39, 0.78, 0.8),
    (0.58, 0.88, 1.0),
    (0.77, 0.79, 1.3),
    (0.93, 0.90, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final glowRect = Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.34),
      radius: math.max(size.width, size.height) * 0.46,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(0, -0.30),
          radius: 0.92,
          colors: [
            _SplashPalette.violet.withValues(alpha: 0.16),
            _SplashPalette.deepBlue.withValues(alpha: 0.07),
            Colors.transparent,
          ],
          stops: [0, 0.52, 1],
        ).createShader(glowRect),
    );

    final blueOrbit = Paint()
      ..color = _SplashPalette.blue.withValues(alpha: 0.12)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    final indigoOrbit = Paint()
      ..color = _SplashPalette.indigo.withValues(alpha: 0.10)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final orbitCenter = Offset(size.width * 0.5, size.height * 0.34);
    canvas.drawArc(
      Rect.fromCenter(
        center: orbitCenter,
        width: size.width * 0.92,
        height: size.width * 0.42,
      ),
      math.pi * 1.08,
      math.pi * 0.86,
      false,
      blueOrbit,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: orbitCenter,
        width: size.width * 0.72,
        height: size.width * 0.56,
      ),
      math.pi * 0.10,
      math.pi * 0.88,
      false,
      indigoOrbit,
    );

    for (var index = 0; index < _stars.length; index += 1) {
      final star = _stars[index];
      final point = Offset(star.$1 * size.width, star.$2 * size.height);
      final color = index % 5 == 0 ? _SplashPalette.gold : _SplashPalette.text;
      final paint = Paint()
        ..color = color.withValues(alpha: index.isEven ? 0.52 : 0.34);
      canvas.drawCircle(point, star.$3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBackdropPainter oldDelegate) => false;
}

abstract final class _SplashPalette {
  static const background = Color(0xFF0E1520);
  static const deepBlue = Color(0xFF141E2B);
  static const violet = Color(0xFF263A52);
  static const blue = Color(0xFF8EA9D1);
  static const indigo = Color(0xFF6F819A);
  static const gold = Color(0xFFC5A568);
  static const text = Color(0xFFE8EDF4);
  static const textMuted = Color(0xFFA8B3C2);
}
