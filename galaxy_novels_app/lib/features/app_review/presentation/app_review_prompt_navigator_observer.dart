import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/analytics/app_screen_names.dart';
import '../application/app_review_prompt_controller.dart';

class AppReviewPromptNavigatorObserver extends NavigatorObserver
    with WidgetsBindingObserver {
  AppReviewPromptNavigatorObserver({
    required AppReviewPromptController controller,
    required bool Function() isForcedUpdateActive,
    Listenable? presentationBlocker,
    this.stabilityDelay = const Duration(milliseconds: 800),
  }) : _controller = controller,
       _isForcedUpdateActive = isForcedUpdateActive,
       _presentationBlocker = presentationBlocker {
    WidgetsBinding.instance.addObserver(this);
    _presentationBlocker?.addListener(_blockerChanged);
  }

  final Duration stabilityDelay;
  AppReviewPromptController _controller;
  bool Function() _isForcedUpdateActive;
  Listenable? _presentationBlocker;
  Route<dynamic>? _topRoute;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  Timer? _timer;

  void update({
    required AppReviewPromptController controller,
    required bool Function() isForcedUpdateActive,
    Listenable? presentationBlocker,
  }) {
    _controller = controller;
    _isForcedUpdateActive = isForcedUpdateActive;
    if (_presentationBlocker != presentationBlocker) {
      _presentationBlocker?.removeListener(_blockerChanged);
      _presentationBlocker = presentationBlocker;
      _presentationBlocker?.addListener(_blockerChanged);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state != AppLifecycleState.resumed) {
      _timer?.cancel();
    } else {
      _scheduleIfPending();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _topRoute = route;
    _timer?.cancel();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _topRoute = newRoute;
    _timer?.cancel();
    _scheduleIfPending();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _topRoute = previousRoute;
    if (route.settings.name == AppScreenNames.reader) {
      _scheduleIfPending(waitForReaderDisposal: true);
    } else if (_controller.requestScheduled) {
      _scheduleIfPending();
    }
  }

  void _scheduleIfPending({bool waitForReaderDisposal = false}) {
    _timer?.cancel();
    if ((!_controller.requestScheduled && !waitForReaderDisposal) ||
        _lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _timer = Timer(stabilityDelay, () {
      final topRoute = _topRoute;
      if (!_controller.requestScheduled) return;
      final canPresent =
          _lifecycleState == AppLifecycleState.resumed &&
          topRoute is PageRoute<dynamic> &&
          !_isForcedUpdateActive();
      unawaited(_controller.tryRequestReview(canPresent: canPresent));
    });
  }

  void _blockerChanged() {
    if (_isForcedUpdateActive()) {
      _timer?.cancel();
    } else {
      _scheduleIfPending();
    }
  }

  void dispose() {
    _timer?.cancel();
    _presentationBlocker?.removeListener(_blockerChanged);
    WidgetsBinding.instance.removeObserver(this);
  }
}
