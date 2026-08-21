import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../application/app_update_controller.dart';
import '../domain/app_update_state.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({
    required this.controller,
    required this.child,
    super.key,
  });

  final AppUpdateController controller;
  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant AppUpdateGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.controller.refreshPlayAvailability());
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    // First install without a trusted cached policy is fail-open while the
    // bounded Firebase fetch completes. A cached forced policy still blocks
    // immediately because it is evaluated before the remote refresh.
    if (!state.policyEvaluated) return widget.child;
    if (!state.blocksApplication) return widget.child;
    return _RequiredUpdateScreen(
      state: state,
      onUpdate: widget.controller.startUpdate,
      onRetry: widget.controller.refresh,
      onOpenStore: widget.controller.openStore,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_refresh);
    super.dispose();
  }
}

class _RequiredUpdateScreen extends StatelessWidget {
  const _RequiredUpdateScreen({
    required this.state,
    required this.onUpdate,
    required this.onRetry,
    required this.onOpenStore,
  });

  final AppUpdateState state;
  final Future<void> Function() onUpdate;
  final Future<void> Function() onRetry;
  final Future<void> Function() onOpenStore;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final busy =
        state.operation == AppUpdateOperation.checking ||
        state.operation == AppUpdateOperation.installing;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(GalaxyMetrics.space24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GalaxySurface(
                  variant: GalaxySurfaceVariant.tonal,
                  radius: GalaxyMetrics.radiusOverlay,
                  padding: const EdgeInsets.all(GalaxyMetrics.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: tokens.brandContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.system_update_alt_rounded,
                          color: tokens.onBrandContainer,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: GalaxyMetrics.space20),
                      Text(
                        state.policy.requiredTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: GalaxyMetrics.space12),
                      Text(
                        state.policy.requiredMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: tokens.contentSecondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: GalaxyMetrics.space12),
                      Text(
                        'الإصدار الحالي ${state.currentVersion} (${state.currentBuild ?? '—'})',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: tokens.contentSecondary,
                        ),
                      ),
                      if (state.errorMessage case final error?) ...[
                        const SizedBox(height: GalaxyMetrics.space12),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: tokens.danger),
                        ),
                      ],
                      const SizedBox(height: GalaxyMetrics.space24),
                      SizedBox(
                        width: double.infinity,
                        child: GalaxyButton(
                          label: busy ? 'جارٍ تجهيز التحديث…' : 'تحديث الآن',
                          icon: Icons.download_rounded,
                          onPressed: busy ? null : () => unawaited(onUpdate()),
                        ),
                      ),
                      const SizedBox(height: GalaxyMetrics.space8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: GalaxyMetrics.space8,
                        runSpacing: GalaxyMetrics.space4,
                        children: [
                          GalaxyButton(
                            label: 'إعادة المحاولة',
                            variant: GalaxyActionVariant.ghost,
                            onPressed: busy ? null : () => unawaited(onRetry()),
                          ),
                          GalaxyButton(
                            label: 'فتح Google Play',
                            variant: GalaxyActionVariant.ghost,
                            onPressed: busy
                                ? null
                                : () => unawaited(onOpenStore()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
