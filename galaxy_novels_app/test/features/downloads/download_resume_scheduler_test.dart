import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/data/workmanager_download_resume_scheduler.dart';
import 'package:workmanager/workmanager.dart';

void main() {
  test('schedules a unique replacement wake-up for 00:01', () async {
    final client = _FakeDownloadWorkmanagerClient();
    final scheduler = WorkmanagerDownloadResumeScheduler(client: client);

    await scheduler.scheduleNextMidnight(DateTime(2026, 7, 20, 23, 50));

    expect(client.uniqueName, 'galaxy-download-midnight-resume');
    expect(client.taskName, downloadMidnightTask);
    expect(client.initialDelay, const Duration(minutes: 11));
    expect(client.existingWorkPolicy, ExistingWorkPolicy.replace);
  });
}

class _FakeDownloadWorkmanagerClient implements DownloadWorkmanagerClient {
  String? uniqueName;
  String? taskName;
  Duration? initialDelay;
  ExistingWorkPolicy? existingWorkPolicy;

  @override
  Future<void> registerOneOffTask(
    String uniqueName,
    String taskName, {
    required Duration initialDelay,
    required ExistingWorkPolicy existingWorkPolicy,
  }) async {
    this.uniqueName = uniqueName;
    this.taskName = taskName;
    this.initialDelay = initialDelay;
    this.existingWorkPolicy = existingWorkPolicy;
  }
}
