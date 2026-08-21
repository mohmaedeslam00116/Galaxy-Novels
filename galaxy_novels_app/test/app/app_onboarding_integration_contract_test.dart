import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'startup places onboarding after forced updates and before app-open ads',
    () {
      final source = File('lib/app/galaxy_novels_app.dart').readAsStringSync();
      final update = source.indexOf('child: AppUpdateGate(');
      final onboarding = source.indexOf('child: AppOnboardingGate(');
      final appOpen = source.indexOf('child: AppOpenAdHost(');

      expect(update, greaterThanOrEqualTo(0));
      expect(onboarding, greaterThan(update));
      expect(appOpen, greaterThan(onboarding));
      expect(source, contains('suppressColdStartAd:'));
      expect(source, contains('.suppressColdStartAdForSession'));
    },
  );

  test('settings forwards the onboarding controller to About', () {
    final dependencies = File(
      'lib/app/app_dependencies.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/features/settings/presentation/settings_screen.dart',
    ).readAsStringSync();

    expect(dependencies, contains('appOnboardingController'));
    expect(settings, contains('onboardingController:'));
    expect(settings, contains('.appOnboardingController'));
  });
}
