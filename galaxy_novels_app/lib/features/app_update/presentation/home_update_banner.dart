import 'dart:async';

import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../application/app_update_controller.dart';
import '../domain/app_update_state.dart';

class HomeUpdateBannerSliver extends StatelessWidget {
  const HomeUpdateBannerSliver({required this.controller, super.key});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.state.requirement != AppUpdateRequirement.optional) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: HomeUpdateBanner(controller: controller),
          ),
        );
      },
    );
  }
}

class HomeUpdateBanner extends StatelessWidget {
  const HomeUpdateBanner({required this.controller, super.key});

  final AppUpdateController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        if (state.requirement != AppUpdateRequirement.optional) {
          return const SizedBox.shrink();
        }
        return _OptionalUpdateCard(controller: controller, state: state);
      },
    );
  }
}

class _OptionalUpdateCard extends StatelessWidget {
  const _OptionalUpdateCard({required this.controller, required this.state});

  final AppUpdateController controller;
  final AppUpdateState state;

  @override
  Widget build(BuildContext context) {
    final tokens = GalaxyDesignTokens.of(context);
    final operation = state.operation;
    final busy =
        operation == AppUpdateOperation.downloading ||
        operation == AppUpdateOperation.installing ||
        operation == AppUpdateOperation.checking;
    final ready = operation == AppUpdateOperation.readyToInstall;
    final failed = operation == AppUpdateOperation.failed;

    return GalaxySurface(
      key: const ValueKey('home-update-banner'),
      variant: GalaxySurfaceVariant.tonal,
      radius: GalaxyMetrics.radiusCard,
      padding: const EdgeInsets.all(GalaxyMetrics.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.brandContainer,
                  borderRadius: BorderRadius.circular(
                    GalaxyMetrics.radiusControl,
                  ),
                ),
                child: Icon(
                  ready ? Icons.download_done_rounded : Icons.auto_awesome,
                  color: tokens.onBrandContainer,
                ),
              ),
              const SizedBox(width: GalaxyMetrics.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.policy.optionalTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: GalaxyMetrics.space4),
                    Text(
                      state.policy.optionalMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: tokens.contentSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (!busy && !ready)
                GalaxyIconAction(
                  icon: Icons.close_rounded,
                  tooltip: 'ذكّرني لاحقًا',
                  onPressed: () => unawaited(controller.snoozeOptionalUpdate()),
                ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: GalaxyMetrics.space12),
            const LinearProgressIndicator(),
          ],
          if (state.errorMessage case final error?) ...[
            const SizedBox(height: GalaxyMetrics.space8),
            Text(error, style: TextStyle(color: tokens.danger)),
          ],
          const SizedBox(height: GalaxyMetrics.space12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: GalaxyMetrics.space8,
            runSpacing: GalaxyMetrics.space8,
            children: [
              if (failed)
                GalaxyButton(
                  label: 'فتح Google Play',
                  variant: GalaxyActionVariant.ghost,
                  onPressed: () => unawaited(controller.openStore()),
                ),
              GalaxyButton(
                label: ready
                    ? 'تثبيت التحديث'
                    : busy
                    ? 'جارٍ التنزيل…'
                    : 'تحديث الآن',
                icon: ready
                    ? Icons.install_mobile_rounded
                    : Icons.download_rounded,
                onPressed: busy
                    ? null
                    : () => unawaited(controller.startUpdate()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
