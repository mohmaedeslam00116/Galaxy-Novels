import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/ad_privacy_options_repository.dart';
import 'admob_initialization_coordinator.dart';

typedef PrivacyStatusLoader =
    Future<PrivacyOptionsRequirementStatus> Function();
typedef PrivacyFormPresenter = Future<void> Function();

class AdMobAdPrivacyOptionsRepository implements AdPrivacyOptionsRepository {
  AdMobAdPrivacyOptionsRepository({
    required AdMobInitializationCoordinator coordinator,
    PrivacyStatusLoader? statusLoader,
    PrivacyFormPresenter? formPresenter,
  }) : _coordinator = coordinator,
       _statusLoader =
           statusLoader ??
           ConsentInformation.instance.getPrivacyOptionsRequirementStatus,
       _formPresenter = formPresenter ?? _showPrivacyOptionsForm;

  final AdMobInitializationCoordinator _coordinator;
  final PrivacyStatusLoader _statusLoader;
  final PrivacyFormPresenter _formPresenter;

  @override
  Future<AdPrivacyOptionsStatus> loadStatus() async {
    if (!_coordinator.isSupported) {
      return AdPrivacyOptionsStatus.unavailable;
    }
    try {
      await _coordinator.initialize();
      final status = await _statusLoader();
      return switch (status) {
        PrivacyOptionsRequirementStatus.required =>
          AdPrivacyOptionsStatus.required,
        PrivacyOptionsRequirementStatus.notRequired =>
          AdPrivacyOptionsStatus.notRequired,
        PrivacyOptionsRequirementStatus.unknown =>
          AdPrivacyOptionsStatus.unavailable,
      };
    } on PlatformException {
      return AdPrivacyOptionsStatus.unavailable;
    } on FormError {
      return AdPrivacyOptionsStatus.unavailable;
    }
  }

  @override
  Future<AdPrivacyOptionsOutcome> show() async {
    if (!_coordinator.isSupported) {
      return AdPrivacyOptionsOutcome.unavailable;
    }
    try {
      await _formPresenter();
      return AdPrivacyOptionsOutcome.shown;
    } on PlatformException {
      return AdPrivacyOptionsOutcome.unavailable;
    } on FormError {
      return AdPrivacyOptionsOutcome.unavailable;
    }
  }
}

Future<void> _showPrivacyOptionsForm() {
  final completer = Completer<void>();
  final presentation = ConsentForm.showPrivacyOptionsForm((error) {
    if (error == null) {
      completer.complete();
    } else {
      completer.completeError(error);
    }
  });
  unawaited(
    presentation.catchError((Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }),
  );
  return completer.future;
}
