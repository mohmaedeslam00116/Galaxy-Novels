import 'package:flutter/material.dart';

import 'app_empty_state.dart';
import 'app_skeleton.dart';

enum AppAsyncStateKind { loading, data, empty, error }

class AppAsyncState extends StatelessWidget {
  const AppAsyncState.loading({
    this.loadingLabel = 'جارٍ تحميل المحتوى',
    super.key,
  }) : kind = AppAsyncStateKind.loading,
       child = null,
       title = null,
       message = null,
       actionLabel = null,
       onAction = null;

  const AppAsyncState.data({required this.child, super.key})
    : kind = AppAsyncStateKind.data,
      loadingLabel = null,
      title = null,
      message = null,
      actionLabel = null,
      onAction = null;

  const AppAsyncState.empty({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : kind = AppAsyncStateKind.empty,
       loadingLabel = null,
       child = null;

  const AppAsyncState.error({
    required this.title,
    required this.message,
    required VoidCallback onRetry,
    super.key,
  }) : kind = AppAsyncStateKind.error,
       loadingLabel = null,
       child = null,
       actionLabel = 'إعادة المحاولة',
       onAction = onRetry;

  final AppAsyncStateKind kind;
  final String? loadingLabel;
  final Widget? child;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => switch (kind) {
    AppAsyncStateKind.loading => Semantics(
      label: loadingLabel,
      liveRegion: true,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            AppSkeleton(height: 160),
            SizedBox(height: 12),
            AppSkeleton(height: 20),
            SizedBox(height: 8),
            AppSkeleton(height: 20, width: 220),
          ],
        ),
      ),
    ),
    AppAsyncStateKind.data => child!,
    AppAsyncStateKind.empty => AppEmptyState(
      title: title!,
      message: message!,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
    AppAsyncStateKind.error => Semantics(
      key: const ValueKey('app-async-error-semantics'),
      container: true,
      liveRegion: true,
      child: AppEmptyState(
        icon: Icons.cloud_off_rounded,
        title: title!,
        message: message!,
        actionLabel: actionLabel,
        onAction: onAction,
        actionKey: const ValueKey('app-async-retry'),
      ),
    ),
  };
}
