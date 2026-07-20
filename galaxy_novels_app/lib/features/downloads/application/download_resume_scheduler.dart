abstract interface class DownloadResumeScheduler {
  Future<void> scheduleNextMidnight(DateTime now);
}
