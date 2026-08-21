import 'package:flutter/foundation.dart';

import '../../../core/analytics/app_analytics.dart';
import '../domain/app_onboarding_state.dart';
import 'app_onboarding_store.dart';

enum AppOnboardingEntryPoint { automatic, manual }

class AppOnboardingController extends ChangeNotifier {
  AppOnboardingController({
    required AppOnboardingStore store,
    required AppAnalytics analytics,
    DateTime Function()? now,
    AppOnboardingState? initialState,
  }) : _store = store,
       _analytics = analytics,
       _now = now ?? DateTime.now,
       _state = initialState ?? const AppOnboardingState.pending(),
       _isLoading = initialState == null,
       _suppressColdStartAdForSession =
           initialState != null && !initialState.isCurrentVersionComplete;

  final AppOnboardingStore _store;
  final AppAnalytics _analytics;
  final DateTime Function() _now;

  AppOnboardingState _state;
  Future<void>? _initialization;
  bool _isLoading;
  bool _isCompleting = false;
  bool _suppressColdStartAdForSession;

  AppOnboardingState get state => _state;
  bool get isLoading => _isLoading;
  bool get isCompleting => _isCompleting;
  bool get shouldShowAutomatic =>
      !_isLoading && !_state.isCurrentVersionComplete;
  bool get suppressColdStartAdForSession => _suppressColdStartAdForSession;

  Future<void> initialize() =>
      _initialization ??= _isLoading ? _load() : Future<void>.value();

  Future<void> _load() async {
    AppOnboardingState? restored;
    try {
      restored = await _store.read();
    } on Object {
      await _log(
        'onboarding_persistence_failed',
        parameters: const {'operation': 'read'},
      );
    }
    _state = restored ?? const AppOnboardingState.pending();
    _suppressColdStartAdForSession = !_state.isCurrentVersionComplete;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> recordShown(AppOnboardingEntryPoint entryPoint) async {
    if (entryPoint == AppOnboardingEntryPoint.manual) {
      await recordManualReopened();
      return;
    }
    await _logScreenView();
    await _log(
      'onboarding_started',
      parameters: const {'entry_point': 'automatic'},
    );
  }

  Future<void> recordPageView({
    required int pageNumber,
    required AppOnboardingEntryPoint entryPoint,
  }) => _log(
    'onboarding_page_view',
    parameters: {'page_number': pageNumber, 'entry_point': entryPoint.name},
  );

  Future<void> recordManualReopened() async {
    await _logScreenView();
    await _log(
      'onboarding_reopened',
      parameters: const {'entry_point': 'manual'},
    );
  }

  Future<void> completeAutomatic(AppOnboardingCompletionMethod method) async {
    if (_isCompleting || _state.isCurrentVersionComplete) return;
    _isCompleting = true;
    _state = AppOnboardingState.completed(
      completedAt: _now().toUtc(),
      method: method,
    );
    notifyListeners();

    try {
      await _store.write(_state);
    } on Object {
      await _log(
        'onboarding_persistence_failed',
        parameters: const {'operation': 'write'},
      );
    }
    await _log(
      method == AppOnboardingCompletionMethod.skipped
          ? 'onboarding_skipped'
          : 'onboarding_completed',
      parameters: {'completion_method': method.name},
    );
    _isCompleting = false;
    notifyListeners();
  }

  Future<void> _log(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name, parameters: parameters);
    } on Object {
      // Analytics must never interrupt startup or onboarding navigation.
    }
  }

  Future<void> _logScreenView() async {
    try {
      await _analytics.logScreenView('onboarding');
    } on Object {
      // Analytics must never interrupt startup or onboarding navigation.
    }
  }
}
