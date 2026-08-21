import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

typedef AdsPlatformCheck = bool Function();
typedef AdsAsyncStep = Future<void> Function();
typedef AdsPermissionCheck = Future<bool> Function();

class AdMobInitializationCoordinator {
  AdMobInitializationCoordinator({
    AdsPlatformCheck? isAndroid,
    AdsAsyncStep? updateConsentInfo,
    AdsAsyncStep? showConsentFormIfRequired,
    AdsPermissionCheck? canRequestAds,
    AdsAsyncStep? initializeMobileAds,
  }) : _isAndroid = isAndroid ?? _isAndroidPlatform,
       _updateConsentInfo = updateConsentInfo ?? _requestConsentInfoUpdate,
       _showConsentFormIfRequired =
           showConsentFormIfRequired ?? _showRequiredConsentForm,
       _canRequestAds =
           canRequestAds ?? ConsentInformation.instance.canRequestAds,
       _initializeMobileAds = initializeMobileAds ?? _initializeSdk;

  static final shared = AdMobInitializationCoordinator();

  final AdsPlatformCheck _isAndroid;
  final AdsAsyncStep _updateConsentInfo;
  final AdsAsyncStep _showConsentFormIfRequired;
  final AdsPermissionCheck _canRequestAds;
  final AdsAsyncStep _initializeMobileAds;
  Future<bool>? _initialization;

  bool get isSupported => _isAndroid();

  Future<bool> initialize() {
    return _initialization ??= isSupported
        ? _initializeSupportedPlatform()
        : Future<bool>.value(false);
  }

  Future<bool> _initializeSupportedPlatform() async {
    try {
      await _updateConsentInfo();
      await _showConsentFormIfRequired();
      if (!await _canRequestAds()) {
        return false;
      }
      await _initializeMobileAds();
      return true;
    } on Object {
      // FormError is not an Exception; every SDK failure means ads unavailable.
      // Only errors are retried: a normal "cannot request ads" result stays
      // cached, while a later reader entry can recover from a transient SDK
      // or consent failure.
      _initialization = null;
      return false;
    }
  }
}

bool _isAndroidPlatform() {
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

Future<void> _requestConsentInfoUpdate() {
  final completer = Completer<void>();
  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    completer.complete,
    (error) => completer.completeError(error),
  );
  return completer.future;
}

Future<void> _showRequiredConsentForm() {
  final completer = Completer<void>();
  final presentation = ConsentForm.loadAndShowConsentFormIfRequired((error) {
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

Future<void> _initializeSdk() async {
  await MobileAds.instance.initialize();
}
