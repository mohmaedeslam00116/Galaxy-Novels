import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/data/admob_initialization_coordinator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  test(
    'runs consent update, required form, permission check, and SDK init in order',
    () async {
      final events = <String>[];
      final coordinator = AdMobInitializationCoordinator(
        isAndroid: () => true,
        updateConsentInfo: () async => events.add('update'),
        showConsentFormIfRequired: () async => events.add('form'),
        canRequestAds: () async {
          events.add('canRequest');
          return true;
        },
        initializeMobileAds: () async => events.add('mobileAds'),
      );

      expect(await coordinator.initialize(), isTrue);
      expect(events, ['update', 'form', 'canRequest', 'mobileAds']);
    },
  );

  test(
    'does not show a form or initialize ads when consent update fails',
    () async {
      final events = <String>[];
      final coordinator = AdMobInitializationCoordinator(
        isAndroid: () => true,
        updateConsentInfo: () {
          events.add('update');
          return Future<void>.error(
            FormError(errorCode: 1, message: 'update failed'),
          );
        },
        showConsentFormIfRequired: () async => events.add('form'),
        canRequestAds: () async {
          events.add('canRequest');
          return true;
        },
        initializeMobileAds: () async => events.add('mobileAds'),
      );

      expect(await coordinator.initialize(), isFalse);
      expect(events, ['update']);
    },
  );

  test(
    'retries initialization after a temporary consent update failure',
    () async {
      var consentAttempts = 0;
      final coordinator = AdMobInitializationCoordinator(
        isAndroid: () => true,
        updateConsentInfo: () {
          consentAttempts++;
          if (consentAttempts == 1) {
            return Future<void>.error(
              FormError(errorCode: 1, message: 'temporary failure'),
            );
          }
          return Future<void>.value();
        },
        showConsentFormIfRequired: () async {},
        canRequestAds: () async => true,
        initializeMobileAds: () async {},
      );

      expect(await coordinator.initialize(), isFalse);
      expect(await coordinator.initialize(), isTrue);
      expect(consentAttempts, 2);
    },
  );

  test(
    'does not initialize ads when the consent form reports an error',
    () async {
      final events = <String>[];
      final coordinator = AdMobInitializationCoordinator(
        isAndroid: () => true,
        updateConsentInfo: () async => events.add('update'),
        showConsentFormIfRequired: () {
          events.add('form');
          return Future<void>.error(
            FormError(errorCode: 2, message: 'form failed'),
          );
        },
        canRequestAds: () async {
          events.add('canRequest');
          return true;
        },
        initializeMobileAds: () async => events.add('mobileAds'),
      );

      expect(await coordinator.initialize(), isFalse);
      expect(events, ['update', 'form']);
    },
  );

  test('does not initialize ads when canRequestAds is false', () async {
    final events = <String>[];
    final coordinator = AdMobInitializationCoordinator(
      isAndroid: () => true,
      updateConsentInfo: () async => events.add('update'),
      showConsentFormIfRequired: () async => events.add('form'),
      canRequestAds: () async {
        events.add('canRequest');
        return false;
      },
      initializeMobileAds: () async => events.add('mobileAds'),
    );

    expect(await coordinator.initialize(), isFalse);
    expect(events, ['update', 'form', 'canRequest']);
  });

  test('shares one initialization future across concurrent callers', () async {
    final consentCompletion = Completer<void>();
    var consentUpdates = 0;
    var consentForms = 0;
    var permissionChecks = 0;
    var sdkInitializations = 0;
    final coordinator = AdMobInitializationCoordinator(
      isAndroid: () => true,
      updateConsentInfo: () {
        consentUpdates++;
        return consentCompletion.future;
      },
      showConsentFormIfRequired: () async => consentForms++,
      canRequestAds: () async {
        permissionChecks++;
        return true;
      },
      initializeMobileAds: () async => sdkInitializations++,
    );

    final firstInitialization = coordinator.initialize();
    final secondInitialization = coordinator.initialize();

    expect(identical(firstInitialization, secondInitialization), isTrue);
    expect(consentUpdates, 1);

    consentCompletion.complete();
    expect(await Future.wait([firstInitialization, secondInitialization]), [
      isTrue,
      isTrue,
    ]);
    expect(consentUpdates, 1);
    expect(consentForms, 1);
    expect(permissionChecks, 1);
    expect(sdkInitializations, 1);
  });

  test('returns false without plugin work outside Android', () async {
    final events = <String>[];
    final coordinator = AdMobInitializationCoordinator(
      isAndroid: () => false,
      updateConsentInfo: () async => events.add('update'),
      showConsentFormIfRequired: () async => events.add('form'),
      canRequestAds: () async {
        events.add('canRequest');
        return true;
      },
      initializeMobileAds: () async => events.add('mobileAds'),
    );

    expect(coordinator.isSupported, isFalse);
    expect(await coordinator.initialize(), isFalse);
    expect(events, isEmpty);
  });
}
