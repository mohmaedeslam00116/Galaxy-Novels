import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/reader_content_data.dart';
import '../../account/domain/auth_session.dart';
import '../../account/application/auth_session_store.dart';
import '../application/download_repository.dart';
import '../application/download_resume_scheduler.dart';
import '../application/download_store.dart';
import '../application/download_transfer.dart';
import '../domain/download_entitlement.dart';
import '../domain/download_models.dart';
import 'downloaded_chapter_file_store.dart';

class StoredDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  StoredDownloadRepository({
    required DownloadStore store,
    required DownloadTransfer transfer,
    required DownloadedChapterFileStore fileStore,
    required DownloadResumeScheduler scheduler,
    required AppConfig config,
    AuthSessionStore? sessionStore,
    DateTime Function()? clock,
  }) : _store = store,
       _transfer = transfer,
       _fileStore = fileStore,
       _scheduler = scheduler,
       _config = config,
       _sessionStore = sessionStore,
       _clock = clock ?? DateTime.now;

  final DownloadStore _store;
  final DownloadTransfer _transfer;
  final DownloadedChapterFileStore _fileStore;
  final DownloadResumeScheduler _scheduler;
  final AppConfig _config;
  final AuthSessionStore? _sessionStore;
  final DateTime Function() _clock;
  final Map<String, DownloadReservation> _reservations = {};
  final Set<Future<void>> _transferOperations = {};
  StreamSubscription<DownloadTransferUpdate>? _transferSubscription;
  Future<void>? _shutdown;
  DownloadMembershipTier _tier = DownloadMembershipTier.regular;
  int _quotaBlockGeneration = 0;
  bool _disposed = false;

  DownloadsDashboard _dashboard = NoopDownloadRepository.emptyDashboard;

  @override
  DownloadsDashboard get value => _dashboard;

  @override
  Future<void> initialize() async {
    _transferSubscription = _transfer.updates.listen(_queueTransferUpdate);
    await _transfer.initialize();
    final snapshot = await _store.snapshot();
    _tier = snapshot.membership.tier;
    _restoreReservations(snapshot);
    await _publish();
    await _startQueuedTransfers();
  }

  void _restoreReservations(DownloadStoreSnapshot snapshot) {
    _reservations.clear();
    for (final group in snapshot.groups) {
      for (final job in group.jobs) {
        final reservedDay = job.reservedDayOrdinal;
        if (reservedDay == null || !_hasActiveTransfer(job.status)) continue;
        _reservations[job.jobId] = DownloadReservation(
          jobId: job.jobId,
          groupId: group.groupId,
          novelId: group.novelId,
          chapterKey: job.chapterKey,
          chapterId: job.chapterId,
          label: job.label,
          contentApi: job.contentApi,
          isVip: job.isVip,
          reservedDayOrdinal: reservedDay,
        );
      }
    }
  }

  void _queueTransferUpdate(DownloadTransferUpdate update) {
    if (_disposed) return;
    final operation = _applyTransferUpdate(update);
    _transferOperations.add(operation);
    unawaited(
      operation.whenComplete(() => _transferOperations.remove(operation)),
    );
  }

  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) async {
    final accepted = await _store.enqueue(novel: novel, chapters: chapters);
    final transferAvailable = await _startQueuedTransfers();
    if (!transferAvailable && accepted.acceptedChapterKeys.isNotEmpty) {
      throw const DownloadUnavailableException();
    }
    return accepted;
  }

  Future<bool> _startQueuedTransfers() async {
    var transferAvailable = true;
    final plan = DownloadPlan.forTier(_tier);
    while (true) {
      final reservation = await _store.reserveNext(plan: plan, now: _clock());
      if (reservation == null) break;
      final request = await _requestForReservation(reservation);
      if (request == null) continue;
      _reservations[reservation.jobId] = reservation;
      try {
        if (await _transfer.enqueue(request)) continue;
      } on DownloadTransferUnavailableException {
        transferAvailable = false;
      }
      if (_reservations.remove(reservation.jobId) != null) {
        await _store.release(
          reservation.jobId,
          reason: DownloadFailure.network,
        );
      }
      transferAvailable = false;
      break;
    }
    await _publish();
    if (_dashboard.allowance.remaining == 0 &&
        _dashboard.groups.any(
          (group) =>
              group.jobs.any((job) => job.status == DownloadJobStatus.queued),
        )) {
      _quotaBlockGeneration++;
      await _scheduler.scheduleNextMidnight(_clock());
      await _publish();
    }
    return transferAvailable;
  }

  Future<DownloadTransferRequest?> _requestForReservation(
    DownloadReservation reservation,
  ) async {
    try {
      final request = await _transferRequest(reservation, _dashboard.wifiOnly);
      if (request != null) return request;
      await _store.release(
        reservation.jobId,
        reason: DownloadFailure.vipRequired,
      );
    } on FormatException {
      await _releaseInvalidReservation(reservation.jobId);
    } on ArgumentError {
      await _releaseInvalidReservation(reservation.jobId);
    } on AppConfigException {
      await _releaseInvalidReservation(reservation.jobId);
    } on AuthSessionStoreException {
      await _store.release(
        reservation.jobId,
        reason: DownloadFailure.unauthorized,
      );
    }
    return null;
  }

  Future<void> _releaseInvalidReservation(String jobId) {
    return _store.release(jobId, reason: DownloadFailure.invalidContent);
  }

  Future<DownloadTransferRequest?> _transferRequest(
    DownloadReservation reservation,
    bool wifiOnly,
  ) async {
    final uri = _safeContentUri(reservation.contentApi);
    final headers = <String, String>{
      'Accept': 'application/json',
      'User-Agent': _config.userAgent,
      'Cache-Control': 'no-store',
      'Pragma': 'no-cache',
    };
    if (reservation.isVip) {
      final session = await _sessionStore?.read();
      if (session == null ||
          (session.expiresAt != null &&
              !session.expiresAt!.isAfter(_clock().toUtc()))) {
        return null;
      }
      headers['Authorization'] = '${session.tokenType} ${session.accessToken}';
      headers['X-Wor-App-Token'] = session.accessToken;
    }
    return DownloadTransferRequest(
      transferId: reservation.jobId,
      kind: DownloadTransferKind.chapter,
      url: uri,
      headers: headers,
      fileName: '${reservation.jobId}.json',
      requiresWifi: wifiOnly,
    );
  }

  Uri _safeContentUri(String contentApi) {
    final uri = _config.resolve(contentApi);
    final origin = _config.resolve('/');
    if (uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host.toLowerCase() != origin.host.toLowerCase() ||
        uri.port != origin.port) {
      throw ArgumentError.value(contentApi, 'contentApi');
    }
    return uri;
  }

  Future<void> _applyTransferUpdate(DownloadTransferUpdate update) async {
    if (update is DownloadTransferFinished) {
      await _finishTransfer(update);
    } else if (update is DownloadTransferFailed) {
      final reservation = _reservations.remove(update.transferId);
      if (reservation != null) {
        await _store.release(reservation.jobId, reason: update.failure);
      }
    }
    await _startQueuedTransfers();
  }

  Future<void> _finishTransfer(DownloadTransferFinished update) async {
    final reservation = _reservations.remove(update.transferId);
    final temporaryFile = File(update.localPath);
    if (reservation == null) {
      await deleteDownloadTemporaryFile(temporaryFile);
      return;
    }
    try {
      final content = _decodeServerResponse(await temporaryFile.readAsString());
      if (reservation.chapterId > 0 && content.id != reservation.chapterId) {
        throw const FormatException('Downloaded chapter ID mismatch.');
      }
      final filePath = reservation.isVip
          ? await _fileStore.writeVip(reservation.chapterKey, content)
          : await _fileStore.writePublic(reservation.chapterKey, content);
      final membership = (await _store.snapshot()).membership;
      await _store.complete(
        reservation.jobId,
        filePath: filePath,
        byteSize: await File(filePath).length(),
        downloadedAtUtcMs: _clock().toUtc().millisecondsSinceEpoch,
        vipVerifiedAtUtcMs: reservation.isVip
            ? membership.verifiedAtUtcMs
            : null,
        vipExpiresAtUtcMs: reservation.isVip ? membership.expiresAtUtcMs : null,
      );
    } on FormatException {
      await _store.release(
        reservation.jobId,
        reason: DownloadFailure.invalidContent,
      );
    } on FileSystemException {
      await _store.release(
        reservation.jobId,
        reason: DownloadFailure.storageFull,
      );
    } finally {
      await deleteDownloadTemporaryFile(temporaryFile);
    }
  }

  ReaderChapterContent _decodeServerResponse(String responseBody) {
    final responseJson = jsonDecode(responseBody);
    if (responseJson is! Map<String, dynamic>) {
      throw const FormatException('Invalid downloaded chapter response.');
    }
    final chapter = ReaderChapterContent.fromJson(responseJson);
    if (chapter.id <= 0 || chapter.contentHtml.trim().isEmpty) {
      throw const FormatException('Downloaded chapter content is incomplete.');
    }
    return chapter;
  }

  @override
  Future<ReaderChapterContent> loadOffline(String offlineUri) async {
    final uri = Uri.parse(offlineUri);
    if (uri.scheme != 'galaxy-download' ||
        uri.host != 'chapter' ||
        uri.pathSegments.length != 1) {
      throw ArgumentError.value(offlineUri, 'offlineUri');
    }
    final chapterKey = uri.pathSegments.single;
    final snapshot = await _store.snapshot();
    DownloadedNovel? novel;
    DownloadedChapter? chapter;
    for (final storedNovel in snapshot.novels) {
      for (final storedChapter in storedNovel.chapters) {
        if (storedChapter.chapterKey == chapterKey) {
          novel = storedNovel;
          chapter = storedChapter;
          break;
        }
      }
      if (chapter != null) break;
    }
    if (novel == null || chapter == null) {
      throw const DownloadUnavailableException();
    }
    if (chapter.isVip && !snapshot.membership.active) {
      throw const DownloadVipLockedException(DownloadVipLockReason.signedOut);
    }
    if (chapter.isVip) {
      final nowUtcMs = _clock().toUtc().millisecondsSinceEpoch;
      final expiresAtUtcMs = snapshot.membership.expiresAtUtcMs;
      if (expiresAtUtcMs != null && nowUtcMs >= expiresAtUtcMs) {
        throw const DownloadVipLockedException(DownloadVipLockReason.expired);
      }
      const verificationWindow = Duration(days: 7);
      if (expiresAtUtcMs == null &&
          nowUtcMs - snapshot.membership.verifiedAtUtcMs >=
              verificationWindow.inMilliseconds) {
        throw const DownloadVipLockedException(
          DownloadVipLockReason.verificationRequired,
        );
      }
    }
    final content = chapter.isVip
        ? _fileStore.readVip(chapter.filePath)
        : _fileStore.readPublic(chapter.filePath);
    return _withOfflineNavigation(await content, novel.chapters, chapterKey);
  }

  ReaderChapterContent _withOfflineNavigation(
    ReaderChapterContent content,
    List<DownloadedChapter> chapters,
    String chapterKey,
  ) {
    final ordered = [...chapters]
      ..sort((a, b) => a.chapterId.compareTo(b.chapterId));
    final index = ordered.indexWhere(
      (chapter) => chapter.chapterKey == chapterKey,
    );
    final previous = index > 0 ? ordered[index - 1] : null;
    final next = index >= 0 && index < ordered.length - 1
        ? ordered[index + 1]
        : null;
    return ReaderChapterContent(
      id: content.id,
      novelId: content.novelId,
      label: content.label,
      title: content.title,
      displayTitle: content.displayTitle,
      position: content.position,
      total: content.total,
      contentHtml: content.contentHtml,
      navigation: ReaderChapterNavigation(
        previousApi: previous == null
            ? ''
            : offlineChapterUri(previous.chapterKey),
        nextApi: next == null ? '' : offlineChapterUri(next.chapterKey),
        previousId: previous?.chapterId ?? 0,
        nextId: next?.chapterId ?? 0,
      ),
    );
  }

  @override
  Future<void> refreshMembership(AuthSessionState state) async {
    if (state.status != AuthSessionStatus.authenticated &&
        state.status != AuthSessionStatus.guest) {
      return;
    }
    final user = state.user;
    final tier = DownloadMembershipTier.fromVip(user?.vip);
    _tier = tier;
    await _store.saveMembership(
      DownloadMembershipSnapshot(
        userId: user?.id,
        active: user?.vip.active ?? false,
        tier: tier,
        verifiedAtUtcMs: _clock().toUtc().millisecondsSinceEpoch,
        expiresAtUtcMs: user?.vip.expiresAt?.toUtc().millisecondsSinceEpoch,
      ),
    );
    await _startQueuedTransfers();
  }

  @override
  Future<void> grantReward({required String rewardEventId}) async {
    await _store.grantReward(
      rewardEventId: rewardEventId,
      plan: DownloadPlan.forTier(_tier),
      now: _clock(),
    );
    await _startQueuedTransfers();
  }

  @override
  Future<void> setWifiOnly(bool enabled) async {
    await _store.setWifiOnly(enabled);
    await _publish();
  }

  @override
  Future<void> deleteChapters(Set<String> chapterKeys) async {
    final snapshot = await _store.snapshot();
    for (final chapter in snapshot.novels.expand((novel) => novel.chapters)) {
      if (chapterKeys.contains(chapter.chapterKey)) {
        await _fileStore.delete(chapter.filePath);
      }
    }
    await _store.deleteChapters(chapterKeys);
    await _publish();
  }

  @override
  Future<void> pauseGroup(String groupId) async {
    final group = _findGroup(groupId);
    if (group == null) return;
    await _store.pauseGroup(groupId);
    try {
      for (final job in group.jobs) {
        if (_hasActiveTransfer(job.status)) {
          await _transfer.pause(job.jobId);
        }
      }
    } finally {
      await _publish();
    }
  }

  @override
  Future<void> resumeGroup(String groupId) async {
    final group = _findGroup(groupId);
    if (group == null) return;
    await _store.resumeGroup(groupId);
    try {
      for (final job in group.jobs) {
        if (_hasActiveTransfer(job.status)) {
          await _transfer.resume(job.jobId);
        }
      }
    } finally {
      await _startQueuedTransfers();
    }
  }

  @override
  Future<void> cancelGroup(String groupId) async {
    final group = _findGroup(groupId);
    if (group == null) return;
    for (final job in group.jobs) {
      _reservations.remove(job.jobId);
      if (_hasActiveTransfer(job.status)) {
        try {
          await _transfer.cancel(job.jobId);
        } catch (_) {
          // The local cancellation remains authoritative. Late native files
          // are discarded when their completion update arrives.
        }
      }
    }
    await _store.cancelGroup(groupId);
    await _startQueuedTransfers();
  }

  DownloadGroup? _findGroup(String groupId) {
    for (final group in value.groups) {
      if (group.groupId == groupId) return group;
    }
    return null;
  }

  @override
  Future<void> retryJob(String jobId) async {
    await _store.retryJob(jobId);
    await _startQueuedTransfers();
  }

  Future<void> _publish() async {
    final snapshot = await _store.snapshot();
    final allowance = const DownloadEntitlementPolicy().evaluate(
      now: _clock(),
      highestLocalDayOrdinal: snapshot.highestSeenDayOrdinal,
      completed: snapshot.completedToday,
      reserved: snapshot.reservedCount,
      rewardedCredits: snapshot.rewardedCredits,
      completedAds: snapshot.completedAds,
      tier: _tier,
    );
    _dashboard = DownloadsDashboard(
      allowance: allowance,
      groups: snapshot.groups,
      novels: snapshot.novels,
      wifiOnly: snapshot.wifiOnly,
      totalBytes: snapshot.totalBytes,
      quotaBlockGeneration: _quotaBlockGeneration,
      isInitializing: false,
    );
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    unawaited(shutdown());
    super.dispose();
  }

  Future<void> shutdown() {
    return _shutdown ??= _shutdownResources();
  }

  Future<void> _shutdownResources() async {
    _disposed = true;
    await _transferSubscription?.cancel();
    await Future.wait(_transferOperations.toList(growable: false));
    _transfer.dispose();
  }
}

bool _hasActiveTransfer(DownloadJobStatus status) {
  return status == DownloadJobStatus.reserved ||
      status == DownloadJobStatus.transferring ||
      status == DownloadJobStatus.processing ||
      status == DownloadJobStatus.paused;
}
