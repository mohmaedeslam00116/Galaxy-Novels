import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../downloads/application/download_repository.dart';
import '../../downloads/application/download_analytics.dart';
import '../../downloads/domain/download_models.dart';

Future<DownloadEnqueueResult?> enqueueChaptersWithFeedback({
  required BuildContext context,
  required DownloadNovelRequest novel,
  required List<DownloadChapterRequest> chapters,
  required String Function(DownloadEnqueueResult result) successMessage,
  VoidCallback? onOpenOperations,
}) async {
  try {
    final dependencies = AppDependencies.of(context);
    final enqueueResult = await dependencies.downloadRepository.enqueue(
      novel: novel,
      chapters: chapters,
    );
    unawaited(
      dependencies.downloadAnalytics.record(
        DownloadAnalyticsEvent.groupStarted(
          acceptedCount: enqueueResult.acceptedChapterKeys.length,
          skippedCount: enqueueResult.skippedChapterKeys.length,
          membershipTier: downloadMembershipLabel(
            dependencies.downloadRepository.value.allowance.plan,
          ),
        ),
      ),
    );
    if (context.mounted) {
      _showMessage(
        context,
        successMessage(enqueueResult),
        onOpenOperations: onOpenOperations,
      );
    }
    return enqueueResult;
  } on DownloadUnavailableException catch (downloadError) {
    debugPrint(
      'Could not start chapter download: ${downloadError.runtimeType}',
    );
    if (context.mounted) {
      final dependencies = AppDependencies.of(context);
      unawaited(
        dependencies.downloadAnalytics.record(
          DownloadAnalyticsEvent.groupFailed(
            chapterCount: chapters.length,
            membershipTier: downloadMembershipLabel(
              dependencies.downloadRepository.value.allowance.plan,
            ),
          ),
        ),
      );
      _showMessage(context, 'تعذر بدء التنزيل الآن. حاول مرة أخرى.');
    }
    return null;
  }
}

Future<void> retryChapterDownloadWithFeedback({
  required BuildContext context,
  required String jobId,
}) async {
  try {
    await AppDependencies.of(context).downloadRepository.retryJob(jobId);
  } on DownloadUnavailableException {
    if (context.mounted) {
      _showMessage(context, 'تعذر إعادة محاولة التنزيل الآن.');
    }
  }
}

void _showMessage(
  BuildContext context,
  String message, {
  VoidCallback? onOpenOperations,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: onOpenOperations == null
            ? null
            : SnackBarAction(
                label: 'عرض العمليات',
                onPressed: onOpenOperations,
              ),
      ),
    );
}
