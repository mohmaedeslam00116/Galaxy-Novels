import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/downloads/data/sqflite_download_store.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late SqfliteDownloadStore store;

  setUp(() async {
    store = await SqfliteDownloadStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => store.close());

  test('releasing a reservation does not charge a chapter', () async {
    final enqueued = await store.enqueue(
      novel: _novel,
      chapters: const [_chapter71],
    );
    final reservation = await store.reserveNext(
      plan: DownloadPlan.forTier(DownloadMembershipTier.regular),
      now: _dayOne,
    );

    expect(reservation?.groupId, enqueued.groupId);
    expect((await store.snapshot()).reservedCount, 1);

    await store.release(reservation!.jobId, reason: DownloadFailure.network);

    final snapshot = await store.snapshot();
    expect(snapshot.completedToday, 0);
    expect(snapshot.reservedCount, 0);
    expect(snapshot.groups.single.jobs.single.status, DownloadJobStatus.failed);
  });

  test('only two reservations can be active at once', () async {
    await store.enqueue(
      novel: _novel,
      chapters: const [_chapter71, _chapter72, _chapter73],
    );
    final plan = DownloadPlan.forTier(DownloadMembershipTier.vipMax);

    final first = await store.reserveNext(plan: plan, now: _dayOne);
    final second = await store.reserveNext(plan: plan, now: _dayOne);
    final third = await store.reserveNext(plan: plan, now: _dayOne);

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(third, isNull);
  });

  test('the next reservation is refused when the plan is exhausted', () async {
    const plan = DownloadPlan(
      baseChapters: 2,
      maxRewardedAds: 1,
      rewardPerAd: 1,
    );
    await store.enqueue(
      novel: _novel,
      chapters: const [_chapter71, _chapter72, _chapter73],
    );

    final first = await store.reserveNext(plan: plan, now: _dayOne);
    await _complete(store, first!);
    final second = await store.reserveNext(plan: plan, now: _dayOne);
    await _complete(store, second!);

    expect(await store.reserveNext(plan: plan, now: _dayOne), isNull);
    expect((await store.snapshot()).completedToday, 2);
  });

  test('duplicate and already downloaded chapter keys are skipped', () async {
    final first = await store.enqueue(
      novel: _novel,
      chapters: const [_chapter71, _chapter71],
    );

    expect(first.acceptedChapterKeys, ['public:71']);
    expect(first.skippedChapterKeys, ['public:71']);

    final duplicate = await store.enqueue(
      novel: _novel,
      chapters: const [_chapter71],
    );
    expect(duplicate.groupId, isNull);
    expect(duplicate.acceptedChapterKeys, isEmpty);
    expect(duplicate.skippedChapterKeys, ['public:71']);

    final reservation = await store.reserveNext(
      plan: DownloadPlan.forTier(DownloadMembershipTier.regular),
      now: _dayOne,
    );
    await _complete(store, reservation!);

    final downloadedDuplicate = await store.enqueue(
      novel: _novel,
      chapters: const [_chapter71],
    );
    expect(downloadedDuplicate.groupId, isNull);
    expect(downloadedDuplicate.skippedChapterKeys, ['public:71']);
  });

  test(
    'completion is charged to the reservation day across midnight',
    () async {
      const onePerDay = DownloadPlan(
        baseChapters: 1,
        maxRewardedAds: 0,
        rewardPerAd: 0,
      );
      await store.enqueue(
        novel: _novel,
        chapters: const [_chapter71, _chapter72],
      );
      final oldReservation = await store.reserveNext(
        plan: onePerDay,
        now: _dayOne,
      );

      await _complete(store, oldReservation!, completedAt: _dayTwo);

      final newDayReservation = await store.reserveNext(
        plan: onePerDay,
        now: _dayTwo,
      );
      expect(newDayReservation, isNotNull);
      expect((await store.snapshot()).completedToday, 0);
    },
  );

  test(
    'reward events are atomic, idempotent, and require zero balance',
    () async {
      const plan = DownloadPlan(
        baseChapters: 1,
        maxRewardedAds: 1,
        rewardPerAd: 2,
      );
      await store.enqueue(novel: _novel, chapters: const [_chapter71]);

      final beforeExhaustion = await store.grantReward(
        rewardEventId: 'reward-too-early',
        plan: plan,
        now: _dayOne,
      );
      expect(beforeExhaustion.rewardedCredits, 0);

      final reservation = await store.reserveNext(plan: plan, now: _dayOne);
      await _complete(store, reservation!);

      final rewarded = await store.grantReward(
        rewardEventId: 'reward-1',
        plan: plan,
        now: _dayOne,
      );
      final duplicate = await store.grantReward(
        rewardEventId: 'reward-1',
        plan: plan,
        now: _dayOne,
      );

      expect(rewarded.rewardedCredits, 2);
      expect(rewarded.completedAds, 1);
      expect(duplicate.rewardedCredits, 2);
      expect(duplicate.completedAds, 1);
    },
  );

  test(
    'deleting a chapter does not restore quota and allows redownload',
    () async {
      const plan = DownloadPlan(
        baseChapters: 1,
        maxRewardedAds: 0,
        rewardPerAd: 0,
      );
      await store.enqueue(novel: _novel, chapters: const [_chapter71]);
      final reservation = await store.reserveNext(plan: plan, now: _dayOne);
      await _complete(store, reservation!);

      await store.deleteChapters(const {'public:71'});
      final snapshot = await store.snapshot();
      expect(snapshot.completedToday, 1);
      expect(snapshot.novels, isEmpty);

      final redownload = await store.enqueue(
        novel: _novel,
        chapters: const [_chapter71],
      );
      expect(redownload.acceptedChapterKeys, ['public:71']);
      expect(await store.reserveNext(plan: plan, now: _dayOne), isNull);
    },
  );

  test(
    'a consumed reward event cannot be reused at the next zero balance',
    () async {
      const plan = DownloadPlan(
        baseChapters: 1,
        maxRewardedAds: 2,
        rewardPerAd: 1,
      );
      await store.enqueue(
        novel: _novel,
        chapters: const [_chapter71, _chapter72],
      );

      final baseReservation = await store.reserveNext(plan: plan, now: _dayOne);
      await _complete(store, baseReservation!);
      await store.grantReward(
        rewardEventId: 'single-use-event',
        plan: plan,
        now: _dayOne,
      );
      final rewardReservation = await store.reserveNext(
        plan: plan,
        now: _dayOne,
      );
      await _complete(store, rewardReservation!);

      final reused = await store.grantReward(
        rewardEventId: 'single-use-event',
        plan: plan,
        now: _dayOne,
      );

      expect(reused.rewardedCredits, 1);
      expect(reused.completedAds, 1);
    },
  );

  test('membership and cover path survive reopening the database', () async {
    await store.close();
    final directory = await Directory.systemTemp.createTemp(
      'galaxy_downloads_',
    );
    final path = '${directory.path}${Platform.pathSeparator}downloads.db';

    try {
      store = await SqfliteDownloadStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      const membership = DownloadMembershipSnapshot(
        userId: 42,
        active: true,
        tier: DownloadMembershipTier.vip2,
        verifiedAtUtcMs: 1000,
        expiresAtUtcMs: 2000,
      );
      await store.saveMembership(membership);
      await store.enqueue(novel: _novel, chapters: const [_chapter71]);
      await store.updateCoverPath(7, '/covers/7.webp');
      await store.close();

      store = await SqfliteDownloadStore.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final snapshot = await store.snapshot();

      expect(snapshot.membership.userId, 42);
      expect(snapshot.membership.tier, DownloadMembershipTier.vip2);
      expect(snapshot.membership.expiresAtUtcMs, 2000);
      expect(snapshot.novels.single.coverPath, '/covers/7.webp');
    } finally {
      await store.close();
      store = await SqfliteDownloadStore.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      await directory.delete(recursive: true);
    }
  });
}

final _dayOne = DateTime(2026, 7, 20, 9);
final _dayTwo = DateTime(2026, 7, 21, 0, 1);

const _novel = DownloadNovelRequest(
  novelId: 7,
  title: 'رواية الاختبار',
  coverUrl: 'https://example.com/cover.jpg',
);

const _chapter71 = DownloadChapterRequest(
  chapterKey: 'public:71',
  chapterId: 71,
  label: 'الفصل 71',
  contentApi: '/wp-json/wor-reader-app/v1/chapters/71',
  isVip: false,
);

const _chapter72 = DownloadChapterRequest(
  chapterKey: 'public:72',
  chapterId: 72,
  label: 'الفصل 72',
  contentApi: '/wp-json/wor-reader-app/v1/chapters/72',
  isVip: false,
);

const _chapter73 = DownloadChapterRequest(
  chapterKey: 'public:73',
  chapterId: 73,
  label: 'الفصل 73',
  contentApi: '/wp-json/wor-reader-app/v1/chapters/73',
  isVip: false,
);

Future<void> _complete(
  SqfliteDownloadStore store,
  DownloadReservation reservation, {
  DateTime? completedAt,
}) {
  return store.complete(
    reservation.jobId,
    filePath: '/downloads/${reservation.chapterKey}.json',
    byteSize: 128,
    downloadedAtUtcMs: (completedAt ?? _dayOne).toUtc().millisecondsSinceEpoch,
  );
}
