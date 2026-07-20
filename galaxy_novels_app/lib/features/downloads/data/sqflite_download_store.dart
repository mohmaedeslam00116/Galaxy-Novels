import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../application/download_store.dart';
import '../domain/download_entitlement.dart';
import '../domain/download_models.dart';

class SqfliteDownloadStore implements DownloadStore {
  SqfliteDownloadStore._(this._database);

  static int _idSequence = 0;

  final Database _database;

  static Future<SqfliteDownloadStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final effectiveFactory = factory ?? databaseFactory;
    final effectivePath = path ?? '${await getDatabasesPath()}/downloads.db';
    final database = await effectiveFactory.openDatabase(
      effectivePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.transaction((transaction) async {
            await _createSchema(transaction);
            await transaction.insert('download_settings', {
              'id': 1,
              'wifi_only': 0,
            });
            await transaction.insert('download_membership', {
              'id': 1,
              'active': 0,
              'tier': DownloadMembershipTier.regular.name,
              'verified_at': 0,
            });
          });
        },
      ),
    );
    return SqfliteDownloadStore._(database);
  }

  static Future<void> _createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE download_days(
        day_ordinal INTEGER PRIMARY KEY,
        highest_seen_day INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        rewarded_credits INTEGER NOT NULL DEFAULT 0,
        completed_ads INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE download_reward_events(
        event_id TEXT PRIMARY KEY,
        day_ordinal INTEGER NOT NULL,
        credits INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE download_novels(
        novel_id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        cover_url TEXT NOT NULL,
        cover_path TEXT NOT NULL DEFAULT '',
        total_bytes INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE download_groups(
        group_id TEXT PRIMARY KEY,
        novel_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        stop_reason TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE download_jobs(
        job_id TEXT PRIMARY KEY,
        group_id TEXT NOT NULL,
        chapter_key TEXT NOT NULL UNIQUE,
        chapter_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        content_api TEXT NOT NULL,
        is_vip INTEGER NOT NULL,
        status TEXT NOT NULL,
        sort_index INTEGER NOT NULL,
        reserved_day INTEGER,
        transfer_task_id TEXT,
        temp_path TEXT,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE downloaded_chapters(
        chapter_key TEXT PRIMARY KEY,
        novel_id INTEGER NOT NULL,
        chapter_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        content_api TEXT NOT NULL,
        is_vip INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        byte_size INTEGER NOT NULL,
        downloaded_at INTEGER NOT NULL,
        vip_verified_at INTEGER,
        vip_expires_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE download_membership(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        user_id INTEGER,
        active INTEGER NOT NULL DEFAULT 0,
        tier TEXT NOT NULL DEFAULT 'regular',
        verified_at INTEGER NOT NULL DEFAULT 0,
        expires_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE download_settings(
        id INTEGER PRIMARY KEY CHECK(id = 1),
        wifi_only INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  @override
  Future<DownloadEnqueueResult> enqueue({
    required DownloadNovelRequest novel,
    required List<DownloadChapterRequest> chapters,
  }) {
    return _database.transaction((transaction) async {
      await transaction.rawInsert(
        '''
        INSERT INTO download_novels(novel_id, title, cover_url)
        VALUES(?, ?, ?)
        ON CONFLICT(novel_id) DO UPDATE SET
          title = excluded.title,
          cover_url = excluded.cover_url
        ''',
        [novel.novelId, novel.title, novel.coverUrl],
      );

      final accepted = <DownloadChapterRequest>[];
      final skipped = <String>[];
      final seen = <String>{};
      for (final chapter in chapters) {
        if (!seen.add(chapter.chapterKey) ||
            await _chapterKeyExists(transaction, chapter.chapterKey)) {
          skipped.add(chapter.chapterKey);
          continue;
        }
        accepted.add(chapter);
      }

      if (accepted.isEmpty) {
        if (!await _novelHasWork(transaction, novel.novelId)) {
          await transaction.delete(
            'download_novels',
            where: 'novel_id = ?',
            whereArgs: [novel.novelId],
          );
        }
        return DownloadEnqueueResult(
          groupId: null,
          acceptedChapterKeys: const [],
          skippedChapterKeys: List.unmodifiable(skipped),
        );
      }

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final groupId = _newId('group');
      await transaction.insert('download_groups', {
        'group_id': groupId,
        'novel_id': novel.novelId,
        'status': DownloadGroupStatus.queued.name,
        'created_at': now,
        'updated_at': now,
      });
      for (var index = 0; index < accepted.length; index++) {
        final chapter = accepted[index];
        await transaction.insert('download_jobs', {
          'job_id': _newId('job'),
          'group_id': groupId,
          'chapter_key': chapter.chapterKey,
          'chapter_id': chapter.chapterId,
          'label': chapter.label,
          'content_api': chapter.contentApi,
          'is_vip': chapter.isVip ? 1 : 0,
          'status': DownloadJobStatus.queued.name,
          'sort_index': index,
        });
      }

      return DownloadEnqueueResult(
        groupId: groupId,
        acceptedChapterKeys: List.unmodifiable(
          accepted.map((chapter) => chapter.chapterKey),
        ),
        skippedChapterKeys: List.unmodifiable(skipped),
      );
    });
  }

  @override
  Future<DownloadReservation?> reserveNext({
    required DownloadPlan plan,
    required DateTime now,
  }) {
    return _database.transaction((transaction) async {
      final dayOrdinal = await _ensureDay(transaction, now);
      final activeReservations =
          Sqflite.firstIntValue(
            await transaction.rawQuery(
              '''
              SELECT COUNT(*) FROM download_jobs
              WHERE status IN (?, ?, ?)
              ''',
              [
                DownloadJobStatus.reserved.name,
                DownloadJobStatus.transferring.name,
                DownloadJobStatus.processing.name,
              ],
            ),
          ) ??
          0;
      if (activeReservations >= 2) return null;

      final day = await _dayRow(transaction, dayOrdinal);
      final reservedToday =
          Sqflite.firstIntValue(
            await transaction.rawQuery(
              '''
              SELECT COUNT(*) FROM download_jobs
              WHERE reserved_day = ? AND status IN (?, ?, ?)
              ''',
              [
                dayOrdinal,
                DownloadJobStatus.reserved.name,
                DownloadJobStatus.transferring.name,
                DownloadJobStatus.processing.name,
              ],
            ),
          ) ??
          0;
      final rawRemaining = math.max(
        0,
        plan.baseChapters +
            _int(day['rewarded_credits']) -
            _int(day['completed']) -
            reservedToday,
      );
      if (rawRemaining == 0) return null;

      final rows = await transaction.rawQuery(
        '''
        SELECT j.*, g.novel_id
        FROM download_jobs j
        JOIN download_groups g ON g.group_id = j.group_id
        WHERE j.status = ?
        ORDER BY g.created_at, j.sort_index
        LIMIT 1
      ''',
        [DownloadJobStatus.queued.name],
      );
      if (rows.isEmpty) return null;

      final row = rows.single;
      final jobId = row['job_id']! as String;
      final groupId = row['group_id']! as String;
      final updatedAt = now.toUtc().millisecondsSinceEpoch;
      await transaction.update(
        'download_jobs',
        {
          'status': DownloadJobStatus.reserved.name,
          'reserved_day': dayOrdinal,
          'last_error': null,
        },
        where: 'job_id = ?',
        whereArgs: [jobId],
      );
      await transaction.update(
        'download_groups',
        {
          'status': DownloadGroupStatus.running.name,
          'stop_reason': null,
          'updated_at': updatedAt,
        },
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      return DownloadReservation(
        jobId: jobId,
        groupId: groupId,
        novelId: _int(row['novel_id']),
        chapterKey: row['chapter_key']! as String,
        chapterId: _int(row['chapter_id']),
        label: row['label']! as String,
        contentApi: row['content_api']! as String,
        isVip: _int(row['is_vip']) == 1,
        reservedDayOrdinal: dayOrdinal,
      );
    });
  }

  @override
  Future<void> complete(
    String jobId, {
    required String filePath,
    required int byteSize,
    required int downloadedAtUtcMs,
    int? vipVerifiedAtUtcMs,
    int? vipExpiresAtUtcMs,
  }) {
    return _database.transaction((transaction) async {
      final rows = await transaction.rawQuery(
        '''
        SELECT j.*, g.novel_id
        FROM download_jobs j
        JOIN download_groups g ON g.group_id = j.group_id
        WHERE j.job_id = ?
      ''',
        [jobId],
      );
      if (rows.isEmpty) return;
      final row = rows.single;
      if (row['status'] == DownloadJobStatus.completed.name) return;
      final reservedDay = row['reserved_day'] as int?;
      if (reservedDay == null) {
        throw StateError('Cannot complete a job without a reservation day.');
      }

      final novelId = _int(row['novel_id']);
      await transaction.insert('downloaded_chapters', {
        'chapter_key': row['chapter_key'],
        'novel_id': novelId,
        'chapter_id': row['chapter_id'],
        'label': row['label'],
        'content_api': row['content_api'],
        'is_vip': row['is_vip'],
        'file_path': filePath,
        'byte_size': byteSize,
        'downloaded_at': downloadedAtUtcMs,
        'vip_verified_at': vipVerifiedAtUtcMs,
        'vip_expires_at': vipExpiresAtUtcMs,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.rawUpdate(
        'UPDATE download_novels SET total_bytes = total_bytes + ? WHERE novel_id = ?',
        [byteSize, novelId],
      );
      await transaction.update(
        'download_jobs',
        {
          'status': DownloadJobStatus.completed.name,
          'temp_path': null,
          'last_error': null,
        },
        where: 'job_id = ?',
        whereArgs: [jobId],
      );
      await transaction.rawUpdate(
        'UPDATE download_days SET completed = completed + 1 WHERE day_ordinal = ?',
        [reservedDay],
      );
      await _finishGroupIfTerminal(transaction, row['group_id']! as String);
    });
  }

  @override
  Future<void> release(String jobId, {required DownloadFailure reason}) {
    return _database.transaction((transaction) async {
      final rows = await transaction.query(
        'download_jobs',
        columns: ['group_id'],
        where: 'job_id = ?',
        whereArgs: [jobId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      await transaction.update(
        'download_jobs',
        {
          'status': DownloadJobStatus.failed.name,
          'reserved_day': null,
          'last_error': reason.name,
        },
        where: 'job_id = ?',
        whereArgs: [jobId],
      );
      await transaction.update(
        'download_groups',
        {
          'status': DownloadGroupStatus.paused.name,
          'stop_reason': reason.name,
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        where: 'group_id = ?',
        whereArgs: [rows.single['group_id']],
      );
    });
  }

  @override
  Future<DownloadStoreSnapshot> grantReward({
    required String rewardEventId,
    required DownloadPlan plan,
    required DateTime now,
  }) async {
    await _database.transaction((transaction) async {
      final dayOrdinal = await _ensureDay(transaction, now);
      final day = await _dayRow(transaction, dayOrdinal);
      final reservedToday =
          Sqflite.firstIntValue(
            await transaction.rawQuery(
              '''
              SELECT COUNT(*) FROM download_jobs
              WHERE reserved_day = ? AND status IN (?, ?, ?)
              ''',
              [
                dayOrdinal,
                DownloadJobStatus.reserved.name,
                DownloadJobStatus.transferring.name,
                DownloadJobStatus.processing.name,
              ],
            ),
          ) ??
          0;
      final remaining = math.max(
        0,
        plan.baseChapters +
            _int(day['rewarded_credits']) -
            _int(day['completed']) -
            reservedToday,
      );
      if (remaining > 0 || _int(day['completed_ads']) >= plan.maxRewardedAds) {
        return;
      }

      final inserted = await transaction.rawInsert(
        '''
        INSERT OR IGNORE INTO download_reward_events(
          event_id, day_ordinal, credits, created_at
        ) VALUES(?, ?, ?, ?)
        ''',
        [
          rewardEventId,
          dayOrdinal,
          plan.rewardPerAd,
          now.toUtc().millisecondsSinceEpoch,
        ],
      );
      if (inserted == 0) return;
      await transaction.rawUpdate(
        '''
        UPDATE download_days
        SET rewarded_credits = rewarded_credits + ?,
            completed_ads = completed_ads + 1
        WHERE day_ordinal = ?
        ''',
        [plan.rewardPerAd, dayOrdinal],
      );
    });
    return snapshot();
  }

  @override
  Future<DownloadStoreSnapshot> snapshot() async {
    final highestDayRows = await _database.rawQuery('''
      SELECT * FROM download_days
      ORDER BY highest_seen_day DESC
      LIMIT 1
    ''');
    final day = highestDayRows.isEmpty
        ? const <String, Object?>{}
        : highestDayRows.single;
    final highestDay = _int(day['highest_seen_day']);
    final reserved = highestDay == 0
        ? 0
        : Sqflite.firstIntValue(
                await _database.rawQuery(
                  '''
                SELECT COUNT(*) FROM download_jobs
                WHERE reserved_day = ? AND status IN (?, ?, ?)
                ''',
                  [
                    highestDay,
                    DownloadJobStatus.reserved.name,
                    DownloadJobStatus.transferring.name,
                    DownloadJobStatus.processing.name,
                  ],
                ),
              ) ??
              0;

    final membershipRows = await _database.query(
      'download_membership',
      where: 'id = 1',
      limit: 1,
    );
    final settingsRows = await _database.query(
      'download_settings',
      where: 'id = 1',
      limit: 1,
    );
    final membership = membershipRows.single;
    final novelRows = await _database.query(
      'download_novels',
      orderBy: 'novel_id',
    );
    final novels = <DownloadedNovel>[];
    for (final novel in novelRows) {
      final chapterRows = await _database.query(
        'downloaded_chapters',
        where: 'novel_id = ?',
        whereArgs: [novel['novel_id']],
        orderBy: 'downloaded_at DESC',
      );
      novels.add(
        DownloadedNovel(
          novelId: _int(novel['novel_id']),
          title: novel['title']! as String,
          coverUrl: novel['cover_url']! as String,
          coverPath: novel['cover_path']! as String,
          totalBytes: _int(novel['total_bytes']),
          chapters: List.unmodifiable(chapterRows.map(_chapterFromRow)),
        ),
      );
    }

    final groupRows = await _database.query(
      'download_groups',
      orderBy: 'created_at',
    );
    final groups = <DownloadGroup>[];
    for (final group in groupRows) {
      final jobRows = await _database.query(
        'download_jobs',
        where: 'group_id = ?',
        whereArgs: [group['group_id']],
        orderBy: 'sort_index',
      );
      groups.add(
        DownloadGroup(
          groupId: group['group_id']! as String,
          novelId: _int(group['novel_id']),
          status: _enumByName(
            DownloadGroupStatus.values,
            group['status']! as String,
          ),
          stopReason: _nullableEnumByName(
            DownloadFailure.values,
            group['stop_reason'] as String?,
          ),
          createdAtUtcMs: _int(group['created_at']),
          updatedAtUtcMs: _int(group['updated_at']),
          jobs: List.unmodifiable(jobRows.map(_jobFromRow)),
        ),
      );
    }

    return DownloadStoreSnapshot(
      groups: List.unmodifiable(groups),
      novels: List.unmodifiable(novels),
      membership: DownloadMembershipSnapshot(
        userId: membership['user_id'] as int?,
        active: _int(membership['active']) == 1,
        tier: _enumByName(
          DownloadMembershipTier.values,
          membership['tier']! as String,
        ),
        verifiedAtUtcMs: _int(membership['verified_at']),
        expiresAtUtcMs: membership['expires_at'] as int?,
      ),
      completedToday: _int(day['completed']),
      reservedCount: reserved,
      rewardedCredits: _int(day['rewarded_credits']),
      completedAds: _int(day['completed_ads']),
      highestSeenDayOrdinal: highestDay,
      wifiOnly: _int(settingsRows.single['wifi_only']) == 1,
      totalBytes: novels.fold(0, (total, novel) => total + novel.totalBytes),
    );
  }

  @override
  Future<void> saveMembership(DownloadMembershipSnapshot membership) {
    return _database.update('download_membership', {
      'user_id': membership.userId,
      'active': membership.active ? 1 : 0,
      'tier': membership.tier.name,
      'verified_at': membership.verifiedAtUtcMs,
      'expires_at': membership.expiresAtUtcMs,
    }, where: 'id = 1');
  }

  @override
  Future<void> updateCoverPath(int novelId, String coverPath) {
    return _database.update(
      'download_novels',
      {'cover_path': coverPath},
      where: 'novel_id = ?',
      whereArgs: [novelId],
    );
  }

  @override
  Future<void> setWifiOnly(bool value) {
    return _database.update('download_settings', {
      'wifi_only': value ? 1 : 0,
    }, where: 'id = 1');
  }

  @override
  Future<void> deleteChapters(Set<String> chapterKeys) async {
    if (chapterKeys.isEmpty) return;
    await _database.transaction((transaction) async {
      for (final chapterKey in chapterKeys) {
        final rows = await transaction.query(
          'downloaded_chapters',
          columns: ['novel_id', 'byte_size'],
          where: 'chapter_key = ?',
          whereArgs: [chapterKey],
          limit: 1,
        );
        if (rows.isEmpty) continue;
        final novelId = _int(rows.single['novel_id']);
        final byteSize = _int(rows.single['byte_size']);
        await transaction.delete(
          'downloaded_chapters',
          where: 'chapter_key = ?',
          whereArgs: [chapterKey],
        );
        await transaction.delete(
          'download_jobs',
          where: 'chapter_key = ? AND status = ?',
          whereArgs: [chapterKey, DownloadJobStatus.completed.name],
        );
        await transaction.rawUpdate(
          '''
          UPDATE download_novels
          SET total_bytes = MAX(0, total_bytes - ?)
          WHERE novel_id = ?
          ''',
          [byteSize, novelId],
        );
        if (!await _novelHasWork(transaction, novelId)) {
          await transaction.delete(
            'download_groups',
            where: '''
              novel_id = ? AND NOT EXISTS(
                SELECT 1 FROM download_jobs
                WHERE download_jobs.group_id = download_groups.group_id
              )
            ''',
            whereArgs: [novelId],
          );
          await transaction.delete(
            'download_novels',
            where: 'novel_id = ?',
            whereArgs: [novelId],
          );
        }
      }
    });
  }

  @override
  Future<void> close() => _database.close();

  static String _newId(String prefix) {
    _idSequence += 1;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  static Future<bool> _chapterKeyExists(
    DatabaseExecutor db,
    String chapterKey,
  ) async {
    final downloaded =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM downloaded_chapters WHERE chapter_key = ?',
            [chapterKey],
          ),
        ) ??
        0;
    if (downloaded > 0) return true;
    final jobs =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM download_jobs WHERE chapter_key = ?',
            [chapterKey],
          ),
        ) ??
        0;
    return jobs > 0;
  }

  static Future<bool> _novelHasWork(DatabaseExecutor db, int novelId) async {
    final chapters =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM downloaded_chapters WHERE novel_id = ?',
            [novelId],
          ),
        ) ??
        0;
    if (chapters > 0) return true;
    final jobs =
        Sqflite.firstIntValue(
          await db.rawQuery(
            '''
            SELECT COUNT(*)
            FROM download_jobs j
            JOIN download_groups g ON g.group_id = j.group_id
            WHERE g.novel_id = ?
            ''',
            [novelId],
          ),
        ) ??
        0;
    return jobs > 0;
  }

  static Future<int> _ensureDay(DatabaseExecutor db, DateTime now) async {
    final current = now.dayOrdinal;
    final rows = await db.rawQuery('''
      SELECT highest_seen_day FROM download_days
      ORDER BY highest_seen_day DESC
      LIMIT 1
    ''');
    final highest = rows.isEmpty ? 0 : _int(rows.single['highest_seen_day']);
    final effective = math.max(current, highest);
    await db.rawInsert(
      '''
      INSERT OR IGNORE INTO download_days(
        day_ordinal, highest_seen_day, completed, rewarded_credits, completed_ads
      ) VALUES(?, ?, 0, 0, 0)
      ''',
      [effective, effective],
    );
    await db.rawUpdate(
      'UPDATE download_days SET highest_seen_day = ? WHERE day_ordinal = ?',
      [effective, effective],
    );
    return effective;
  }

  static Future<Map<String, Object?>> _dayRow(
    DatabaseExecutor db,
    int dayOrdinal,
  ) async {
    final rows = await db.query(
      'download_days',
      where: 'day_ordinal = ?',
      whereArgs: [dayOrdinal],
      limit: 1,
    );
    return rows.single;
  }

  static Future<void> _finishGroupIfTerminal(
    DatabaseExecutor db,
    String groupId,
  ) async {
    final unfinished =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM download_jobs WHERE group_id = ? AND status != ?',
            [groupId, DownloadJobStatus.completed.name],
          ),
        ) ??
        0;
    if (unfinished == 0) {
      await db.update(
        'download_groups',
        {
          'status': DownloadGroupStatus.completed.name,
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        },
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
    }
  }

  static DownloadedChapter _chapterFromRow(Map<String, Object?> row) {
    return DownloadedChapter(
      chapterKey: row['chapter_key']! as String,
      novelId: _int(row['novel_id']),
      chapterId: _int(row['chapter_id']),
      label: row['label']! as String,
      contentApi: row['content_api']! as String,
      isVip: _int(row['is_vip']) == 1,
      filePath: row['file_path']! as String,
      byteSize: _int(row['byte_size']),
      downloadedAtUtcMs: _int(row['downloaded_at']),
      vipVerifiedAtUtcMs: row['vip_verified_at'] as int?,
      vipExpiresAtUtcMs: row['vip_expires_at'] as int?,
    );
  }

  static DownloadJob _jobFromRow(Map<String, Object?> row) {
    return DownloadJob(
      jobId: row['job_id']! as String,
      groupId: row['group_id']! as String,
      chapterKey: row['chapter_key']! as String,
      chapterId: _int(row['chapter_id']),
      label: row['label']! as String,
      contentApi: row['content_api']! as String,
      isVip: _int(row['is_vip']) == 1,
      status: _enumByName(DownloadJobStatus.values, row['status']! as String),
      sortIndex: _int(row['sort_index']),
      reservedDayOrdinal: row['reserved_day'] as int?,
      transferTaskId: row['transfer_task_id'] as String?,
      tempPath: row['temp_path'] as String?,
      attempts: _int(row['attempts']),
      lastError: _nullableEnumByName(
        DownloadFailure.values,
        row['last_error'] as String?,
      ),
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, String name) {
    return values.firstWhere((value) => value.name == name);
  }

  static T? _nullableEnumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    return _enumByName(values, name);
  }

  static int _int(Object? value) => value is int ? value : 0;
}
