enum PlayAppUpdateResult { accepted, denied, failed }

enum PlayAppUpdateInstallStatus {
  idle,
  pending,
  downloading,
  downloaded,
  installing,
  installed,
  failed,
  canceled,
}

class PlayAppUpdateAvailability {
  const PlayAppUpdateAvailability({
    required this.availableVersionCode,
    required this.updateAvailable,
    required this.flexibleAllowed,
    required this.immediateAllowed,
    this.installStatus = PlayAppUpdateInstallStatus.idle,
  });

  static const none = PlayAppUpdateAvailability(
    availableVersionCode: null,
    updateAvailable: false,
    flexibleAllowed: false,
    immediateAllowed: false,
  );

  final int? availableVersionCode;
  final bool updateAvailable;
  final bool flexibleAllowed;
  final bool immediateAllowed;
  final PlayAppUpdateInstallStatus installStatus;
}

abstract interface class PlayAppUpdateGateway {
  Stream<PlayAppUpdateInstallStatus> get installStatuses;

  Future<PlayAppUpdateAvailability> checkForUpdate();

  Future<PlayAppUpdateResult> startFlexibleUpdate();

  Future<void> completeFlexibleUpdate();

  Future<PlayAppUpdateResult> startImmediateUpdate();

  Future<bool> openStore();
}
