# توثيق ربط تطبيق مجرة الروايات مع موقع Wor Reader

هذا الملف يوثق آلية الربط التي يجب أن يبنى عليها تطبيق Flutter العربي لتطبيق **مجرة الروايات / Galaxy Novels**.

القاعدة الأساسية: التطبيق لا يعتمد على REST API للبيانات العامة. التصفح العام يأتي من ملفات JSON ثابتة مكاشاة عبر Cloudflare، والـ REST يستخدم فقط للبيانات الخاصة أو العمليات التي تحتاج مستخدمًا مسجلًا.

## مصادر الفحص

- `message.txt`
- `قواعد كلود فلير`
- `wor-reader-v2470-app-cache-api.zip`
- داخل القالب:
  - `docs/v2470-app-cache-api.md`
  - `inc/app-cache.php`
  - `inc/app-api.php`
  - `inc/chapter-index.php`
  - `inc/novel-search-index.php`
  - `inc/vip-release-schedule.php`
  - `inc/reading-ledger.php`
  - `inc/activity.php`
  - `single-wor_chapter.php`

## فلسفة الربط

يوجد مساران منفصلان:

1. مسار عام مكاشى:
   - الرئيسية.
   - البحث.
   - المكتبة والفهرسة.
   - ترتيب الروايات.
   - بيانات الرواية العامة.
   - فهرس الفصول العامة.
   - مواعيد نزول فصول VIP للعامة.
   - إعدادات المتجر العامة.

2. مسار خاص عبر REST:
   - تسجيل الدخول والجلسة.
   - بيانات المستخدم.
   - المفضلة.
   - سجل القراءة.
   - مزامنة نشاط القراءة و XP.
   - تقييمات المستخدم.
   - إنشاء التعليقات والتصويت والتفاعلات.
   - فصول VIP الفعلية.
   - عمليات الاشتراك والدفع.

الهدف العملي أن يكون 80 إلى 90 بالمئة من التصفح من Cloudflare وكاش الهاتف، وأن تصل للسيرفر فقط عمليات المستخدم الخاصة والمجمعة.

## Bootstrap

أول طلب عام للتطبيق:

```text
GET /wp-content/uploads/wor-reader-cache/app/manifest/bootstrap.json
```

الـ manifest يحتوي عادة:

```json
{
  "schema": 1,
  "generated": 1710000000,
  "version": "hash",
  "pack": "/wp-content/uploads/wor-reader-cache/app/packs/bootstrap-hash.json"
}
```

بعد ذلك يحمّل التطبيق قيمة `pack`. داخل pack تكون البيانات تحت `data`:

```json
{
  "schema": 1,
  "generated": 1710000000,
  "data": {
    "site": {
      "name": "اسم الموقع",
      "url": "https://example.com/",
      "locale": "ar",
      "rtl": true
    },
    "api": {
      "base": "https://example.com/wp-json/wor-reader-app/v1",
      "legacy_base": "https://example.com/wp-json/wor-reader/v1"
    },
    "public": {
      "search_manifest": "/wp-content/uploads/wor-reader-cache/search/manifest.json",
      "home_manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/home.json",
      "catalog_manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/catalog.json",
      "rankings_manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/rankings.json",
      "store_manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/store.json"
    },
    "features": {
      "vip": true,
      "comments": true,
      "ratings": true,
      "xp": true,
      "translator_awards": true,
      "html_app_reader": true
    },
    "limits": {
      "reading_sync_interval_seconds": 180,
      "reading_sync_max_items": 50,
      "favorites_sync_max_changes": 50,
      "comments_page_size": 20
    }
  }
}
```

في Flutter يجب بناء خدمة `BootstrapService` تقوم بتحميل manifest ثم pack، وتحفظ روابط `api.base` وملفات `public`.

## نمط manifest و pack

معظم الملفات العامة تعمل بنمط:

1. افتح manifest صغير.
2. اقرأ منه رابط pack أو packs.
3. حمّل pack ذي اسم versioned.
4. احفظ pack محليًا حسب `version` أو اسم الملف.

قواعد الكاش:

- manifest: قصير العمر، ويجب إعادة فحصه دوريًا.
- pack: طويل العمر، آمن للكاش لأن الاسم يتغير عند تحديث المحتوى.

لا تفترض أن كل JSON في الموقع عام. المسارات الآمنة فقط هي الموجودة داخل:

```text
/wp-content/uploads/wor-reader-cache/search/
/wp-content/uploads/wor-reader-cache/chapters/manifest/
/wp-content/uploads/wor-reader-cache/chapters/packs/
/wp-content/uploads/wor-reader-cache/vip-schedule/manifest/
/wp-content/uploads/wor-reader-cache/vip-schedule/packs/
/wp-content/uploads/wor-reader-cache/app/manifest/
/wp-content/uploads/wor-reader-cache/app/packs/
```

## الرئيسية

من bootstrap استخدم:

```text
public.home_manifest
```

ثم حمّل pack. البيانات تكون تحت `data`:

```json
{
  "latest_chapters": [],
  "recent_novels": [],
  "links": {
    "catalog_manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/catalog.json",
    "rankings_manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/rankings.json"
  }
}
```

## المكتبة Catalog

من bootstrap استخدم:

```text
public.catalog_manifest
```

الـ manifest الخاص بالمكتبة يحتوي:

```json
{
  "schema": 1,
  "generated": 1710000000,
  "version": "hash",
  "count": 1200,
  "part_size": 500,
  "packs": [
    "/wp-content/uploads/wor-reader-cache/app/packs/catalog-part-1-hash.json"
  ]
}
```

كل pack يحتوي:

```json
{
  "schema": 1,
  "generated": 1710000000,
  "part": 1,
  "total_parts": 3,
  "items": []
}
```

كل عنصر رواية مختصر:

```json
{
  "id": 123,
  "title": "اسم الرواية",
  "original_title": "Original Title",
  "url": "/novel/example/",
  "cover": {
    "thumbnail": "/wp-content/uploads/...",
    "medium": "/wp-content/uploads/..."
  },
  "status": {
    "key": "ongoing",
    "label": "مستمرة"
  },
  "country": "",
  "author": "",
  "translator": "",
  "genres": [
    {
      "id": 1,
      "name": "أكشن",
      "slug": "action",
      "url": "/novel-genre/action/"
    }
  ],
  "chapters_count": 120,
  "first_chapter_id": 555,
  "first_chapter_url": "/novel/example/chapter-1/",
  "rating": {
    "average": 4.5,
    "count": 30
  },
  "stats": {
    "views": 10000
  },
  "updated_at": "2026-06-18T10:00:00+00:00",
  "manifest": "/wp-content/uploads/wor-reader-cache/app/manifest/novel-123.json"
}
```

الفلترة والترتيب والبحث داخل المكتبة يجب أن تتم محليًا قدر الإمكان بعد تحميل packs.

## البحث

من bootstrap استخدم:

```text
public.search_manifest
```

الـ manifest:

```json
{
  "version": 1,
  "generated": 1710000000,
  "count": 1200,
  "index": "https://example.com/wp-content/uploads/wor-reader-cache/search/novels-hash.json"
}
```

الـ index pack:

```json
{
  "v": 1,
  "generated": 1710000000,
  "items": [
    {
      "id": 123,
      "t": "العنوان",
      "o": "العنوان الأصلي",
      "u": "/novel/example/",
      "c": "/wp-content/uploads/cover.jpg",
      "g": ["أكشن", "خيال"],
      "n": 120,
      "st": "مستمرة",
      "r": 123456,
      "s": "نص بحث مطبع"
    }
  ]
}
```

الحقل `s` جاهز للبحث المحلي بعد تطبيع عربي مشابه:

- تحويل `أ/إ/آ/ٱ` إلى `ا`.
- تحويل `ى/ئ` إلى `ي`.
- تحويل `ؤ` إلى `و`.
- تحويل `ة` إلى `ه`.
- حذف التشكيل والتطويل.
- تحويل النص إلى lowercase.
- استبدال غير الحروف والأرقام بمسافات.

ممنوع استخدام REST أو `/?s=` للبحث أثناء الكتابة.

## صفحة الرواية

من عنصر catalog اقرأ الحقل:

```text
manifest
```

ثم افتح manifest و pack للرواية. بيانات الرواية الكاملة تكون تحت `data`، وتزيد عن المختصر بهذه الحقول:

```json
{
  "summary": "ملخص الرواية",
  "cover": {
    "thumbnail": "...",
    "medium": "...",
    "large": "..."
  },
  "links": {
    "chapters_manifest": "/wp-content/uploads/wor-reader-cache/chapters/manifest/novel-123.json",
    "vip_schedule_manifest": "/wp-content/uploads/wor-reader-cache/vip-schedule/manifest/novel-123.json"
  }
}
```

لإظهار حالة المستخدم داخل صفحة الرواية، لا تضعها في الملف العام. بعد تسجيل الدخول اطلب:

```text
GET /wp-json/wor-reader-app/v1/me/novels/{novel_id}
```

يرجع:

```json
{
  "novel_id": 123,
  "favorite": true,
  "my_rating": 4,
  "last_read": {
    "chapter_id": 555,
    "chapter_url": "/novel/example/chapter-1/",
    "progress": 96,
    "updated_at": "2026-06-18T10:00:00+00:00"
  },
  "vip": {
    "active": true,
    "can_read_private": true
  }
}
```

## فهرس الفصول العامة

من pack الرواية استخدم:

```text
data.links.chapters_manifest
```

أو المسار المعروف:

```text
/wp-content/uploads/wor-reader-cache/chapters/manifest/novel-ID.json
```

الـ manifest يشير إلى pack فصول عام. الـ pack يحتوي فصولًا منشورة عامة فقط، مثل:

```json
[
  {
    "id": 555,
    "position": 1,
    "number": "1",
    "label": "الفصل 1",
    "title": "عنوان فرعي",
    "url": "https://example.com/novel/example/chapter-1/",
    "date": "18 يونيو 2026",
    "date_iso": "2026-06-18T10:00:00+00:00",
    "views": 0,
    "comments": 0,
    "search": "1 الفصل 1 عنوان الفصل"
  }
]
```

لا تطلب REST لفهرس الفصول العامة. البحث داخل قائمة الفصول يتم محليًا باستخدام `number`, `label`, `title`, `search`.

## قراءة الفصل العام

محتوى الفصل العام لا يأتي من JSON.

افتح الفصل كرابط HTML خفيف:

```text
/novel/.../chapter-.../?wr_app_reader=1
```

القالب يعرض صفحة HTML صغيرة RTL بدون هيدر وفوتر الموقع. الصفحة تحتوي:

- `data-wor-app-reader="1"`
- `data-chapter-id`
- `data-novel-id`
- `data-position`
- `data-total`
- روابط السابق والتالي.

تطبيق Flutter يمكنه عرض هذه الصفحة داخل WebView أو تحميل HTML للعرض، لكن الأفضل عمليًا أن تفتح كرابط document داخل WebView لأن قواعد WAF تتعامل بحذر مع طلبات الفصول غير الشبيهة بالمتصفح.

ممنوع:

- جلب محتوى كل الفصول مسبقًا.
- prefetch جماعي للفصول.
- فتح أكثر من فصل أو فصلين مسبقًا.
- تخزين محتوى VIP لمدة طويلة.

## مواعيد نزول VIP العامة

من pack الرواية استخدم:

```text
data.links.vip_schedule_manifest
```

الـ manifest يحتوي:

```json
{
  "schema": 1,
  "novel_id": 123,
  "version": "hash",
  "total": 5,
  "generated": 1710000000,
  "pack": "novel-123-hash.json",
  "pack_url": "https://example.com/wp-content/uploads/wor-reader-cache/vip-schedule/packs/novel-123-hash.json"
}
```

الـ pack يحتوي:

```json
{
  "schema": 1,
  "novel_id": 123,
  "generated": 1710000000,
  "version": "hash",
  "items": [
    {
      "number": "121",
      "position": 121,
      "order": "121.000000",
      "public_at": "2026-06-20T20:00:00Z"
    }
  ],
  "total": 1
}
```

هذه البيانات عامة فقط. لا تحتوي روابط فصول VIP ولا محتواها ولا صلاحيات المستخدم.

## الترتيب Rankings

من bootstrap استخدم:

```text
public.rankings_manifest
```

الـ pack يحتوي:

```json
{
  "period": "month",
  "items": []
}
```

العناصر بنفس شكل رواية catalog المختصرة.

## المتجر Store

من bootstrap استخدم:

```text
public.store_manifest
```

الـ pack يحتوي إعدادات عامة وخطط الاشتراك، وفيه:

```json
{
  "enabled": true,
  "plans": [],
  "restBase": "https://example.com/wp-json/wor-reader-app/v1/store"
}
```

عمليات الدفع نفسها تتم عبر REST الخاص ولا تكاشى.

## REST الخاص

الـ base من bootstrap:

```text
/wp-json/wor-reader-app/v1
```

كل ردود هذا namespace تضبط `Cache-Control: no-store`.

## الجلسة وتسجيل الدخول

تسجيل الدخول:

```text
POST /auth/login
```

Body:

```json
{
  "username": "user",
  "password": "password",
  "remember": true
}
```

الرد:

```json
{
  "logged_in": true,
  "nonce": "wp-rest-nonce",
  "user": {
    "id": 1,
    "display_name": "الاسم",
    "avatar": "https://...",
    "vip": {
      "active": false,
      "tier": "",
      "label": "",
      "expires_at": ""
    },
    "xp": {
      "total": 0,
      "today": 0,
      "seconds_total": 0,
      "chapters_total": 0,
      "rank": {}
    }
  }
}
```

مهم:

- احتفظ بالكوكيز التي يرجعها WordPress.
- احتفظ بالـ `nonce`.
- أرسل في كل طلب خاص:

```text
X-WP-Nonce: <nonce>
```

فحص الجلسة:

```text
GET /session
```

إذا كان المستخدم مسجلًا يرجع `nonce` جديدًا. استخدمه لتحديث nonce المحلي.

تسجيل الخروج:

```text
POST /auth/logout
```

يتطلب كوكيز و `X-WP-Nonce`.

## قائمة endpoints الخاصة

```text
POST /auth/login
POST /auth/logout
GET  /session
GET  /me
GET  /me/novels/{novel_id}
GET  /me/favorites
POST /me/favorites/sync
GET  /me/history
GET  /me/history/novel/{novel_id}
POST /reading/sync
GET  /ratings/novel/{novel_id}
POST /ratings/novel/{novel_id}
GET  /comments/{novel|chapter}/{id}
POST /comments/{novel|chapter}/{id}
POST /comments/{comment_id}/vote
POST /comments/{novel|chapter}/{id}/reaction
GET  /vip/chapters?novel_id=ID
GET  /vip/continuous-next?chapter_id=ID
POST /vip/library-counts
POST /store/create-order
POST /store/capture-order
POST /store/create-subscription
POST /store/activate-subscription
POST /store/cancel-subscription
POST /translator-awards/vote
```

ملاحظة: ملف `message.txt` يذكر أهم endpoints، والكود يضيف أيضًا `POST /vip/library-counts`.

## المفضلة

قراءة المفضلة:

```text
GET /me/favorites
```

مزامنة تغييرات المفضلة:

```text
POST /me/favorites/sync
```

يجب أن تكون المزامنة مجمعة وليست طلبًا لكل نقرة إذا كان المستخدم يعمل offline أو لديه عدة تغييرات.

## سجل القراءة

قراءة السجل العام للمستخدم:

```text
GET /me/history
```

قراءة سجل رواية معينة:

```text
GET /me/history/novel/{novel_id}
```

استخدم هذا عند فتح صفحة رواية لمزامنة آخر فصل ونسب القراءة.

## مزامنة القراءة و XP

لا يرسل التطبيق XP جاهزًا. التطبيق يرسل نشاط قراءة فقط، والسيرفر يحسب XP.

Endpoint:

```text
POST /reading/sync
```

Body:

```json
{
  "items": [
    {
      "event_id": "uuid",
      "object_type": "chapter",
      "object_id": 555,
      "parent_id": 123,
      "active_seconds": 180,
      "open_seconds": 420,
      "progress": 96,
      "completed": true,
      "read_at": "2026-06-18T20:00:00Z"
    }
  ],
  "final": false
}
```

حدود السيرفر:

- الحد الأقصى 50 عنصرًا في الطلب.
- `active_seconds` أو `reading_seconds` يقص إلى 300 ثانية لكل عنصر.
- `open_seconds` يقص إلى 900 ثانية لكل عنصر.
- `progress` من 0 إلى 100.
- يعتبر الفصل مكتملًا إذا `completed = true` أو `progress >= 92`.
- `event_id` يمنع التكرار، ويجب أن يكون ثابتًا لكل حدث مرسل.
- إذا `final` غير موجودة أو false يوجد rate limit تقريبي 20 ثانية للمستخدم.

سياسة التطبيق:

- أرسل كل 3 دقائق حسب bootstrap أو عند الوصول للحد.
- أرسل عند إغلاق الفصل.
- أرسل عند اكتمال الفصل.
- لا ترسل كل ثانية ولا كل scroll.
- خزّن أحداث القراءة محليًا إذا انقطع الاتصال، ثم أرسلها على دفعات.

## التقييمات

قراءة تقييم المستخدم:

```text
GET /ratings/novel/{novel_id}
```

إرسال تقييم:

```text
POST /ratings/novel/{novel_id}
```

تحتاج تسجيل دخول و nonce.

## التعليقات والتفاعلات

قراءة التعليقات عامة:

```text
GET /comments/{novel|chapter}/{id}?page=1&sort=newest
```

إنشاء تعليق:

```text
POST /comments/{novel|chapter}/{id}
```

Body:

```json
{
  "content": "نص التعليق",
  "parent_id": 0,
  "is_spoiler": false
}
```

تصويت على تعليق:

```text
POST /comments/{comment_id}/vote
```

تفاعل على رواية أو فصل:

```text
POST /comments/{novel|chapter}/{id}/reaction
```

## VIP

فهرس مواعيد VIP العام يأتي من ملفات `vip-schedule` ولا يكشف محتوى خاص.

أما فصول VIP الفعلية فتأتي من REST خاص:

```text
GET /vip/chapters?novel_id=ID&cursor_order=&cursor_id=0&limit=100&order=asc&search=
```

الصلاحيات على السيرفر:

- المستخدم يجب أن يكون مسجلًا.
- المستخدم يجب أن يكون مديرًا/محررًا أو لديه اشتراك VIP فعال.
- التطبيق لا يقرر صلاحية VIP محليًا.

الفصل التالي في قراءة VIP المتواصلة:

```text
GET /vip/continuous-next?chapter_id=ID
```

يرجع HTML خاصًا للفصل التالي المتاح، ولا يجب كاشه طويلًا.

## الدفع والاشتراكات

كل العمليات خاصة وتحتاج جلسة:

```text
POST /store/create-order
POST /store/capture-order
POST /store/create-subscription
POST /store/activate-subscription
POST /store/cancel-subscription
```

الحقول الأساسية التي تظهر في الكود:

- `tier`
- `duration`
- `paypal_order_id`
- `order_key`
- `subscription_id`

تفاصيل تجربة الدفع في Flutter تحتاج مراجعة لاحقة حسب بوابة الدفع المعتمدة في التطبيق.

## User-Agent و WAF

لا تستخدم User-Agent الافتراضي لـ Flutter أو Dart أو OkHttp لأن قواعد Cloudflare قد تتحدى هذه العملاء.

استخدم:

```text
WorReaderApp/1.0 Android
```

أو:

```text
WorReaderApp/1.0 iOS
```

يفضل توحيد هذا الهيدر في كل طلبات HTTP و WebView.

طلبات REST الخاصة يجب أن تتجنب الكاش، وأن ترسل:

```text
Accept: application/json
Content-Type: application/json
X-WP-Nonce: <nonce>
User-Agent: WorReaderApp/1.0 Android
```

طلبات الملفات العامة يمكنها استخدام:

```text
Accept: application/json
User-Agent: WorReaderApp/1.0 Android
```

## تصميم خدمات Flutter المقترح لاحقًا

يفضل تقسيم الربط إلى طبقات:

- `ApiClient`
  - Dio أو http client.
  - Cookie jar.
  - User-Agent ثابت.
  - إضافة nonce تلقائيًا للطلبات الخاصة.
  - تحويل الروابط النسبية إلى مطلقة باستخدام `site.url`.

- `PublicCacheClient`
  - تحميل manifest ثم pack.
  - حفظ manifest خفيفًا مع وقت آخر فحص.
  - حفظ packs حسب URL/version.
  - عدم استخدام REST للبيانات العامة.

- `BootstrapRepository`
  - تحميل bootstrap عند تشغيل التطبيق.
  - حفظ `api.base` و public manifests.

- `CatalogRepository`
  - تحميل packs المكتبة.
  - فلاتر وترتيب وبحث محلي.

- `SearchRepository`
  - تحميل search index.
  - تطبيع عربي محلي.
  - اقتراحات بدون API.

- `NovelRepository`
  - تحميل pack رواية.
  - تحميل فهرس فصول الرواية.
  - دمج بيانات المستخدم من `/me/novels/{id}` عند تسجيل الدخول.

- `ReaderRepository`
  - فتح الفصل العام كرابط `?wr_app_reader=1`.
  - تتبع القراءة محليًا.
  - إرسال `/reading/sync` على دفعات.

- `AuthRepository`
  - login/session/logout.
  - حفظ cookies و nonce.
  - تحديث nonce من `/session`.

- `UserRepository`
  - me/favorites/history/ratings/comments.

- `VipRepository`
  - فصول VIP الخاصة.
  - عدم تخزين محتوى VIP طويلًا.

- `StoreRepository`
  - خطط عامة من store pack.
  - عمليات الدفع من REST الخاص.

## سياسة الكاش داخل التطبيق

اقتراح عملي:

- bootstrap manifest: افحصه عند تشغيل التطبيق وبعد مدة قصيرة.
- home/rankings/store manifests: افحصها عند فتح الشاشة أو بعد مدة متوسطة.
- catalog manifest: افحصه عند تشغيل التطبيق، وحمل packs الجديدة فقط إذا تغير `version`.
- search manifest: افحصه عند تشغيل التطبيق أو عند فتح البحث.
- novel manifest: افحصه عند فتح صفحة الرواية.
- chapter manifest: افحصه عند فتح قائمة الفصول.
- packs: احفظها حسب URL أو version ولا تعيد تحميلها إذا موجودة وسليمة.

عند فشل الشبكة:

- استخدم آخر pack محفوظ للبيانات العامة.
- لا تعرض بيانات خاصة قديمة كأنها مؤكدة؛ وضح داخل الحالة أن الجلسة تحتاج تحديثًا.
- احتفظ بأحداث القراءة والمفضلة محليًا حتى تعود الشبكة.

## ممنوعات مهمة

- لا تطلب `/wp-json/` للبحث أو المكتبة أو فهرس الفصول العامة.
- لا تستخدم REST لجلب صفحة الرواية العامة إذا كان pack متاحًا.
- لا تجلب محتوى الفصل العام من JSON.
- لا تعتمد على التطبيق لتحديد صلاحية VIP.
- لا ترسل XP جاهزًا.
- لا تحفظ محتوى VIP لمدة طويلة.
- لا تعمل prefetch جماعي للفصول.
- لا تفتح أكثر من فصل أو فصلين مسبقًا.
- لا تستخدم User-Agent الافتراضي لـ Flutter/Dart/OkHttp.
- لا تضف أي افتراض أن ملفات JSON خارج `wor-reader-cache` آمنة للكاش.

## أسئلة تحتاج حسم قبل التنفيذ

- رابط الدومين النهائي الذي سيستخدمه التطبيق.
- هل قراءة الفصل العام ستكون WebView كاملة أم عارض HTML داخلي بعد تحميل الصفحة؟
- طريقة الدفع داخل التطبيق: PayPal Web flow، WebView، أو بوابة native لاحقًا.
- سياسة مدة الاحتفاظ بمحتوى الفصول العامة offline.
- هل يحتاج التطبيق دعم iOS من البداية أم Android فقط؟

