import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/analytics/app_analytics.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_controller.dart';
import 'package:galaxy_novels_app/features/onboarding/application/app_onboarding_store.dart';
import 'package:galaxy_novels_app/features/onboarding/domain/app_onboarding_state.dart';
import 'package:galaxy_novels_app/features/onboarding/presentation/app_onboarding_gate.dart';

void main() {
  testWidgets('pending first launch shows onboarding instead of app content', (
    tester,
  ) async {
    final controller = _controller(_Store());

    await tester.pumpWidget(_surface(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-onboarding-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-content')), findsNothing);
  });

  testWidgets('completed launch shows app content', (tester) async {
    final controller = _controller(
      _Store(
        AppOnboardingState.completed(
          completedAt: DateTime.utc(2026, 8, 12),
          method: AppOnboardingCompletionMethod.completed,
        ),
      ),
    );

    await tester.pumpWidget(_surface(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-content')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-onboarding-screen')), findsNothing);
  });
}

Widget _surface(AppOnboardingController controller) => MaterialApp(
  theme: AppTheme.dark(),
  home: AppOnboardingGate(
    controller: controller,
    child: const SizedBox(key: ValueKey('app-content')),
  ),
);

AppOnboardingController _controller(_Store store) =>
    AppOnboardingController(store: store, analytics: const NoopAppAnalytics());

class _Store implements AppOnboardingStore {
  _Store([this.value]);
  AppOnboardingState? value;

  @override
  Future<AppOnboardingState?> read() async => value;

  @override
  Future<void> write(AppOnboardingState state) async => value = state;
}
