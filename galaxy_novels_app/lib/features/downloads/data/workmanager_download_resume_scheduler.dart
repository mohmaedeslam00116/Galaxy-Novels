import 'package:workmanager/workmanager.dart';

import '../application/download_resume_scheduler.dart';

const downloadMidnightTask = 'galaxy_download_midnight_resume';

class WorkmanagerDownloadResumeScheduler implements DownloadResumeScheduler {
  WorkmanagerDownloadResumeScheduler({DownloadWorkmanagerClient? client})
    : _client = client ?? WorkmanagerClient();

  final DownloadWorkmanagerClient _client;

  @override
  Future<void> scheduleNextMidnight(DateTime now) {
    final next = DateTime(now.year, now.month, now.day + 1, 0, 1);
    return _client.registerOneOffTask(
      'galaxy-download-midnight-resume',
      downloadMidnightTask,
      initialDelay: next.difference(now),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}

abstract interface class DownloadWorkmanagerClient {
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    required Duration initialDelay,
    required ExistingWorkPolicy existingWorkPolicy,
  });
}

class WorkmanagerClient implements DownloadWorkmanagerClient {
  WorkmanagerClient({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    required Duration initialDelay,
    required ExistingWorkPolicy existingWorkPolicy,
  }) {
    return _workmanager.registerOneOffTask(
      uniqueName,
      taskName,
      initialDelay: initialDelay,
      existingWorkPolicy: existingWorkPolicy,
    );
  }
}
