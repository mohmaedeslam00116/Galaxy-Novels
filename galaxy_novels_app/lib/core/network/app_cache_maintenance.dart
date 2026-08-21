abstract interface class AppCacheMaintenance {
  Future<int> cacheSizeBytes();

  Future<void> clearTemporaryCache();
}

class NoopAppCacheMaintenance implements AppCacheMaintenance {
  const NoopAppCacheMaintenance();

  @override
  Future<int> cacheSizeBytes() async => 0;

  @override
  Future<void> clearTemporaryCache() async {}
}
