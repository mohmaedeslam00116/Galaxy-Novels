# مجرة الروايات

تطبيق Flutter عربي لقراءة روايات `galaxynovels.com` بواجهة Native وقارئ فصول دون WebView. يدعم الحسابات والمفضلة المتزامنة، ويدمج أحدث موضع قراءة محلي مع سجل الحساب، ويحفظ نشاط القراءة ويرسله عند عودة الاتصال.

## التشغيل

```bash
flutter pub get
flutter run
```

## التحقق

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## متطلبات المنصات

- Android 7.0 (API 24) أو أحدث، وهو الحد الافتراضي في Flutter 3.41 المستخدم لبناء المشروع.
- Android Backup معطل حتى لا تنتقل البيانات المشفرة دون مفاتيحها.
- مشروع iOS مجهز بملفات Keychain entitlements، ويستهدف iOS 13 أو أحدث.

## حالة الـ API

راجع [تدقيق التطبيق والـ API](docs/app_api_gap_audit.md) لمعرفة الأجزاء المنفذة والخطوات التالية.
