import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/features/startup/presentation/galaxy_splash_screen.dart';

void main() {
  testWidgets('renders the single approved splash composition', (tester) async {
    await tester.pumpWidget(
      _surface(theme: AppTheme.dark(), child: const GalaxySplashScreen()),
    );

    expect(
      find.byKey(const ValueKey('splash-background-pattern')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('splash-brand-mark')), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('splash-brand-mark')),
    );
    final scaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('galaxy-splash-screen')),
    );
    expect(scaffold.backgroundColor, const Color(0xFF0E1520));
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/galaxy_novels_splash_mark.png',
    );
    expect(find.text('مجرة الروايات'), findsOneWidget);
    expect(find.text('كل حكاية تبدأ من نجمة'), findsOneWidget);
    expect(find.text('نُهيّئ لك عالماً من الحكايات...'), findsOneWidget);
    expect(find.byKey(const ValueKey('stellar-orbit-loader')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('splash-brand-frame')), findsNothing);
    expect(find.byKey(const ValueKey('splash-variant-default')), findsNothing);
    expect(
      find.byKey(const ValueKey('splash-variant-deepSpace')),
      findsNothing,
    );
  });

  testWidgets('uses the same branded splash for every app theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(theme: AppTheme.dark(), child: const GalaxySplashScreen()),
    );
    final darkScaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('galaxy-splash-screen')),
    );

    await tester.pumpWidget(
      _surface(theme: AppTheme.light(), child: const GalaxySplashScreen()),
    );
    final lightScaffold = tester.widget<Scaffold>(
      find.byKey(const ValueKey('galaxy-splash-screen')),
    );

    expect(lightScaffold.backgroundColor, darkScaffold.backgroundColor);
    expect(find.text('كل حكاية تبدأ من نجمة'), findsOneWidget);
    expect(find.byKey(const ValueKey('stellar-orbit-loader')), findsOneWidget);
  });

  testWidgets('keeps splash content visible with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        theme: AppTheme.dark(),
        mediaQueryData: const MediaQueryData(
          disableAnimations: true,
          textScaler: TextScaler.linear(1.6),
        ),
        child: const GalaxySplashScreen(),
      ),
    );

    expect(find.text('مجرة الروايات'), findsOneWidget);
    expect(find.text('كل حكاية تبدأ من نجمة'), findsOneWidget);
    expect(find.byKey(const ValueKey('stellar-orbit-loader')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits the splash on a small phone viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _surface(theme: AppTheme.dark(), child: const GalaxySplashScreen()),
    );

    expect(find.byKey(const ValueKey('splash-brand-mark')), findsOneWidget);
    expect(find.text('كل حكاية تبدأ من نجمة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the splash briefly before revealing the app', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        theme: AppTheme.dark(),
        child: const GalaxySplashGate(
          duration: Duration(milliseconds: 1200),
          child: Text('الرئيسية'),
        ),
      ),
    );

    expect(find.byType(GalaxySplashScreen), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 241));
    await tester.pump();

    expect(find.byType(GalaxySplashScreen), findsNothing);
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('starts splash dismissal after the first frame settles', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        theme: AppTheme.dark(),
        child: const GalaxySplashGate(
          duration: Duration(milliseconds: 20),
          child: Text('الرئيسية'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 19));
    expect(find.byType(GalaxySplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 241));
    await tester.pump();

    expect(find.byType(GalaxySplashScreen), findsNothing);
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('skips the splash when startup duration is zero', (tester) async {
    await tester.pumpWidget(
      _surface(
        theme: AppTheme.dark(),
        child: const GalaxySplashGate(
          duration: Duration.zero,
          child: Text('الرئيسية'),
        ),
      ),
    );

    expect(find.byType(GalaxySplashScreen), findsNothing);
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('cancels splash dismissal when the gate is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        theme: AppTheme.dark(),
        child: const GalaxySplashGate(
          duration: Duration(milliseconds: 1200),
          child: Text('الرئيسية'),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

Widget _surface({
  required ThemeData theme,
  required Widget child,
  MediaQueryData mediaQueryData = const MediaQueryData(),
}) {
  return MaterialApp(
    theme: theme,
    home: MediaQuery(
      data: mediaQueryData,
      child: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );
}
