import 'package:in_app_update/in_app_update.dart' as play;

import '../../../core/navigation/external_uri_launcher.dart';
import '../application/play_app_update_gateway.dart';

typedef AppStoreUriLauncher = Future<bool> Function(Uri uri);

class PlayStoreAppUpdateGateway implements PlayAppUpdateGateway {
  PlayStoreAppUpdateGateway({
    this.packageName = 'com.galaxynovels.app',
    AppStoreUriLauncher uriLauncher = launchExternalUri,
  }) : _uriLauncher = uriLauncher;

  final String packageName;
  final AppStoreUriLauncher _uriLauncher;

  @override
  Stream<PlayAppUpdateInstallStatus> get installStatuses =>
      play.InAppUpdate.installUpdateListener.map(_mapInstallStatus);

  @override
  Future<PlayAppUpdateAvailability> checkForUpdate() async {
    final info = await play.InAppUpdate.checkForUpdate();
    final updateAvailable =
        info.updateAvailability == play.UpdateAvailability.updateAvailable ||
        info.updateAvailability ==
            play.UpdateAvailability.developerTriggeredUpdateInProgress;
    return PlayAppUpdateAvailability(
      availableVersionCode: updateAvailable ? info.availableVersionCode : null,
      updateAvailable: updateAvailable,
      flexibleAllowed: updateAvailable && info.flexibleUpdateAllowed,
      immediateAllowed: updateAvailable && info.immediateUpdateAllowed,
      installStatus: _mapInstallStatus(info.installStatus),
    );
  }

  @override
  Future<PlayAppUpdateResult> startFlexibleUpdate() async {
    return _mapResult(await play.InAppUpdate.startFlexibleUpdate());
  }

  @override
  Future<void> completeFlexibleUpdate() {
    return play.InAppUpdate.completeFlexibleUpdate();
  }

  @override
  Future<PlayAppUpdateResult> startImmediateUpdate() async {
    return _mapResult(await play.InAppUpdate.performImmediateUpdate());
  }

  @override
  Future<bool> openStore() async {
    var marketOpened = false;
    try {
      marketOpened = await _uriLauncher(
        Uri.parse('market://details?id=$packageName'),
      );
    } on Exception {
      marketOpened = false;
    }
    if (marketOpened) return true;
    try {
      return await _uriLauncher(
        Uri.https('play.google.com', '/store/apps/details', {
          'id': packageName,
        }),
      );
    } on Exception {
      return false;
    }
  }

  static PlayAppUpdateResult _mapResult(play.AppUpdateResult result) {
    return switch (result) {
      play.AppUpdateResult.success => PlayAppUpdateResult.accepted,
      play.AppUpdateResult.userDeniedUpdate => PlayAppUpdateResult.denied,
      play.AppUpdateResult.inAppUpdateFailed => PlayAppUpdateResult.failed,
    };
  }

  static PlayAppUpdateInstallStatus _mapInstallStatus(
    play.InstallStatus status,
  ) {
    return switch (status) {
      play.InstallStatus.pending => PlayAppUpdateInstallStatus.pending,
      play.InstallStatus.downloading => PlayAppUpdateInstallStatus.downloading,
      play.InstallStatus.downloaded => PlayAppUpdateInstallStatus.downloaded,
      play.InstallStatus.installing => PlayAppUpdateInstallStatus.installing,
      play.InstallStatus.installed => PlayAppUpdateInstallStatus.installed,
      play.InstallStatus.failed => PlayAppUpdateInstallStatus.failed,
      play.InstallStatus.canceled => PlayAppUpdateInstallStatus.canceled,
      play.InstallStatus.unknown => PlayAppUpdateInstallStatus.idle,
    };
  }
}

class NoopPlayAppUpdateGateway implements PlayAppUpdateGateway {
  const NoopPlayAppUpdateGateway();

  @override
  Stream<PlayAppUpdateInstallStatus> get installStatuses =>
      const Stream.empty();

  @override
  Future<PlayAppUpdateAvailability> checkForUpdate() async =>
      PlayAppUpdateAvailability.none;

  @override
  Future<void> completeFlexibleUpdate() async {}

  @override
  Future<bool> openStore() async => false;

  @override
  Future<PlayAppUpdateResult> startFlexibleUpdate() async =>
      PlayAppUpdateResult.failed;

  @override
  Future<PlayAppUpdateResult> startImmediateUpdate() async =>
      PlayAppUpdateResult.failed;
}
