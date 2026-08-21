# Local-First Rewarded Downloads Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Do not use subagents; the user explicitly prohibited them. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** بناء نظام تنزيل فصول محلي بحصص يومية حسب فئة VIP، ومكافآت AdMob محدودة، وطابور خلفي قابل للاستعادة، وقراءة عامة دون اتصال مع قفل محتوى VIP عند فقدان الاستحقاق.

**Architecture:** يفصل التنفيذ بين سياسة الاستحقاق النقية، ودفتر SQLite الذري، ومخزن ملفات المحتوى، وبوابة النقل الخلفي، ومستودع واحد يعرض حالة قابلة للمراقبة للواجهات. يستخدم `background_downloader` لنقل الملفات والإشعارات وشرط Wi-Fi، و`workmanager` لإيقاظ الطابور بعد منتصف الليل، وAES-GCM مع مفتاح محفوظ عبر `flutter_secure_storage` لفصول VIP.

**Tech Stack:** Flutter 3.41.7، Dart 3.11.5، Material 3، `sqflite 2.4.2+1`، `background_downloader 9.5.6`، `workmanager 0.9.0+3`، `cryptography 2.9.0`، `cryptography_flutter 2.3.4`، Google Mobile Ads 9.x، Android Java 17/Kotlin 2.2.20.

## Global Constraints

- التنفيذ المستهدف Android في هذه المرحلة؛ لا توسع النطاق إلى iOS أو سطح المكتب.
- الحالة والحصص محلية على الجهاز ولا توجد مزامنة خادم أو بين الأجهزة.
- الحصص ثابتة: عادي `100 + 4×20`، VIP 1 `200 + 5×40`، VIP 2 `400 + 5×80`، VIP 3 `600 + 5×100`، VIP Max `1000 + 6×100`.
- يبدأ يوم جديد عند منتصف الليل المحلي فقط عندما يتقدم التاريخ؛ إرجاع التاريخ لا يعيد الحصة.
- الخصم النهائي بعد حفظ فصل جديد صالح فقط؛ الفشل والإلغاء والحجز المحرر لا يخصمون.
- لا يظهر إعلان مكافأة إلا عند رصيد صفر، ولا تمنح المكافأة إلا من `onUserEarnedReward`.
- تنزيل فصلين بالتوازي كحد أقصى، مع حجز ذري قبل النقل.
- الملفات العامة تبقى حتى الحذف اليدوي؛ ملفات VIP مشفرة وتقفل عند فقدان الأهلية.
- عدم وجود `expiresAt` يسمح بفتح VIP سبعة أيام من آخر تحقق ناجح، ثم يلزم اتصال.
- أوامر التنزيل في قوائم الفصول فقط؛ لا يضاف زر إلى شاشة القراءة.
- شاشة التنزيلات تعرض العمليات أولًا ثم الروايات المكتملة مع الغلاف.
- دليل الاستخدام يفتح من علامة الاستفهام فقط في لوحة سفلية نصفية.
- دعم Galaxy Noir وStarlight Paper، عروض 320/600/840، الأفقي، ونص 200%.
- وحدة rewarded في debug/profile هي وحدة Google الاختبارية `ca-app-pub-3940256099942544/5224354917`؛ release يتطلب `ADMOB_ANDROID_DOWNLOAD_REWARDED_ID` ولا يخمن قيمة إنتاج.
- لا تضمّن تغييرات المستخدم غير المرتبطة في أي commit.

## File Structure

### Domain and application

- `lib/features/downloads/domain/download_entitlement.dart`: الفئات والخطط وحساب الرصيد والتجدد.
- `lib/features/downloads/domain/download_models.dart`: الطلبات والمهام والمجموعات والفصول المحفوظة ولقطة الشاشة.
- `lib/features/downloads/application/download_store.dart`: عقد العمليات الذرية الدائمة.
- `lib/features/downloads/application/download_transfer.dart`: عقد النقل الخلفي وتحديثاته.
- `lib/features/downloads/application/download_repository.dart`: API الواجهة والطابور والقراءة المحلية.
- `lib/features/downloads/application/download_resume_scheduler.dart`: عقد إيقاظ منتصف الليل.

### Data

- `lib/features/downloads/data/sqflite_download_store.dart`: schema ومعاملات الحجز والخصم والمكافآت.
- `lib/features/downloads/data/downloaded_chapter_file_store.dart`: ملفات JSON العامة وAES-GCM لـVIP.
- `lib/features/downloads/data/secure_download_key_store.dart`: مفتاح VIP في التخزين الآمن.
- `lib/features/downloads/data/background_download_transfer.dart`: تكامل `background_downloader`.
- `lib/features/downloads/data/workmanager_download_resume_scheduler.dart`: مهمة منتصف الليل.
- `lib/features/downloads/data/stored_download_repository.dart`: منسق الطابور والمصالحة والحالة.
- `lib/features/downloads/data/download_aware_reader_repository.dart`: قراءة URI المحلي أو التفويض للمستودع الحالي.
- `lib/features/downloads/data/download_background_entrypoint.dart`: bootstrap مستقل لعزلة WorkManager.

### Ads and presentation

- `lib/features/ads/application/rewarded_download_ad_repository.dart`: نتيجة الإعلان وعقد العرض.
- `lib/features/ads/data/admob_rewarded_download_ad_repository.dart`: AdMob rewarded.
- `lib/features/downloads/presentation/downloads_screen.dart`: الشاشة الرئيسية.
- `lib/features/downloads/presentation/downloads_help_sheet.dart`: دليل الخطوات.
- `lib/features/downloads/presentation/download_quota_sheet.dart`: انتهاء الحصة والمكافأة.
- `lib/features/downloads/presentation/download_quota_prompt_host.dart`: العرض التلقائي مرة لكل توقف.
- `lib/features/downloads/presentation/widgets/download_queue_section.dart`: العمليات الجارية.
- `lib/features/downloads/presentation/widgets/downloaded_novel_group.dart`: التجميع بالغلاف والفصول.
- `lib/features/downloads/presentation/widgets/download_allowance_strip.dart`: الحصة والفئة والإعلانات والمساحة.

---

### Task 1: Add verified dependencies and Android background contract

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/res/values-ar/strings.xml`
- Test: `test/app/android_download_platform_contract_test.dart`

**Interfaces:**
- Consumes: Android API 21+، Kotlin 2.2.20، Google Mobile Ads الحالي.
- Produces: SQLite، النقل الخلفي، التشفير، WorkManager، وأذونات الإشعار/foreground المطلوبة لبقية المهام.

- [ ] **Step 1: Write the failing platform contract test**

```dart
test('Android declares the download foreground service contract', () {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();
  expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
  expect(manifest, contains('android.permission.FOREGROUND_SERVICE_DATA_SYNC'));
  expect(manifest, contains('androidx.work.impl.foreground.SystemForegroundService'));
  expect(manifest, contains('android:foregroundServiceType="dataSync"'));
});
```

- [ ] **Step 2: Run the test to verify RED**

Run: `flutter test test/app/android_download_platform_contract_test.dart`

Expected: FAIL because the notification and foreground service declarations are absent.

- [ ] **Step 3: Add compatible packages**

Add exactly:

```yaml
dependencies:
  background_downloader: ^9.5.6
  cryptography: ^2.9.0
  cryptography_flutter: ^2.3.4
  path: ^1.9.1
  sqflite: 2.4.2+1
  workmanager: ^0.9.0+3

dev_dependencies:
  sqflite_common_ffi: 2.4.0+3
```

Use `sqflite 2.4.2+1` and `sqflite_common_ffi 2.4.0+3` because their newer releases require Dart 3.12 while this app uses Dart 3.11.5.

- [ ] **Step 4: Add Android declarations and Arabic downloader strings**

Add above `<application>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
```

Add inside `<application>`:

```xml
<service
    android:name="androidx.work.impl.foreground.SystemForegroundService"
    android:foregroundServiceType="dataSync"
    tools:node="merge" />
```

Add `xmlns:tools="http://schemas.android.com/tools"` to `<manifest>`. Create Arabic values:

```xml
<resources>
    <string name="bg_downloader_cancel">إلغاء</string>
    <string name="bg_downloader_pause">إيقاف مؤقت</string>
    <string name="bg_downloader_resume">استئناف</string>
    <string name="bg_downloader_notification_channel_name">تنزيل الفصول</string>
    <string name="bg_downloader_notification_channel_description">تقدم تنزيل فصول الروايات</string>
</resources>
```

- [ ] **Step 5: Verify packages, test, and Android debug build**

Run:

```powershell
flutter pub get
flutter test test/app/android_download_platform_contract_test.dart
flutter build apk --debug
```

Expected: dependency resolution succeeds, test PASS, APK builds.

- [ ] **Step 6: Commit**

```powershell
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml android/app/src/main/res/values-ar/strings.xml test/app/android_download_platform_contract_test.dart
git commit -m "build(downloads): add local background download dependencies"
```

### Task 2: Implement the entitlement policy and anti-rollback day logic

**Files:**
- Create: `lib/features/downloads/domain/download_entitlement.dart`
- Test: `test/features/downloads/download_entitlement_test.dart`

**Interfaces:**
- Consumes: `AuthVip(active, tier, expiresAt)`.
- Produces: `DownloadMembershipTier.fromVip(AuthVip?)`, `DownloadPlan.forTier(DownloadMembershipTier)`, `DownloadEntitlementPolicy.evaluate({required DateTime now, required int highestLocalDayOrdinal, required int completed, required int reserved, required int rewardedCredits, required int completedAds, required DownloadMembershipTier tier})`, `DownloadAllowance`.

- [ ] **Step 1: Write table-driven failing tests**

```dart
const cases = [
  (tier: DownloadMembershipTier.regular, base: 100, ads: 4, reward: 20),
  (tier: DownloadMembershipTier.vip1, base: 200, ads: 5, reward: 40),
  (tier: DownloadMembershipTier.vip2, base: 400, ads: 5, reward: 80),
  (tier: DownloadMembershipTier.vip3, base: 600, ads: 5, reward: 100),
  (tier: DownloadMembershipTier.vipMax, base: 1000, ads: 6, reward: 100),
];
for (final value in cases) {
  test('${value.tier} exposes the approved plan', () {
    final plan = DownloadPlan.forTier(value.tier);
    expect(plan.baseChapters, value.base);
    expect(plan.maxRewardedAds, value.ads);
    expect(plan.rewardPerAd, value.reward);
  });
}

test('clock rollback never creates a new day', () {
  final result = const DownloadEntitlementPolicy().evaluate(
    now: DateTime(2026, 7, 19, 23),
    highestLocalDayOrdinal: DateTime(2026, 7, 20).dayOrdinal,
    completed: 100,
    reserved: 0,
    rewardedCredits: 0,
    completedAds: 0,
    tier: DownloadMembershipTier.regular,
  );
  expect(result.shouldReset, isFalse);
  expect(result.remaining, 0);
}
```

Also cover aliases `vip1`, `vip_1`, `vip2`, `vip_2`, `vip3`, `vip_3`, `max`, `vipmax`, `vip_max`; inactive and unknown active tiers map to regular.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/downloads/download_entitlement_test.dart`

Expected: FAIL because the domain does not exist.

- [ ] **Step 3: Implement immutable policy types**

Use these public shapes:

```dart
enum DownloadMembershipTier { regular, vip1, vip2, vip3, vipMax }

class DownloadPlan {
  const DownloadPlan({
    required this.baseChapters,
    required this.maxRewardedAds,
    required this.rewardPerAd,
  });
  final int baseChapters;
  final int maxRewardedAds;
  final int rewardPerAd;
  int get maximumDailyChapters =>
      baseChapters + (maxRewardedAds * rewardPerAd);
  static DownloadPlan forTier(DownloadMembershipTier tier) => switch (tier) {
    DownloadMembershipTier.regular => const DownloadPlan(baseChapters: 100, maxRewardedAds: 4, rewardPerAd: 20),
    DownloadMembershipTier.vip1 => const DownloadPlan(baseChapters: 200, maxRewardedAds: 5, rewardPerAd: 40),
    DownloadMembershipTier.vip2 => const DownloadPlan(baseChapters: 400, maxRewardedAds: 5, rewardPerAd: 80),
    DownloadMembershipTier.vip3 => const DownloadPlan(baseChapters: 600, maxRewardedAds: 5, rewardPerAd: 100),
    DownloadMembershipTier.vipMax => const DownloadPlan(baseChapters: 1000, maxRewardedAds: 6, rewardPerAd: 100),
  };
}

class DownloadAllowance {
  const DownloadAllowance({
    required this.plan,
    required this.remaining,
    required this.adsRemaining,
    required this.shouldReset,
    required this.effectiveDayOrdinal,
  });
  final DownloadPlan plan;
  final int remaining;
  final int adsRemaining;
  final bool shouldReset;
  final int effectiveDayOrdinal;
  bool get canDownload => remaining > 0;
  bool get canWatchRewardedAd => remaining == 0 && adsRemaining > 0;
}
```

Add a local-date ordinal extension based on `DateTime(year, month, day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay`; do not use UTC day for reset.

Name it exactly:

```dart
extension LocalDownloadDay on DateTime {
  int get dayOrdinal =>
      DateTime(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
```

- [ ] **Step 4: Verify policy tests**

Run: `flutter test test/features/downloads/download_entitlement_test.dart`

Expected: PASS for all tiers, upgrade/downgrade, reward preservation, midnight, and rollback.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/downloads/domain/download_entitlement.dart test/features/downloads/download_entitlement_test.dart
git commit -m "feat(downloads): define daily entitlement policy"
```

### Task 3: Add domain models and an atomic SQLite store

**Files:**
- Create: `lib/features/downloads/domain/download_models.dart`
- Create: `lib/features/downloads/application/download_store.dart`
- Create: `lib/features/downloads/data/sqflite_download_store.dart`
- Test: `test/features/downloads/sqflite_download_store_test.dart`

**Interfaces:**
- Consumes: `DownloadPlan`, local day ordinal, chapter/novel requests, and the last verified membership snapshot.
- Produces: `DownloadStore.open`, `enqueue`, `reserveNext`, `complete`, `release`, `grantReward`, `snapshot`, `saveMembership`, `updateCoverPath`, `setWifiOnly`, delete and reconciliation methods.

- [ ] **Step 1: Define failing transaction tests with FFI SQLite**

Initialize `sqfliteFfiInit()` and an in-memory database. Test this sequence:

```dart
final group = await store.enqueue(
  novel: const DownloadNovelRequest(
    novelId: 7,
    title: 'رواية الاختبار',
    coverUrl: 'https://example.com/cover.jpg',
  ),
  chapters: const [
    DownloadChapterRequest(
      chapterKey: 'public:71',
      chapterId: 71,
      label: 'الفصل 71',
      contentApi: '/wp-json/wor-reader-app/v1/chapters/71',
      isVip: false,
    ),
  ],
);
final reservation = await store.reserveNext(
  plan: DownloadPlan.forTier(DownloadMembershipTier.regular),
  now: DateTime(2026, 7, 20, 9),
);
expect(reservation?.groupId, group.groupId);
expect((await store.snapshot()).reservedCount, 1);
await store.release(reservation!.jobId, reason: DownloadFailure.network);
expect((await store.snapshot()).completedToday, 0);
```

Add tests for two simultaneous reservations, no 101st regular reservation, duplicate chapter rejection, successful completion charging the reservation day even after midnight, atomic reward grant once per `rewardEventId`, deletion not restoring quota, membership persistence across a fresh store instance, and an atomic local-cover-path update.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/downloads/sqflite_download_store_test.dart`

Expected: FAIL because models and store are absent.

- [ ] **Step 3: Create the exact domain state types**

Define:

```dart
enum DownloadJobStatus { queued, reserved, transferring, processing, paused, completed, failed, canceled }
enum DownloadGroupStatus { queued, running, paused, waitingForQuota, waitingForWifi, waitingForNetwork, storageFull, completed, canceled }
enum DownloadFailure { network, wifiRequired, storageFull, unauthorized, vipRequired, invalidContent, canceled, unknown }

class DownloadChapterRequest {
  const DownloadChapterRequest({required this.chapterKey, required this.chapterId, required this.label, required this.contentApi, required this.isVip});
  final String chapterKey;
  final int chapterId;
  final String label;
  final String contentApi;
  final bool isVip;
}
```

Also define immutable `DownloadNovelRequest`, `DownloadJob`, `DownloadGroup`, `DownloadedChapter`, `DownloadedNovel`, `DownloadReservation`, `DownloadEnqueueResult`, `DownloadStoreSnapshot`, and `DownloadsDashboard`. Every stored time is integer UTC milliseconds; day ordinals are integer local calendar keys.

The cross-task fields are fixed as follows:

```dart
class DownloadEnqueueResult {
  const DownloadEnqueueResult({required this.groupId, required this.acceptedChapterKeys, required this.skippedChapterKeys});
  final String? groupId;
  final List<String> acceptedChapterKeys;
  final List<String> skippedChapterKeys;
}

class DownloadMembershipSnapshot {
  const DownloadMembershipSnapshot({required this.userId, required this.active, required this.tier, required this.verifiedAtUtcMs, required this.expiresAtUtcMs});
  final int? userId;
  final bool active;
  final DownloadMembershipTier tier;
  final int verifiedAtUtcMs;
  final int? expiresAtUtcMs;
}

class DownloadStoreSnapshot {
  const DownloadStoreSnapshot({required this.groups, required this.novels, required this.membership, required this.completedToday, required this.reservedCount, required this.rewardedCredits, required this.completedAds, required this.highestSeenDayOrdinal, required this.wifiOnly, required this.totalBytes});
  final List<DownloadGroup> groups;
  final List<DownloadedNovel> novels;
  final DownloadMembershipSnapshot membership;
  final int completedToday;
  final int reservedCount;
  final int rewardedCredits;
  final int completedAds;
  final int highestSeenDayOrdinal;
  final bool wifiOnly;
  final int totalBytes;
}

class DownloadsDashboard {
  const DownloadsDashboard({required this.allowance, required this.groups, required this.novels, required this.wifiOnly, required this.totalBytes, required this.quotaBlockGeneration, required this.isInitializing});
  final DownloadAllowance allowance;
  final List<DownloadGroup> groups;
  final List<DownloadedNovel> novels;
  final bool wifiOnly;
  final int totalBytes;
  final int quotaBlockGeneration;
  final bool isInitializing;
}
```

- [ ] **Step 4: Create schema version 1**

Create tables in one `onCreate` transaction:

```sql
CREATE TABLE download_days(day_ordinal INTEGER PRIMARY KEY, highest_seen_day INTEGER NOT NULL, completed INTEGER NOT NULL DEFAULT 0, rewarded_credits INTEGER NOT NULL DEFAULT 0, completed_ads INTEGER NOT NULL DEFAULT 0);
CREATE TABLE download_reward_events(event_id TEXT PRIMARY KEY, day_ordinal INTEGER NOT NULL, credits INTEGER NOT NULL, created_at INTEGER NOT NULL);
CREATE TABLE download_novels(novel_id INTEGER PRIMARY KEY, title TEXT NOT NULL, cover_url TEXT NOT NULL, cover_path TEXT NOT NULL DEFAULT '', total_bytes INTEGER NOT NULL DEFAULT 0);
CREATE TABLE download_groups(group_id TEXT PRIMARY KEY, novel_id INTEGER NOT NULL, status TEXT NOT NULL, stop_reason TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);
CREATE TABLE download_jobs(job_id TEXT PRIMARY KEY, group_id TEXT NOT NULL, chapter_key TEXT NOT NULL UNIQUE, chapter_id INTEGER NOT NULL, label TEXT NOT NULL, content_api TEXT NOT NULL, is_vip INTEGER NOT NULL, status TEXT NOT NULL, sort_index INTEGER NOT NULL, reserved_day INTEGER, transfer_task_id TEXT, temp_path TEXT, attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT);
CREATE TABLE downloaded_chapters(chapter_key TEXT PRIMARY KEY, novel_id INTEGER NOT NULL, chapter_id INTEGER NOT NULL, label TEXT NOT NULL, content_api TEXT NOT NULL, is_vip INTEGER NOT NULL, file_path TEXT NOT NULL, byte_size INTEGER NOT NULL, downloaded_at INTEGER NOT NULL, vip_verified_at INTEGER, vip_expires_at INTEGER);
CREATE TABLE download_membership(id INTEGER PRIMARY KEY CHECK(id = 1), user_id INTEGER, active INTEGER NOT NULL DEFAULT 0, tier TEXT NOT NULL DEFAULT 'regular', verified_at INTEGER NOT NULL DEFAULT 0, expires_at INTEGER);
CREATE TABLE download_settings(id INTEGER PRIMARY KEY CHECK(id = 1), wifi_only INTEGER NOT NULL DEFAULT 0);
```

Insert singleton rows for `download_membership` and `download_settings` in the same transaction. Clean terminal jobs older than 30 days during `open`; keep day ledgers while any job references their ordinal, otherwise keep current and previous day only.

- [ ] **Step 5: Implement atomic methods**

Use `Database.transaction` for `reserveNext`, `complete`, `release`, and `grantReward`. `reserveNext` refreshes the current day only if the local ordinal is greater than `highest_seen_day`, counts active reservations for the same day, then marks one queued job `reserved`. `grantReward` inserts `rewardEventId` first and returns an unchanged snapshot on uniqueness conflict.

- [ ] **Step 6: Verify store tests and commit**

Run: `flutter test test/features/downloads/sqflite_download_store_test.dart`

Expected: PASS.

```powershell
git add lib/features/downloads/domain/download_models.dart lib/features/downloads/application/download_store.dart lib/features/downloads/data/sqflite_download_store.dart test/features/downloads/sqflite_download_store_test.dart
git commit -m "feat(downloads): persist queue and quota atomically"
```

### Task 4: Store public chapters and encrypt VIP chapters

**Files:**
- Create: `lib/features/downloads/data/secure_download_key_store.dart`
- Create: `lib/features/downloads/data/downloaded_chapter_file_store.dart`
- Create: `lib/features/downloads/data/reader_content_codec.dart`
- Test: `test/features/downloads/downloaded_chapter_file_store_test.dart`

**Interfaces:**
- Consumes: `ReaderChapterContent`, `DownloadChapterRequest`, app support directory.
- Produces: `writePublic`, `writeVip`, `readPublic`, `readVip`, `delete`, `reconcile`, and `offlineChapterUri(String chapterKey)`.

- [ ] **Step 1: Write failing round-trip and confidentiality tests**

```dart
final publicPath = await files.writePublic('public:4', content);
final decodedPublic = await files.readPublic(publicPath);
expect(decodedPublic.chapterId, content.chapterId);
expect(decodedPublic.contentHtml, content.contentHtml);

final vipPath = await files.writeVip('vip:9', content);
final raw = await File(vipPath).readAsString();
expect(raw, isNot(contains(content.contentHtml)));
final decodedVip = await files.readVip(vipPath);
expect(decodedVip.chapterId, content.chapterId);
expect(decodedVip.contentHtml, content.contentHtml);
expect(offlineChapterUri('vip:9'), 'galaxy-download://chapter/vip%3A9');
```

Also test wrong key failure, truncated ciphertext rejection, atomic `.part` rename, orphan `.part` cleanup, and missing file reporting.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/downloads/downloaded_chapter_file_store_test.dart`

Expected: FAIL because the file store is absent.

- [ ] **Step 3: Implement stable JSON codec**

Encode every `ReaderChapterContent` field and nested navigation field. Decode using `ReaderChapterContent.fromJson`. Do not serialize arbitrary objects or runtime type names.

- [ ] **Step 4: Implement AES-GCM and secure key storage**

Use `AesGcm.with256bits()`. Store one 32-byte device key as base64 under key `galaxy_novels_download_key_v1` with Android namespace `galaxy_novels_downloads`. File format is:

```text
GNVIP1\n<base64 nonce>\n<base64 mac>\n<base64 cipherText>
```

Write to `<chapter-key>.part`, flush, then rename to `<chapter-key>.gnchapter`. Public files use UTF-8 JSON with the same atomic rename but without encryption.

- [ ] **Step 5: Verify and commit**

Run: `flutter test test/features/downloads/downloaded_chapter_file_store_test.dart`

Expected: PASS.

```powershell
git add lib/features/downloads/data/secure_download_key_store.dart lib/features/downloads/data/downloaded_chapter_file_store.dart lib/features/downloads/data/reader_content_codec.dart test/features/downloads/downloaded_chapter_file_store_test.dart
git commit -m "feat(downloads): store encrypted offline chapter files"
```

### Task 5: Build the native transfer gateway and midnight scheduler

**Files:**
- Create: `lib/features/downloads/application/download_transfer.dart`
- Create: `lib/features/downloads/application/download_resume_scheduler.dart`
- Create: `lib/features/downloads/data/background_download_transfer.dart`
- Create: `lib/features/downloads/data/workmanager_download_resume_scheduler.dart`
- Test: `test/features/downloads/background_download_transfer_test.dart`
- Test: `test/features/downloads/download_resume_scheduler_test.dart`

**Interfaces:**
- Consumes: transfer kind, absolute HTTPS URL, safe headers, destination filename, Wi-Fi flag, transfer ID.
- Produces: `Stream<DownloadTransferUpdate>`, enqueue/pause/resume/cancel, and one unique midnight wake-up.

- [ ] **Step 1: Write fake-driven contract tests**

Test that chapter transfers use `group: 'chapter-downloads'`, `BaseDirectory.applicationSupport`, `directory: 'galaxy_downloads/tmp'`, while cover transfers use `group: 'download-covers'`, `directory: 'galaxy_downloads/covers'`. Both use `Updates.statusAndProgress`, `allowPause: true`, `retries: 2`, and `requiresWiFi` from settings. Test that scheduling at `2026-07-20 23:50` uses an eleven-minute delay to the deliberate `00:01` wake-up and replaces the unique task `galaxy-download-midnight-resume`.

- [ ] **Step 2: Run to verify RED**

Run:

```powershell
flutter test test/features/downloads/background_download_transfer_test.dart
flutter test test/features/downloads/download_resume_scheduler_test.dart
```

Expected: FAIL because gateway and scheduler are absent.

- [ ] **Step 3: Define stable transfer contracts**

```dart
enum DownloadTransferKind { chapter, cover }

class DownloadTransferRequest {
  const DownloadTransferRequest({required this.transferId, required this.kind, required this.url, required this.headers, required this.fileName, required this.requiresWifi});
  final String transferId;
  final DownloadTransferKind kind;
  final Uri url;
  final Map<String, String> headers;
  final String fileName;
  final bool requiresWifi;
}

sealed class DownloadTransferUpdate { const DownloadTransferUpdate(this.transferId); final String transferId; }
final class DownloadTransferProgress extends DownloadTransferUpdate { const DownloadTransferProgress(super.transferId, this.value); final double value; }
final class DownloadTransferFinished extends DownloadTransferUpdate { const DownloadTransferFinished(super.transferId, {required this.localPath, required this.statusCode}); final String localPath; final int statusCode; }
final class DownloadTransferFailed extends DownloadTransferUpdate { const DownloadTransferFailed(super.transferId, this.failure); final DownloadFailure failure; }
```

- [ ] **Step 4: Configure background_downloader once**

In `initialize()` call:

```dart
await downloader.configure(
  globalConfig: [
    (Config.holdingQueue, (2, 2, 2)),
    (Config.checkAvailableSpace, 8),
  ],
  androidConfig: [(Config.runInForeground, Config.always)],
);
downloader.configureNotificationForGroup(
  'chapter-downloads',
  running: const TaskNotification('تنزيل الفصول', '{numFinished} من {numTotal} · {progress}'),
  complete: const TaskNotification('اكتمل التنزيل', 'تم حفظ {numTotal} فصلًا'),
  error: const TaskNotification('توقف التنزيل', 'تعذر تنزيل {numFailed} فصل'),
  paused: const TaskNotification('التنزيل متوقف', 'اضغط للاستئناف'),
  progressBar: true,
  groupNotificationId: 'galaxy-chapter-downloads',
);
await downloader.start();
```

Configure a second silent notification group, `download-covers`, without progress notifications. Sanitize `fileName` down to one basename, map native status updates to the stable contracts, and never log headers or tokens. A chapter result remains in `tmp` until the repository validates and persists it; a cover result is already at its final local path.

- [ ] **Step 5: Implement the unique midnight schedule**

```dart
const downloadMidnightTask = 'galaxy_download_midnight_resume';

class WorkmanagerDownloadResumeScheduler implements DownloadResumeScheduler {
  const WorkmanagerDownloadResumeScheduler({required this.workmanager});
  final Workmanager workmanager;

  @override
  Future<void> scheduleNextMidnight(DateTime now) {
    final next = DateTime(now.year, now.month, now.day + 1, 0, 1);
    return workmanager.registerOneOffTask(
      'galaxy-download-midnight-resume',
      downloadMidnightTask,
      initialDelay: next.difference(now),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}
```

The repository will register the dispatcher in Task 6, after its headless bootstrap exists.

- [ ] **Step 6: Verify adapters and commit**

Run the two focused tests and `flutter build apk --debug`; expect PASS and a successful APK.

```powershell
git add lib/features/downloads/application/download_transfer.dart lib/features/downloads/application/download_resume_scheduler.dart lib/features/downloads/data/background_download_transfer.dart lib/features/downloads/data/workmanager_download_resume_scheduler.dart test/features/downloads/background_download_transfer_test.dart test/features/downloads/download_resume_scheduler_test.dart
git commit -m "feat(downloads): add native background transfer scheduling"
```

### Task 6: Orchestrate the queue and inject the repository

**Files:**
- Create: `lib/features/downloads/application/download_repository.dart`
- Create: `lib/features/downloads/data/stored_download_repository.dart`
- Create: `lib/features/downloads/data/download_background_entrypoint.dart`
- Create: `test/helpers/fake_download_repository.dart`
- Modify: `lib/main.dart`
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Test: `test/features/downloads/stored_download_repository_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: store, transfer, file store, scheduler, `AppConfig`, `AuthRepository`, and secure session snapshot.
- Produces: one `DownloadRepository implements ValueListenable<DownloadsDashboard>` used by every UI and reader integration.

- [ ] **Step 1: Write failing repository behavior tests**

Use fake store/transfer/clock/auth and assert:

- enqueue removes stored and duplicate chapters;
- only two reservations start;
- success parses JSON, writes final file, then commits quota;
- invalid JSON and 401 release reservations without charge;
- zero balance marks the group `waitingForQuota` and schedules midnight;
- reward resumes the remaining group;
- network failure retries twice then exposes manual retry;
- Wi-Fi toggle reschedules enqueued transfers;
- restart reconciles completed native tasks and `.part` files;
- the first completed chapter schedules one quota-free cover transfer and persists its local path without blocking the chapter if the cover fails;
- membership refresh is persisted and a fresh headless repository uses that cached tier;
- auth logout immediately recomputes VIP locks.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/downloads/stored_download_repository_test.dart`

Expected: FAIL because `DownloadRepository` is absent.

- [ ] **Step 3: Define the repository API**

```dart
abstract interface class DownloadRepository implements ValueListenable<DownloadsDashboard> {
  Future<void> initialize();
  Future<DownloadEnqueueResult> enqueue({required DownloadNovelRequest novel, required List<DownloadChapterRequest> chapters});
  Future<void> pauseGroup(String groupId);
  Future<void> resumeGroup(String groupId);
  Future<void> cancelGroup(String groupId);
  Future<void> retryJob(String jobId);
  Future<void> grantReward({required String rewardEventId});
  Future<void> setWifiOnly(bool value);
  Future<void> deleteChapters(Set<String> chapterKeys);
  Future<ReaderChapterContent> loadOffline(String offlineUri);
  Future<void> refreshMembership(AuthSessionState state);
  void dispose();
}
```

Provide `NoopDownloadRepository` with an empty dashboard so existing isolated tests need no database.

- [ ] **Step 4: Implement orchestration and safe URL/header creation**

Resolve every `contentApi` through `AppConfig.resolve`, require HTTPS and the configured origin, and reject user info or another host. Public jobs use `Accept`, `User-Agent`, and no-store headers. VIP jobs additionally obtain the current `PrivateSessionSnapshot` and add `Authorization: Bearer <token>` and `X-Wor-App-Token`; never store these headers in the app's SQLite tables.

Process chapter-transfer completion in this order: read temporary response, parse `ReaderChapterContent`, validate requested ID when both IDs are positive, write/encrypt final content, commit the stored record and quota, remove temporary file, start the next reservation, publish dashboard. After the first successful chapter for a novel whose `coverPath` is empty, start one quota-free `DownloadTransferKind.cover` request with transfer ID `cover:<novelId>` and a sanitized extension inferred only from the response MIME type or URL; its success calls `updateCoverPath`, and its failure never rolls back or pauses chapter work.

`refreshMembership` persists `DownloadMembershipSnapshot` before pumping the queue. The cached snapshot is only a quota-tier input for a headless wake-up; it never replaces online VIP authorization for a private chapter request.

- [ ] **Step 5: Add the headless midnight entry point**

```dart
@pragma('vm:entry-point')
void downloadBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != downloadMidnightTask) return true;
    return DownloadBackgroundEntrypoint.resumeWaitingQueue();
  });
}
```

`DownloadBackgroundEntrypoint.resumeWaitingQueue()` initializes Flutter bindings, opens `SqfliteDownloadStore`, creates the secure key/file stores and `BackgroundDownloadTransfer`, reads the cached `DownloadMembershipSnapshot`, and reads `SecureAuthSessionStore` only when a queued VIP request needs its bearer token. It refreshes the local day, enqueues only newly eligible waiting jobs, closes the headless repository, and returns `false` only for retryable initialization or database errors. A missing or expired private session leaves VIP jobs paused as `vipRequired`; it does not fall back to a public request. In `main`, call `Workmanager().initialize(downloadBackgroundDispatcher)` after `WidgetsFlutterBinding.ensureInitialized()`.

- [ ] **Step 6: Inject without breaking test constructors**

Add optional `downloadRepository` to `GalaxyNovelsApp`; add `DownloadRepository downloadRepository = const NoopDownloadRepository()` to `AppDependencies`; include it in `updateShouldNotify`. Construct one default stored repository lazily, initialize once, listen to auth state, and dispose it with the app.

- [ ] **Step 7: Verify focused and shell tests**

Run:

```powershell
flutter test test/features/downloads/stored_download_repository_test.dart
flutter test test/widget_test.dart --plain-name "injects the configured download repository"
```

Expected: PASS.

- [ ] **Step 8: Commit**

```powershell
git add lib/main.dart lib/features/downloads/application/download_repository.dart lib/features/downloads/data/stored_download_repository.dart lib/features/downloads/data/download_background_entrypoint.dart test/helpers/fake_download_repository.dart lib/app/app_dependencies.dart lib/app/galaxy_novels_app.dart test/features/downloads/stored_download_repository_test.dart test/widget_test.dart
git commit -m "feat(downloads): orchestrate persistent chapter queues"
```

### Task 7: Add the rewarded AdMob gateway and idempotent reward coordinator

**Files:**
- Create: `lib/features/ads/application/rewarded_download_ad_repository.dart`
- Create: `lib/features/ads/data/admob_rewarded_download_ad_repository.dart`
- Modify: `lib/features/ads/data/admob_ad_units.dart`
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Test: `test/features/ads/admob_rewarded_download_ad_repository_test.dart`
- Test: `test/features/ads/admob_ad_units_test.dart`

**Interfaces:**
- Consumes: shared `AdMobInitializationCoordinator`, Google rewarded callbacks.
- Produces: `Future<RewardedDownloadAdResult> show()`, with exactly one terminal result.

- [ ] **Step 1: Write failing callback tests**

Test loaded+earned+dismissed returns `earned`, dismissed without reward returns `dismissed`, load/show failures return `unavailable`, two simultaneous `show` calls make the second return `busy`, and duplicate reward callbacks still return one event ID.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/ads/admob_rewarded_download_ad_repository_test.dart test/features/ads/admob_ad_units_test.dart`

Expected: FAIL because rewarded support is absent.

- [ ] **Step 3: Define stable result contract**

```dart
enum RewardedDownloadAdStatus { earned, dismissed, unavailable, busy }

class RewardedDownloadAdResult {
  const RewardedDownloadAdResult(this.status, {this.rewardEventId});
  final RewardedDownloadAdStatus status;
  final String? rewardEventId;
}

abstract interface class RewardedDownloadAdRepository {
  Future<RewardedDownloadAdResult> show();
}
```

- [ ] **Step 4: Add ad unit selection**

Add Android test ID `ca-app-pub-3940256099942544/5224354917`. In release, read `ADMOB_ANDROID_DOWNLOAD_REWARDED_ID`; throw `AdMobConfigurationException` if empty. Do not use the banner production ID as a fallback.

- [ ] **Step 5: Implement AdMob lifecycle**

Use `RewardedAd.load`, set `FullScreenContentCallback`, call `show(onUserEarnedReward:)`, dispose after dismissal or show failure, and complete only once. Generate `rewardEventId` locally when `onUserEarnedReward` fires; the quota amount always comes from `DownloadPlan`, never from `RewardItem.amount`.

- [ ] **Step 6: Inject, verify, and commit**

Run focused ad tests and existing `test/features/ads`; expect PASS.

```powershell
git add lib/features/ads/application/rewarded_download_ad_repository.dart lib/features/ads/data/admob_rewarded_download_ad_repository.dart lib/features/ads/data/admob_ad_units.dart lib/app/app_dependencies.dart lib/app/galaxy_novels_app.dart test/features/ads/admob_rewarded_download_ad_repository_test.dart test/features/ads/admob_ad_units_test.dart
git commit -m "feat(ads): add rewarded chapter download credits"
```

### Task 8: Add individual and multi-select download actions to chapter lists

**Files:**
- Modify: `lib/features/novel_details/presentation/all_chapters_screen.dart`
- Modify: `lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapters_section.dart`
- Modify: `lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart`
- Test: `test/features/novel_details/chapter_download_actions_test.dart`

**Interfaces:**
- Consumes: `DownloadRepository.enqueue`, dashboard chapter keys, `NovelDetails.bestCover`, `ReadableChapter`.
- Produces: per-row action, persistent multi-page selection, selection action bar, and stable keys for UI tests.

- [ ] **Step 1: Write failing widget tests**

Assert:

```dart
expect(find.byKey(const ValueKey('chapter-download-public:1')), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('chapters-select-mode')));
await tester.tap(find.byKey(const ValueKey('chapter-select-public:1')));
expect(find.text('تم تحديد فصل واحد'), findsOneWidget);
await tester.tap(find.byKey(const ValueKey('chapters-download-selected')));
expect(fakeDownloads.lastEnqueuedChapterKeys, ['public:1']);
```

Also assert stored chapters show `تم التنزيل`, queued chapters show progress state, VIP is disabled without current eligibility, selection survives paging/search, and 200% text has no overflow.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/novel_details/chapter_download_actions_test.dart`

Expected: FAIL because actions are absent.

- [ ] **Step 3: Extend tiles without coupling to the repository**

Add presentation inputs `downloadState`, `selected`, `selectionMode`, `onDownload`, and `onToggleSelection`. Keep the chapter tap behavior separate. Use 44×44 download/select controls with Arabic tooltips and semantics.

- [ ] **Step 4: Build requests in the screens**

Create `DownloadNovelRequest` from `result.details.id/title/bestCover` and `DownloadChapterRequest` from `ReadableChapter.dedupeKey/id/label/contentApi/isVip`. Preserve a `Set<String>` across pages. Exclude stored and queued chapters from the count before enqueue.

- [ ] **Step 5: Verify existing chapter behavior and commit**

Run:

```powershell
flutter test test/features/novel_details/chapter_download_actions_test.dart
flutter test test/features/novel_details
```

Expected: PASS.

```powershell
git add lib/features/novel_details/presentation/all_chapters_screen.dart lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart lib/features/novel_details/presentation/widgets/novel_chapters_section.dart lib/features/novel_details/presentation/widgets/novel_chapter_tile.dart test/features/novel_details/chapter_download_actions_test.dart
git commit -m "feat(downloads): add chapter selection and queue actions"
```

### Task 9: Build the downloads screen, help sheet, and quota prompt

**Files:**
- Create: `lib/features/downloads/presentation/downloads_screen.dart`
- Create: `lib/features/downloads/presentation/downloads_help_sheet.dart`
- Create: `lib/features/downloads/presentation/download_quota_sheet.dart`
- Create: `lib/features/downloads/presentation/download_quota_prompt_host.dart`
- Create: `lib/features/downloads/presentation/widgets/download_allowance_strip.dart`
- Create: `lib/features/downloads/presentation/widgets/download_queue_section.dart`
- Create: `lib/features/downloads/presentation/widgets/downloaded_novel_group.dart`
- Modify: `lib/features/reader_journey/presentation/reader_journey_screen.dart`
- Modify: `lib/features/shell/presentation/app_shell.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Test: `test/features/downloads/downloads_screen_test.dart`
- Test: `test/features/downloads/downloads_accessibility_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `DownloadsDashboard`, repository commands, rewarded repository.
- Produces: enabled Journey destination, grouped management UI, manual help, and one automatic quota prompt per block generation.

- [ ] **Step 1: Write failing surface tests**

Assert keys `downloads-screen`, `downloads-help`, `downloads-allowance`, `download-queue-section`, `downloaded-novel-7`, `downloads-wifi-only`, and `download-storage-usage`. Tap help and assert the five approved numbered steps. Supply a blocked dashboard and assert reward amount and `متبقي 3 من 4 إعلانات اليوم`.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/downloads/downloads_screen_test.dart`

Expected: FAIL because the screen does not exist and Journey is disabled.

- [ ] **Step 3: Implement compact responsive screen**

Use one `CustomScrollView`: compact allowance strip, active queue section, then downloaded novels grouped by cover. Expansion shows chapter read/select/delete actions. Empty state says التنزيل يبدأ من قائمة فصول الرواية. Wi-Fi toggle calls `setWifiOnly` immediately.

- [ ] **Step 4: Implement sheets**

`DownloadsHelpSheet` is a scrollable half-height bottom sheet opened only by `downloads-help`. `DownloadQuotaSheet` shows current tier, `+rewardPerAd`, ads remaining, close, and watch button only when `allowance.canWatchRewardedAd`. On earned result call `grantReward(rewardEventId:)`; dismissed/unavailable does not mutate quota.

- [ ] **Step 5: Add app-wide automatic prompt host**

Wrap `MaterialApp.builder` child with `DownloadQuotaPromptHost`. Track `dashboard.quotaBlockGeneration`; show once when it increases while the app is resumed. Dismissing records that generation in memory. The explicit queue action can reopen the sheet.

- [ ] **Step 6: Enable Journey navigation**

Replace the disabled Journey button with `onOpenDownloads`. In `AppShell`, push `const DownloadsScreen()`. Remove «قريبًا» and unavailable semantics; preserve key `reader-journey-downloads`.

- [ ] **Step 7: Verify responsiveness and shell flow**

Test 320×720, 600×800, 840×900, 840×360, and 320×1100 at 200% text. Verify all controls are at least 44×44 and statuses are labeled independent of color.

Run:

```powershell
flutter test test/features/downloads/downloads_screen_test.dart test/features/downloads/downloads_accessibility_test.dart
flutter test test/widget_test.dart --plain-name "opens downloads from reader journey"
```

Expected: PASS.

- [ ] **Step 8: Commit**

```powershell
git add lib/features/downloads/presentation lib/features/reader_journey/presentation/reader_journey_screen.dart lib/features/shell/presentation/app_shell.dart lib/app/galaxy_novels_app.dart test/features/downloads/downloads_screen_test.dart test/features/downloads/downloads_accessibility_test.dart test/widget_test.dart
git commit -m "feat(downloads): add compact download management surfaces"
```

### Task 10: Integrate offline reading and enforce VIP locks

**Files:**
- Create: `lib/features/downloads/data/download_aware_reader_repository.dart`
- Modify: `lib/features/reader/presentation/reader_screen.dart`
- Modify: `lib/features/downloads/presentation/downloads_screen.dart`
- Modify: `lib/app/galaxy_novels_app.dart`
- Test: `test/features/downloads/download_aware_reader_repository_test.dart`
- Test: `test/features/downloads/downloads_offline_reader_integration_test.dart`

**Interfaces:**
- Consumes: `galaxy-download://chapter/<encoded-key>`, current auth state, encrypted/public file store.
- Produces: `ReaderChapterContent` with offline navigation between adjacent stored chapters and explicit VIP lock failures.

- [ ] **Step 1: Write failing repository tests**

Test public offline load without network; navigation maps only stored previous/next chapters to offline URIs; non-offline URI delegates exactly once; VIP opens before expiry; VIP locks after expiry, logout, or seven days without a dated verification; renewal reopens without rewriting the file.

- [ ] **Step 2: Run to verify RED**

Run: `flutter test test/features/downloads/download_aware_reader_repository_test.dart`

Expected: FAIL because the wrapper is absent.

- [ ] **Step 3: Implement wrapper and stable exceptions**

```dart
class DownloadVipLockedException implements Exception {
  const DownloadVipLockedException(this.reason);
  final DownloadVipLockReason reason;
}

class DownloadAwareReaderRepository implements ReaderRepository {
  const DownloadAwareReaderRepository({required this.online, required this.downloads});
  final ReaderRepository online;
  final DownloadRepository downloads;
  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) =>
      contentApi.startsWith('galaxy-download://')
          ? downloads.loadOffline(contentApi)
          : online.loadChapter(contentApi);
}
```

The stored repository replaces navigation only with adjacent downloaded chapters from the same novel; absent neighbors use empty APIs so offline reading never unexpectedly starts network traffic.

- [ ] **Step 4: Show a VIP-specific reader failure**

In `ReaderScreen`, map `DownloadVipLockedException` to title `فصل VIP مقفول`, a concise reason, and an action that opens the account screen. Keep generic network behavior for other errors.

- [ ] **Step 5: Wrap the default online repository and wire screen opens**

Construct `DownloadAwareReaderRepository(online: effectiveReaderRepository, downloads: effectiveDownloadRepository)` in app composition. Downloads screen opens `ReaderScreen` with `offlineChapterUri(chapterKey)`, stored title, novel title, and local/network cover path.

- [ ] **Step 6: Verify reader regression and commit**

Run:

```powershell
flutter test test/features/downloads/download_aware_reader_repository_test.dart test/features/downloads/downloads_offline_reader_integration_test.dart
flutter test test/features/reader
```

Expected: PASS.

```powershell
git add lib/features/downloads/data/download_aware_reader_repository.dart lib/features/downloads/presentation/downloads_screen.dart lib/features/reader/presentation/reader_screen.dart lib/app/galaxy_novels_app.dart test/features/downloads/download_aware_reader_repository_test.dart test/features/downloads/downloads_offline_reader_integration_test.dart
git commit -m "feat(downloads): read stored chapters with VIP access guards"
```

### Task 11: Complete visual, integration, device, and release verification

**Files:**
- Modify: `test/goldens/phase4_surfaces_golden_test.dart`
- Create: `test/goldens/goldens/phase4_downloads_galaxyNoir_320.png`
- Create: `test/goldens/goldens/phase4_downloads_galaxyNoir_600.png`
- Create: `test/goldens/goldens/phase4_downloads_galaxyNoir_840.png`
- Create: `test/goldens/goldens/phase4_downloads_starlightPaper_320.png`
- Create: `test/goldens/goldens/phase4_downloads_starlightPaper_600.png`
- Create: `test/goldens/goldens/phase4_downloads_starlightPaper_840.png`
- Create: `integration_test/downloads_flow_test.dart`
- Modify: `docs/manual_test_plan.md`
- Modify: `docs/app_api_gap_audit.md`

**Interfaces:**
- Consumes: completed feature and Google rewarded test unit.
- Produces: six approved baselines, automated end-to-end coverage, device checklist, final APK.

- [ ] **Step 1: Add deterministic golden fixture**

Render a dashboard with one 3/5 active group, one waiting-for-quota group, and two novels with covers, counts, byte sizes, and one locked VIP chapter. Disable network image variability by supplying test image providers.

- [ ] **Step 2: Generate and inspect goldens**

Run:

```powershell
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name downloads --update-goldens
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name downloads
```

Expected: six goldens generated then PASS. Inspect all six for clipping, order, cover proportions, and Stitch dark colors.

- [ ] **Step 3: Add integration flow**

The integration test uses a local fake HTTP server and test repositories to select three chapters, complete two concurrent transfers, verify three charges only after saved files exist, exhaust a one-credit fixture, grant one fake rewarded event, resume the remaining chapter, kill/recreate the repository, and open the stored chapter with network disabled.

- [ ] **Step 4: Update manual and API audit documentation**

Document exact Android checks: notification permission, Wi-Fi-only transition, background transfer, swipe-away/reopen, force-stop limitation, midnight resume, ad complete/dismiss/fail, all five tier plans, storage-full behavior, logout/expiry/renewal for VIP, and data-clear limitation. Record that no new server endpoint is used and counters remain local.

- [ ] **Step 5: Run the full verification matrix**

```powershell
dart format lib test integration_test
flutter test test/features/downloads
flutter test test/features/ads
flutter test test/features/novel_details
flutter test test/features/reader
flutter test test/widget_test.dart
flutter test test/goldens/phase4_surfaces_golden_test.dart --plain-name downloads
flutter analyze
git diff --check
flutter build apk --debug
```

Expected: all tests PASS, no analyzer issues, no whitespace errors, APK at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 6: Perform USB device checks**

Install the debug APK, keep Google test rewarded ID, and verify the manual matrix. Capture `adb logcat` filtered to app process during one successful and one interrupted background group. Confirm logs contain no access tokens, response bodies, or decrypted VIP text.

- [ ] **Step 7: Final commit**

```powershell
git add test/goldens integration_test/downloads_flow_test.dart docs/manual_test_plan.md docs/app_api_gap_audit.md
git commit -m "test(downloads): verify rewarded offline download flow"
```

## Primary References

- Google rewarded Flutter lifecycle and test ID: <https://developers.google.com/admob/flutter/rewarded>
- background_downloader 9.5.6 setup and limits: <https://pub.dev/packages/background_downloader>
- background_downloader notification contract: <https://github.com/781flyingdutchman/background_downloader/blob/main/doc/notifications.md>
- background_downloader foreground and holding-queue config: <https://github.com/781flyingdutchman/background_downloader/blob/main/doc/CONFIG.md>
- Workmanager background isolate contract: <https://docs.page/fluttercommunity/flutter_workmanager/quickstart>
- sqflite transactions and supported storage types: <https://pub.dev/packages/sqflite>
- cryptography/cryptography_flutter AES-GCM implementation: <https://pub.dev/packages/cryptography_flutter>
