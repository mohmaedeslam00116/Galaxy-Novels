# تقرير مراجعة Crashlytics وإصلاح أعطال الإنتاج

**التاريخ:** 20 أغسطس 2026  
**مشروع Firebase:** `galaxy-novels-app-4720`  
**تطبيق Android:** `com.galaxynovels.app`  
**الإصدار الذي ظهرت فيه كل المشكلات:** `3.2.1`

## الخلاصة التنفيذية

- أُعيد الاستعلام عن تقرير `topIssues` حتى `2026-08-20 14:17 UTC` عبر واجهة Crashlytics التي يستخدمها Firebase CLI، مع تضمين الأنواع الثلاثة `FATAL` و`NON_FATAL` و`ANR`، خلال آخر 89 يومًا (ضمن الحد الأقصى البالغ 90 يومًا).
- النتيجة: **15 Issue مفتوحة، كلها FATAL، بإجمالي 903 أحداث**. لم يعرض التقرير Issue إضافية من نوع Non-fatal أو ANR.
- عولجت الأسباب الجذرية الخمسة: سباقات دورة الحياة، ملكية قاعدة التنزيلات، callbacks مرتبطة بشاشات منتهية، lookup غير آمن لتنزيل قديم، وحذف ملف مؤقت بصورة غير idempotent.
- أضيفت سياسة شدة تجعل أخطاء الاتصال والمهلة والأخطاء المؤقتة المعرّفة صراحة Non-fatal، مع إبقاء أخطاء البرمجة والتخزين غير المتوقعة Fatal.
- لم تُغلق Issues من Firebase؛ مصدرها الإصدار المنشور القديم، ولا يصح إغلاقها قبل نشر بناء جديد ومراقبته.

> عدد المستخدمين أدناه خاص بكل Issue على حدة، وقد يكون المستخدم نفسه موجودًا في أكثر من صف.

## نتيجة كل Issue

| # | Issue | الأحداث / المستخدمون | السبب الجذري | المعالجة في المصدر |
|---:|---|---:|---|---|
| 1 | [527705a8247008eec1408bffb816afc9](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/527705a8247008eec1408bffb816afc9) | 375 / 25 | مؤقت auto-scroll يعمل بعد التخلص من Reader والاعتماد على controller منتهي | إلغاء المؤقت، تتبع حالة التخلص، ومنع الاستئناف/الإيقاف بعد unmount |
| 2 | [f8143afd8a95405e9a4014cae2924109](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/f8143afd8a95405e9a4014cae2924109) | 218 / 19 | العامل الخلفي والواجهة يشتركان في اتصال sqflite يمكن أن يغلقه العامل | اتصال مستقل للعامل `singleInstance: false` وانتظار shutdown قبل إغلاق المتجر |
| 3 | [7df752985bbaa29a93a8fb72436cf43d](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/7df752985bbaa29a93a8fb72436cf43d) | 132 / 3 | حالة تنزيل غير متاحة متوقعة سُجلت كعطل قاتل | تعريفها كـ `AppRecoverableException` وتسجيلها Non-fatal |
| 4 | [a80bb0bc530e23d3a8e7ca7ca9048f86](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/a80bb0bc530e23d3a8e7ca7ca9048f86) | 65 / 8 | فشل DNS/الاتصال سُجل Fatal | تصنيف `SocketException` كتشخيص Non-fatal |
| 5 | [dc4bb639c79d17aede14bea16f8f24a8](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/dc4bb639c79d17aede14bea16f8f24a8) | 42 / 10 | Connection reset مؤقت سُجل Fatal | تصنيف خطأ socket كـ Non-fatal مع الاحتفاظ بالتشخيص |
| 6 | [3c1422171b61809b672644f556778324](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/3c1422171b61809b672644f556778324) | 28 / 7 | ضغطات سريعة تبدأ انتقالات PageController متداخلة في onboarding | تسلسل `_goTo` ومنع بدء انتقال ثانٍ قبل انتهاء الأول |
| 7 | [82f00f438684897c50981847fb9e21c2](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/82f00f438684897c50981847fb9e21c2) | 17 / 12 | Snackbar callback يرجع إلى `AppDependencies.of` عبر context لشاشة منتهية | التقاط dependencies وNavigator والRoute الدائمة قبل العملية غير المتزامنة |
| 8 | [8ed8a0a8b4dcb269538fa6125874b92b](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/8ed8a0a8b4dcb269538fa6125874b92b) | 7 / 3 | إجراء Snackbar في تخصيص المكتبة يستخدم context منتهي | استخدام NavigatorState صالح تم التقاطه قبل إغلاق الشاشة |
| 9 | [9d883f9ab08989f28d898296d6e62cfd](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/9d883f9ab08989f28d898296d6e62cfd) | 5 / 5 | إجراء معاينة تخصيص الرئيسية يبقى ظاهرًا بعد التخلص من controller الذي يحتاجه | الاحتفاظ بمتحكم Snackbar وإغلاق الرسالة نفسها عند `dispose` |
| 10 | [0f3a554c1821314b7d187ddd530a0a63](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/0f3a554c1821314b7d187ddd530a0a63) | 4 / 4 | إجراء فتح الحساب يستخدم context لشاشة تفاصيل منتهية | التقاط NavigatorState واستخدام helper لا يعتمد على State المتخلص منه |
| 11 | [33f92adfd647a9ac3fffac5e09ec4766](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/33f92adfd647a9ac3fffac5e09ec4766) | 3 / 3 | انقطاع HTTP أثناء استقبال صورة سُجل Fatal | تصنيف `HttpException` كـ Non-fatal |
| 12 | [54b02f4fde610589cce20880dcf6ed49](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/54b02f4fde610589cce20880dcf6ed49) | 3 / 1 | فشل DNS في public cache سُجل Fatal | تصنيفه كـ Non-fatal مع استمرار cache fallback |
| 13 | [c237529e447c4e865e31a86678258765](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/c237529e447c4e865e31a86678258765) | 2 / 1 | `firstWhere` يفشل بـ `StateError` عند URI قديم لم يعد ضمن snapshot | lookup صريح وتحويل الحالة إلى `DownloadUnavailableException` typed |
| 14 | [09556dad266456d6c1e174e924980c69](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/09556dad266456d6c1e174e924980c69) | 1 / 1 | مهلة الشبكة المتوقعة سُجلت Fatal | تصنيف `TimeoutException` كـ Non-fatal |
| 15 | [b3cb06b63df032e098aab1c8fc6291e3](https://console.firebase.google.com/v1/appid/project/galaxy-novels-app-4720/crashlytics/app/1:184724821028:android:e5f4c4333e1e28b20ff4b1/issues/b3cb06b63df032e098aab1c8fc6291e3) | 1 / 1 | محاولتان قد تحذفان ملف النقل المؤقت نفسه | عملية حذف idempotent تتجاهل `PathNotFoundException` فقط في مساري الإنهاء |

## مراجعة جودة الإصلاح

وجدت المراجعة المستقلة أربع نقاط إضافية وأُغلقت قبل الاعتماد:

1. انتظار `StoredDownloadRepository.shutdown()` قبل `dispose` وإغلاق قاعدة العامل الخلفي.
2. ضمان تنفيذ `dispose` و`close` داخل `finally` متداخل حتى إذا فشل `shutdown` نفسه، مع اختبار سلوكي لمسار الفشل.
3. تضييق أخطاء I/O غير القاتلة إلى `SocketException` و`HttpException` فقط؛ `FileSystemException` غير المتوقع يظل Fatal.
4. إزالة Snackbar معاينة الرئيسية عند التخلص من الشاشة بدل ترك إجراء ظاهر بلا مفعول.

## التحقق

- اختبارات التنزيلات المركزة بعد آخر ملاحظة مراجعة: **24/24 ناجحة**.
- حزمة الاختبارات الكاملة غير الذهبية: **1222/1222 ناجحة**.
- `flutter analyze`: **No issues found**.
- بناء Android Release App Bundle: **ناجح**، الملف `build/app/outputs/bundle/release/app-release.aab` بحجم **60.6MB**، وبصمة SHA-256: `37D9411EB518B3B79CCB9F5E57B6E6EB00F008DF3ADB09E3C38FAF98B824F69D`.
- فُعّلت خدمة `firebasecrashlytics.googleapis.com` للمشروع حتى يمكن تنفيذ المراجعة عبر API؛ لم تُفعّل خدمات Firebase أخرى.

## ما يتبقى قبل الإغلاق في Firebase

1. البناء الحالي يحمل `3.2.1+5`. يجب اختيار رقم build جديد غير مستخدم في Google Play قبل الرفع؛ ملف AAB الحالي هو ناتج تحقق وليس نشرًا على المتجر.
2. نشر الإصلاح في مسار اختبار ثم Production.
3. مراقبة الإصدار الجديد في Crashlytics مدة 24–72 ساعة، مع التفريق بين أحداث مستخدمي 3.2.1 القديمة وأحداث الإصدار الجديد.
4. إغلاق كل Issue فقط بعد التأكد من عدم ظهورها في الإصدار الجديد. لم يُنفذ رفع إلى Play Console ولم تُعدّل حالة Issues عن `OPEN` في هذه المراجعة.
