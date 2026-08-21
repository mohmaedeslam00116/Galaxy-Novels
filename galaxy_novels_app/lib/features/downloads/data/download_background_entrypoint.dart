import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/config/app_config.dart';
import '../../account/data/secure_auth_session_store.dart';
import 'background_download_transfer.dart';
import 'downloaded_chapter_file_store.dart';
import 'secure_download_key_store.dart';
import 'sqflite_download_store.dart';
import 'stored_download_repository.dart';
import 'workmanager_download_resume_scheduler.dart';

@pragma('vm:entry-point')
void downloadBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != downloadMidnightTask) return false;
    return resumeStoredDownloadQueue();
  });
}

@visibleForTesting
Future<bool> resumeStoredDownloadQueue() async {
  SqfliteDownloadStore? store;
  StoredDownloadRepository? repository;
  try {
    final supportDirectory = await getApplicationSupportDirectory();
    store = await SqfliteDownloadStore.open(singleInstance: false);
    repository = StoredDownloadRepository(
      store: store,
      transfer: BackgroundDownloadTransfer(),
      fileStore: DownloadedChapterFileStore(
        rootDirectory: Directory(
          path.join(supportDirectory.path, 'downloads', 'chapters'),
        ),
        keyStore: SecureDownloadKeyStore(),
      ),
      scheduler: WorkmanagerDownloadResumeScheduler(),
      config: const AppConfig(),
      sessionStore: SecureAuthSessionStore(),
    );
    await repository.initialize();
    return true;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  } on FileSystemException {
    return false;
  } on DatabaseException {
    return false;
  } finally {
    await shutdownDownloadWorkerResources(
      shutdownRepository: repository?.shutdown,
      disposeRepository: repository?.dispose,
      closeStore: store?.close,
    );
  }
}

@visibleForTesting
Future<void> shutdownDownloadWorkerResources({
  Future<void> Function()? shutdownRepository,
  void Function()? disposeRepository,
  Future<void> Function()? closeStore,
}) async {
  try {
    await shutdownRepository?.call();
  } finally {
    try {
      disposeRepository?.call();
    } finally {
      await closeStore?.call();
    }
  }
}
