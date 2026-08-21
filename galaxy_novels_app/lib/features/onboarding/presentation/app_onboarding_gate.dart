import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../application/app_onboarding_controller.dart';
import 'app_onboarding_screen.dart';

class AppOnboardingGate extends StatefulWidget {
  const AppOnboardingGate({
    required this.controller,
    required this.child,
    super.key,
  });

  final AppOnboardingController controller;
  final Widget child;

  @override
  State<AppOnboardingGate> createState() => _AppOnboardingGateState();
}

class _AppOnboardingGateState extends State<AppOnboardingGate> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.initialize());
  }

  @override
  void didUpdateWidget(covariant AppOnboardingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      unawaited(widget.controller.initialize());
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, child) {
      if (widget.controller.isLoading) {
        return const _OnboardingHoldingView();
      }
      if (widget.controller.shouldShowAutomatic) {
        return AppOnboardingScreen(
          controller: widget.controller,
          entryPoint: AppOnboardingEntryPoint.automatic,
          onFinished: () {},
          onExitRequested: SystemNavigator.pop,
        );
      }
      return child!;
    },
    child: widget.child,
  );
}

class _OnboardingHoldingView extends StatelessWidget {
  const _OnboardingHoldingView();

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    return ColoredBox(
      key: const ValueKey('onboarding-holding-view'),
      color: tokens.canvas,
      child: SafeArea(
        child: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tokens.brandContainer,
              borderRadius: BorderRadius.circular(GalaxyMetrics.radiusCard),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: tokens.onBrandContainer,
              size: 38,
            ),
          ),
        ),
      ),
    );
  }
}
