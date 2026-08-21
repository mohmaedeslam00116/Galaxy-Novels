import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/full_screen_ad_cadence.dart';

class SharedPreferencesFullScreenAdCadenceStore
    implements FullScreenAdCadenceStore {
  SharedPreferencesFullScreenAdCadenceStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences;

  static const key = 'full_screen_ad_cadence.v1';

  SharedPreferencesAsync? _preferences;
  String? _fallbackValue;

  @override
  Future<FullScreenAdCadenceState> read() async {
    String? encoded = _fallbackValue;
    final preferences = _safePreferences();
    if (preferences != null) {
      try {
        encoded = await preferences.getString(key) ?? encoded;
      } on MissingPluginException {
        // Tests and unsupported platforms use the in-memory fallback.
      } on PlatformException {
        // Ads must never block the app because persistence is unavailable.
      }
    }
    if (encoded == null || encoded.trim().isEmpty) {
      return const FullScreenAdCadenceState();
    }
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) {
        return const FullScreenAdCadenceState();
      }
      final lastAppOpenShownAt = DateTime.tryParse(
        json['last_app_open_shown_at']?.toString() ?? '',
      );
      return FullScreenAdCadenceState(
        appLaunches: _nonNegativeInt(json['app_launches']),
        lastAppOpenShownAt: lastAppOpenShownAt,
        novelDetailOpensSinceBrowseAd: _nonNegativeInt(
          json['novel_detail_opens_since_browse_ad'],
        ),
        lastFullScreenShownAt:
            DateTime.tryParse(
              json['last_full_screen_shown_at']?.toString() ?? '',
            ) ??
            lastAppOpenShownAt,
        readerForwardTransitionsSinceInterstitial: _nonNegativeInt(
          json['reader_forward_transitions_since_interstitial'],
        ),
        readerInterstitialTarget: _nonNegativeInt(
          json['reader_interstitial_target'],
        ),
        readerInterstitialRetryAtTransition: _nonNegativeInt(
          json['reader_interstitial_retry_at_transition'],
        ),
      );
    } on FormatException {
      return const FullScreenAdCadenceState();
    }
  }

  @override
  Future<void> write(FullScreenAdCadenceState state) async {
    final encoded = jsonEncode({
      'app_launches': state.appLaunches,
      'last_app_open_shown_at': state.lastAppOpenShownAt?.toIso8601String(),
      'novel_detail_opens_since_browse_ad': state.novelDetailOpensSinceBrowseAd,
      'last_full_screen_shown_at': state.lastFullScreenShownAt
          ?.toIso8601String(),
      'reader_forward_transitions_since_interstitial':
          state.readerForwardTransitionsSinceInterstitial,
      'reader_interstitial_target': state.readerInterstitialTarget,
      'reader_interstitial_retry_at_transition':
          state.readerInterstitialRetryAtTransition,
    });
    _fallbackValue = encoded;
    final preferences = _safePreferences();
    if (preferences == null) {
      return;
    }
    try {
      await preferences.setString(key, encoded);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}

int _nonNegativeInt(Object? value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return (parsed ?? 0).clamp(0, 1 << 31);
}
