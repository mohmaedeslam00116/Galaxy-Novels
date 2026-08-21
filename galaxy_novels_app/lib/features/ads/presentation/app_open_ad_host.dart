import 'dart:async';

import 'package:flutter/material.dart';

import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../../startup/presentation/galaxy_splash_screen.dart';
import '../application/full_screen_ad_repository.dart';
import '../application/standard_ad_visibility_policy.dart';

class AppOpenAdHost extends StatefulWidget {
  const AppOpenAdHost({
    required this.authRepository,
    required this.ads,
    this.suppressColdStartAd = false,
    required this.child,
    super.key,
  });

  final AuthRepository authRepository;
  final FullScreenAdRepository ads;
  final bool suppressColdStartAd;
  final Widget child;

  @override
  State<AppOpenAdHost> createState() => _AppOpenAdHostState();
}

class _AppOpenAdHostState extends State<AppOpenAdHost>
    with WidgetsBindingObserver {
  static const _minimumBackgroundDuration = Duration(minutes: 30);
  static const _startupSafetyTimeout = Duration(seconds: 6);

  late bool _coverVisible = widget.ads.isSupported;
  bool _coldStartHandled = false;
  bool _appOpenAttemptInProgress = false;
  DateTime? _backgroundedAt;
  Timer? _startupSafetyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.authRepository.addListener(_handleAuthChanged);
    _startupSafetyTimer = Timer(_startupSafetyTimeout, _handleStartupTimeout);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuthChanged());
  }

  @override
  void didUpdateWidget(covariant AppOpenAdHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authRepository != widget.authRepository) {
      oldWidget.authRepository.removeListener(_handleAuthChanged);
      widget.authRepository.addListener(_handleAuthChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_coverVisible)
          const Positioned.fill(
            child: GalaxySplashScreen(key: ValueKey('app-open-loading-cover')),
          ),
      ],
    );
  }

  void _handleAuthChanged() {
    if (_coldStartHandled || _appOpenAttemptInProgress) {
      return;
    }
    final session = widget.authRepository.value;
    final resolved =
        session.status == AuthSessionStatus.guest ||
        session.status == AuthSessionStatus.authenticated ||
        session.status == AuthSessionStatus.signingOut ||
        session.status == AuthSessionStatus.failure;
    if (!resolved) {
      return;
    }
    _coldStartHandled = true;
    _startupSafetyTimer?.cancel();
    _startupSafetyTimer = null;
    unawaited(
      _showAppOpen(
        () => widget.ads.showAppOpenOnColdStart(
          canShow:
              !widget.suppressColdStartAd &&
              StandardAdVisibilityPolicy.canShow(session),
        ),
      ),
    );
  }

  void _handleStartupTimeout() {
    _startupSafetyTimer = null;
    if (_coldStartHandled || _appOpenAttemptInProgress) {
      return;
    }
    _coldStartHandled = true;
    unawaited(
      _showAppOpen(() => widget.ads.showAppOpenOnColdStart(canShow: false)),
    );
  }

  Future<void> _showAppOpen(Future<bool> Function() show) async {
    if (_appOpenAttemptInProgress || !widget.ads.isSupported) {
      _hideCover();
      return;
    }
    _appOpenAttemptInProgress = true;
    if (mounted && !_coverVisible) {
      setState(() => _coverVisible = true);
      await WidgetsBinding.instance.endOfFrame;
    }
    try {
      await show();
    } finally {
      _appOpenAttemptInProgress = false;
      _hideCover();
    }
  }

  void _hideCover() {
    if (mounted && _coverVisible) {
      setState(() => _coverVisible = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed ||
        !_coldStartHandled ||
        _appOpenAttemptInProgress) {
      return;
    }
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null ||
        DateTime.now().difference(backgroundedAt) <
            _minimumBackgroundDuration) {
      return;
    }
    final session = widget.authRepository.value;
    unawaited(
      _showAppOpen(
        () => widget.ads.showAppOpenOnForeground(
          canShow: StandardAdVisibilityPolicy.canShow(session),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _startupSafetyTimer?.cancel();
    widget.authRepository.removeListener(_handleAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
