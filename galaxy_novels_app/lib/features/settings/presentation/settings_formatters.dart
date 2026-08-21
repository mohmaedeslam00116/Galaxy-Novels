String formatStorageSize(int bytes) {
  if (bytes < 1024) return '$bytes بايت';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} ك.ب';
  final megabytes = kilobytes / 1024;
  if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} م.ب';
  return '${(megabytes / 1024).toStringAsFixed(1)} ج.ب';
}
