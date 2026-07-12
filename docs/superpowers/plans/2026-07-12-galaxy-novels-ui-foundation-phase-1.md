# Galaxy Novels UI Foundation — Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** بناء أساس واجهة «المكتبة المدارية الهادئة» عبر الوضعين المعتمدين، مكونات تخطيط وحالات مشتركة، وهيكل تنقل متكيف ينشئ الصفحات عند فتحها فقط من دون تغيير وظائف التطبيق الحالية.

**Architecture:** تظل طبقات البيانات والمستودعات والشاشات الحالية كما هي. تضيف المرحلة طبقة تصميم دلالية متوافقة مؤقتًا مع أسماء التوكنات القديمة، ومكونات عرض مشتركة مستقلة عن البيانات، ثم تفصل هيكل التنقل المتكيف عن `AppShell` الإنتاجي حتى يمكن اختباره بحقن بناة صفحات بسيطة. يحتفظ الهيكل في هذه المرحلة بالوجهات الخمس الحالية؛ تنتقل المفضلة والحساب إلى الشريط الرئيسي في المرحلة الثانية بعد دمج التنزيلات والترتيبات داخل المكتبة والرئيسية، منعًا لفقد أي وظيفة أثناء الانتقال.

**Tech Stack:** Flutter، Dart، Material 3، `ThemeExtension`، `SharedPreferencesAsync`، Flutter widget tests.

## Global Constraints

- الهدف الحالي Android فقط؛ لا تغييرات نشر أو إعداد خاصة بـ iOS.
- واجهة المستخدم تعرض Galaxy Noir وStarlight Paper فقط؛ خيار «حسب النظام» يختار بينهما ولا يمثل سمة ثالثة.
- التطبيق يعمل كزائر، ولا تصبح أي وجهة اكتشاف أو قراءة خلف تسجيل الدخول.
- لا يتغير Splash المعتمد إلا إذا تطلب البناء توافقًا مباشرًا مع السمات الجديدة.
- الضغط على «آخر التحديثات» يستمر في فتح تفاصيل الرواية.
- لا تتغير API أو المستودعات أو نماذج البيانات في هذه المرحلة.
- تبقى سياسة الخصوصية وDiscord في أسفل القائمة وبالرابط المعتمد.
- الحد الأدنى للهدف اللمسي 44×44، ودعم تكبير النص حتى 200%.
- نقاط التحول: أقل من 600 هاتف، 600–839 متوسط، و840 فأكثر موسع.
- تُنفذ أوامر Flutter وDart وGit من `galaxy_novels_app` ما لم تذكر الخطوة مسارًا آخر.
- لا تُضم أي تغييرات موجودة مسبقًا في الشجرة المتسخة إلى commits المرحلة. إذا كان الملف متسخًا قبل المهمة، راجع الفرق وأجّل commit الخاص به بدل إدخال تغييرات غير مرتبطة.
- خطوات commit تفترض أن اعتماديات المهمة قابلة للعزل. في الشجرة الحالية، إذا امتد تغيير ذري عبر ملف متسخ فلا تنشئ commit جزئيًا لا ينجح بناؤه منفردًا؛ اترك تغييرات المرحلة موثقة وغير staged إلى أن يمكن عزلها بأمان.

---

## File Map

### Theme responsibility

- Modify: `galaxy_novels_app/lib/app/app_theme.dart` — التوكنات الدلالية والوضعان فقط وسمات Material 3.
- Modify: `galaxy_novels_app/lib/app/app_theme_controller.dart` — اختيارات المستخدم الثلاثة وترحيل القيم القديمة.
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart` — ربط الاختيارات الثلاثة بالوضعين فقط.
- Modify: `galaxy_novels_app/lib/features/settings/presentation/settings_screen.dart` — واجهة اختيار السمات المرنة.
- Modify: `galaxy_novels_app/test/app/app_theme_test.dart` — قيم الألوان والتباين ومكونات Material.
- Modify: `galaxy_novels_app/test/app/app_theme_controller_test.dart` — ترحيل التخزين.
- Modify: `galaxy_novels_app/test/app/galaxy_splash_screen_test.dart` — استبدال مرجع السمة القديمة مع تثبيت استقلال Splash.
- Create: `galaxy_novels_app/test/features/settings/settings_screen_test.dart` — خيارات السمات وتكبير النص.
- Modify: `galaxy_novels_app/test/widget_test.dart` — تحديث تكامل مبدل السمات وإزالة توقعات السمات الملغاة.

### Shared UI responsibility

- Create: `galaxy_novels_app/lib/shared/layout/app_breakpoints.dart` — تصنيف العرض والحواف.
- Create: `galaxy_novels_app/lib/shared/widgets/app_scaffold.dart` — SafeArea والعرض الأقصى والحواف المتكيفة.
- Create: `galaxy_novels_app/lib/shared/widgets/app_section_header.dart` — عنوان قسم موحّد بلا شريط زخرفي.
- Modify: `galaxy_novels_app/lib/shared/widgets/section_title.dart` — غلاف توافق مؤقت فوق المكوّن الجديد.
- Delete: `galaxy_novels_app/lib/shared/widgets/section_header.dart` — مكوّن غير مستخدم ومكرر.
- Create: `galaxy_novels_app/test/shared/app_layout_primitives_test.dart` — اختبارات نقاط التحول والتكبير.

### State surfaces responsibility

- Create: `galaxy_novels_app/lib/shared/widgets/app_empty_state.dart` — حالة فارغة وإجراء اختياري.
- Create: `galaxy_novels_app/lib/shared/widgets/app_notice.dart` — رسائل دلالية.
- Create: `galaxy_novels_app/lib/shared/widgets/app_skeleton.dart` — هيكل تحميل ثابت منخفض التكلفة.
- Create: `galaxy_novels_app/lib/shared/widgets/app_async_state.dart` — توحيد التحميل والبيانات والفراغ والخطأ.
- Modify: `galaxy_novels_app/lib/shared/widgets/status_badge.dart` — ألوان حالة دلالية متباينة بدل الألوان الثابتة.
- Create: `galaxy_novels_app/test/shared/app_async_state_test.dart` — الوصول، إعادة المحاولة، والأهداف اللمسية.
- Modify: `galaxy_novels_app/test/shared/novel_components_test.dart` — عقود ألوان الشارات في الوضعين.

### Shell responsibility

- Create: `galaxy_novels_app/lib/features/shell/presentation/shell_destination.dart` — تعريف الوجهات الحالية وعناوينها وأيقوناتها.
- Create: `galaxy_novels_app/lib/features/shell/presentation/adaptive_app_shell.dart` — التخطيط المتكيف والإنشاء الكسول وحفظ الحالة.
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_shell.dart` — حقن الشاشات الإنتاجية في الهيكل المتكيف.
- Create: `galaxy_novels_app/test/features/shell/adaptive_app_shell_test.dart` — الهاتف والتابلت والشاشة الواسعة والإنشاء الكسول.

---

### Task 1: Semantic themes, stored-choice migration, and responsive selector

**Files:**
- Modify: `galaxy_novels_app/lib/app/app_theme.dart`
- Modify: `galaxy_novels_app/lib/app/app_theme_controller.dart`
- Modify: `galaxy_novels_app/lib/app/galaxy_novels_app.dart`
- Modify: `galaxy_novels_app/test/app/app_theme_test.dart`
- Modify: `galaxy_novels_app/test/app/app_theme_controller_test.dart`
- Modify: `galaxy_novels_app/test/app/galaxy_splash_screen_test.dart`
- Modify: `galaxy_novels_app/lib/features/settings/presentation/settings_screen.dart`
- Create: `galaxy_novels_app/test/features/settings/settings_screen_test.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

**Interfaces:**
- Produces: `AppThemeChoice.system`, `AppThemeChoice.galaxyNoir`, `AppThemeChoice.starlightPaper`.
- Produces: `AppThemeTokens` canonical fields `canvas`, `surface`, `surfaceRaised`, `contentPrimary`, `contentSecondary`, `brand`, `onBrand`, `outline`, `success`, `warning`, `danger` and container/on-container fields.
- Preserves temporarily: getters `background`, `surfaceSoft`, `primary`, `accent`, `gold`, `border`, `textPrimary`, `textSecondary` for feature code migrated in later phases.
- Produces: three selectable cards keyed by `theme-choice-card-system`, `theme-choice-card-galaxyNoir`, and `theme-choice-card-starlightPaper`.

- [ ] **Step 1: Replace theme tests with the approved palette and two-preset contract**

Keep the existing `_contrastRatio` helper and replace tests for removed presets with these assertions:

```dart
test('only Galaxy Noir and Starlight Paper presets remain', () {
  expect(AppThemePreset.values, [
    AppThemePreset.galaxyNoir,
    AppThemePreset.starlightPaper,
  ]);
});

test('theme choices map system, dark, and light correctly', () {
  expect(AppThemeChoice.system.themeMode, ThemeMode.system);
  expect(AppThemeChoice.galaxyNoir.themeMode, ThemeMode.dark);
  expect(AppThemeChoice.starlightPaper.themeMode, ThemeMode.light);
});

test('Galaxy Noir exposes the approved semantic palette', () {
  final tokens = AppTheme.dark().extension<AppThemeTokens>()!;

  expect(tokens.preset, AppThemePreset.galaxyNoir);
  expect(tokens.canvas, const Color(0xFF070B14));
  expect(tokens.surface, const Color(0xFF0E1523));
  expect(tokens.surfaceRaised, const Color(0xFF151F30));
  expect(tokens.contentPrimary, const Color(0xFFF4F8FF));
  expect(tokens.contentSecondary, const Color(0xFFA9B7C8));
  expect(tokens.brand, const Color(0xFF22D3EE));
  expect(tokens.onBrand, const Color(0xFF06212A));
  expect(tokens.warning, const Color(0xFFFBBF24));
});

test('Starlight Paper exposes the approved semantic palette', () {
  final tokens = AppTheme.light().extension<AppThemeTokens>()!;

  expect(tokens.preset, AppThemePreset.starlightPaper);
  expect(tokens.canvas, const Color(0xFFF7F8FB));
  expect(tokens.surface, const Color(0xFFFFFFFF));
  expect(tokens.surfaceRaised, const Color(0xFFEDF2F7));
  expect(tokens.contentPrimary, const Color(0xFF111827));
  expect(tokens.contentSecondary, const Color(0xFF526174));
  expect(tokens.brand, const Color(0xFF087D86));
  expect(tokens.onBrand, const Color(0xFFFFFFFF));
  expect(tokens.warning, const Color(0xFF8A5300));
});

test('semantic foreground pairs meet normal-text AA contrast', () {
  for (final theme in [AppTheme.dark(), AppTheme.light()]) {
    final tokens = theme.extension<AppThemeTokens>()!;
    expect(_contrastRatio(tokens.contentPrimary, tokens.canvas), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(tokens.contentSecondary, tokens.canvas), greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(tokens.onBrand, tokens.brand), greaterThanOrEqualTo(4.5));
  }
});

test('system bar icons follow the two theme brightness values', () {
  final lightTheme = AppTheme.light();
  final lightOverlay = AppTheme.systemOverlayStyleFor(lightTheme);
  expect(lightOverlay.statusBarIconBrightness, Brightness.dark);
  expect(lightOverlay.systemNavigationBarIconBrightness, Brightness.dark);

  final darkTheme = AppTheme.dark();
  final darkOverlay = AppTheme.systemOverlayStyleFor(darkTheme);
  expect(darkOverlay.statusBarIconBrightness, Brightness.light);
  expect(darkOverlay.systemNavigationBarIconBrightness, Brightness.light);
});
```

- [ ] **Step 2: Add failing storage-migration tests**

Replace all four existing controller tests in `app_theme_controller_test.dart` with:

```dart
test('maps every legacy dark value to Galaxy Noir', () {
  for (final raw in ['siteNoir', 'deepSpace', 'crimsonPagoda', 'blueberryNebula']) {
    expect(AppThemeChoice.fromStorageValue(raw), AppThemeChoice.galaxyNoir);
  }
});

test('loads a legacy dark value through the controller as Galaxy Noir', () async {
  final controller = StoredAppThemeController(
    store: _MemoryThemeStore(raw: 'deepSpace'),
  );

  await controller.load();

  expect(controller.value, AppThemeChoice.galaxyNoir);
});

test('maps the legacy light value to Starlight Paper', () {
  expect(
    AppThemeChoice.fromStorageValue('desertAstronaut'),
    AppThemeChoice.starlightPaper,
  );
});

test('keeps unknown storage values on system mode', () {
  expect(AppThemeChoice.fromStorageValue('unknown-theme'), AppThemeChoice.system);
});

test('persists an approved theme choice', () async {
  final store = _MemoryThemeStore();
  final controller = StoredAppThemeController(store: store);

  await controller.update(AppThemeChoice.starlightPaper);

  expect(controller.value, AppThemeChoice.starlightPaper);
  expect(store.raw, 'starlightPaper');
});
```

- [ ] **Step 3: Run the focused tests and verify they fail for removed APIs/palette values**

Run from `galaxy_novels_app`:

```powershell
flutter test test/app/app_theme_test.dart test/app/app_theme_controller_test.dart
```

Expected: FAIL because extra presets still exist and the semantic fields/new palette are not implemented.

- [ ] **Step 4: Reduce stored choices and migrate legacy values**

Replace `AppThemeChoice` with:

```dart
enum AppThemeChoice {
  system,
  galaxyNoir,
  starlightPaper;

  ThemeMode get themeMode => switch (this) {
    AppThemeChoice.system => ThemeMode.system,
    AppThemeChoice.galaxyNoir => ThemeMode.dark,
    AppThemeChoice.starlightPaper => ThemeMode.light,
  };

  static AppThemeChoice fromStorageValue(String? value) {
    return switch (value) {
      'galaxyNoir' || 'siteNoir' || 'deepSpace' || 'crimsonPagoda' ||
      'blueberryNebula' => AppThemeChoice.galaxyNoir,
      'starlightPaper' || 'desertAstronaut' => AppThemeChoice.starlightPaper,
      _ => AppThemeChoice.system,
    };
  }
}
```

Keep the store key `app_theme_choice.v1` so existing installations migrate without a second preference read.

- [ ] **Step 5: Implement canonical semantic tokens with compatibility getters**

Reduce `AppThemePreset` to two values and replace the token class with the complete canonical shape:

```dart
enum AppThemePreset { galaxyNoir, starlightPaper }

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.preset,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.brand,
    required this.onBrand,
    required this.brandContainer,
    required this.onBrandContainer,
    required this.outline,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  final AppThemePreset preset;
  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color brand;
  final Color onBrand;
  final Color brandContainer;
  final Color onBrandContainer;
  final Color outline;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  @override
  AppThemeTokens copyWith({
    AppThemePreset? preset,
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? brand,
    Color? onBrand,
    Color? brandContainer,
    Color? onBrandContainer,
    Color? outline,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? onDangerContainer,
  }) {
    return AppThemeTokens(
      preset: preset ?? this.preset,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandContainer: brandContainer ?? this.brandContainer,
      onBrandContainer: onBrandContainer ?? this.onBrandContainer,
      outline: outline ?? this.outline,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      preset: t < 0.5 ? preset : other.preset,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary: Color.lerp(contentSecondary, other.contentSecondary, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      brandContainer: Color.lerp(brandContainer, other.brandContainer, t)!,
      onBrandContainer: Color.lerp(onBrandContainer, other.onBrandContainer, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
    );
  }

  // Temporary source-compatible aliases for feature migration in phases 2–4.
Color get background => canvas;
Color get surfaceSoft => surfaceRaised;
Color get primary => brand;
Color get accent => brand;
Color get gold => warning;
Color get border => outline;
Color get textPrimary => contentPrimary;
Color get textSecondary => contentSecondary;
}
```

Define the two token constants from the approved values:

```dart
static const galaxyNoir = AppThemeTokens(
  preset: AppThemePreset.galaxyNoir,
  canvas: Color(0xFF070B14),
  surface: Color(0xFF0E1523),
  surfaceRaised: Color(0xFF151F30),
  contentPrimary: Color(0xFFF4F8FF),
  contentSecondary: Color(0xFFA9B7C8),
  brand: Color(0xFF22D3EE),
  onBrand: Color(0xFF06212A),
  brandContainer: Color(0xFF123B46),
  onBrandContainer: Color(0xFFB8F5FC),
  outline: Color(0xFF2A394D),
  success: Color(0xFF34D399),
  successContainer: Color(0xFF123D32),
  onSuccessContainer: Color(0xFFA7F3D0),
  warning: Color(0xFFFBBF24),
  warningContainer: Color(0xFF49380E),
  onWarningContainer: Color(0xFFFDE68A),
  danger: Color(0xFFFB7185),
  dangerContainer: Color(0xFF4B1F29),
  onDangerContainer: Color(0xFFFFD5DC),
);

static const starlightPaper = AppThemeTokens(
  preset: AppThemePreset.starlightPaper,
  canvas: Color(0xFFF7F8FB),
  surface: Color(0xFFFFFFFF),
  surfaceRaised: Color(0xFFEDF2F7),
  contentPrimary: Color(0xFF111827),
  contentSecondary: Color(0xFF526174),
  brand: Color(0xFF087D86),
  onBrand: Color(0xFFFFFFFF),
  brandContainer: Color(0xFFD5F3F5),
  onBrandContainer: Color(0xFF064E55),
  outline: Color(0xFFD7DEE8),
  success: Color(0xFF087A55),
  successContainer: Color(0xFFD6F5E8),
  onSuccessContainer: Color(0xFF07543E),
  warning: Color(0xFF8A5300),
  warningContainer: Color(0xFFFFF1C2),
  onWarningContainer: Color(0xFF4A2A00),
  danger: Color(0xFFB4233B),
  dangerContainer: Color(0xFFFFE1E7),
  onDangerContainer: Color(0xFF7A1730),
);
```

- [ ] **Step 6: Normalize Material 3 component themes**

In `AppTheme._base`, build `ColorScheme` directly from the semantic roles, change title weights to 700, keep body weight 400, set minimum interactive sizes to at least 44, and remove default card borders:

```dart
final brightness = tokens.preset == AppThemePreset.starlightPaper
    ? Brightness.light
    : Brightness.dark;
final colorScheme = ColorScheme.fromSeed(
  seedColor: tokens.brand,
  brightness: brightness,
).copyWith(
  primary: tokens.brand,
  onPrimary: tokens.onBrand,
  primaryContainer: tokens.brandContainer,
  onPrimaryContainer: tokens.onBrandContainer,
  secondary: tokens.brand,
  onSecondary: tokens.onBrand,
  secondaryContainer: tokens.brandContainer,
  onSecondaryContainer: tokens.onBrandContainer,
  surface: tokens.surface,
  onSurface: tokens.contentPrimary,
  surfaceContainerLow: tokens.surface,
  surfaceContainer: tokens.surface,
  surfaceContainerHigh: tokens.surfaceRaised,
  surfaceContainerHighest: tokens.surfaceRaised,
  onSurfaceVariant: tokens.contentSecondary,
  outline: tokens.outline,
  outlineVariant: tokens.outline.withValues(alpha: 0.65),
  error: tokens.danger,
  errorContainer: tokens.dangerContainer,
  onErrorContainer: tokens.onDangerContainer,
);

final textTheme = baseTheme.textTheme.copyWith(
  headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
    fontSize: 22,
    height: 1.35,
    fontWeight: FontWeight.w700,
  ),
  titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
    fontSize: 18,
    height: 1.4,
    fontWeight: FontWeight.w700,
  ),
  bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.65),
  bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.65),
  bodySmall: baseTheme.textTheme.bodySmall?.copyWith(fontSize: 14, height: 1.55),
  labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
  ),
).apply(bodyColor: tokens.contentPrimary, displayColor: tokens.contentPrimary);

cardTheme: CardThemeData(
  elevation: 0,
  color: tokens.surface,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
textButtonTheme: TextButtonThemeData(
  style: TextButton.styleFrom(
    minimumSize: const Size(44, 44),
    foregroundColor: tokens.brand,
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  ),
),
iconButtonTheme: IconButtonThemeData(
  style: IconButton.styleFrom(
    minimumSize: const Size(44, 44),
    foregroundColor: tokens.contentPrimary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
),
filledButtonTheme: FilledButtonThemeData(
  style: FilledButton.styleFrom(
    minimumSize: const Size(48, 48),
    backgroundColor: tokens.brand,
    foregroundColor: tokens.onBrand,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
),
```

Delete the four removed theme constants and factory methods.

- [ ] **Step 7: Reduce application theme switches to three choices**

In `galaxy_novels_app.dart`, replace both switch methods with:

```dart
ThemeData _lightThemeFor(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.system || AppThemeChoice.starlightPaper => AppTheme.light(),
  AppThemeChoice.galaxyNoir => AppTheme.dark(),
};

ThemeData _darkThemeFor(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.system || AppThemeChoice.galaxyNoir => AppTheme.dark(),
  AppThemeChoice.starlightPaper => AppTheme.light(),
};
```

- [ ] **Step 8: Keep the approved Splash independent from the removed legacy theme**

In `galaxy_splash_screen_test.dart`, change only the theme supplied by the “same branded splash for every app theme” test:

```dart
await tester.pumpWidget(
  _surface(theme: AppTheme.dark(), child: const GalaxySplashScreen()),
);
final darkScaffold = tester.widget<Scaffold>(
  find.byKey(const ValueKey('galaxy-splash-screen')),
);

await tester.pumpWidget(
  _surface(theme: AppTheme.light(), child: const GalaxySplashScreen()),
);
final lightScaffold = tester.widget<Scaffold>(
  find.byKey(const ValueKey('galaxy-splash-screen')),
);

expect(lightScaffold.backgroundColor, darkScaffold.backgroundColor);
```

#### Task 1 continued: responsive theme selector

**Files:**
- Modify: `galaxy_novels_app/lib/features/settings/presentation/settings_screen.dart`
- Create: `galaxy_novels_app/test/features/settings/settings_screen_test.dart`
- Modify: `galaxy_novels_app/test/widget_test.dart`

**Interfaces:**
- Consumes: the three `AppThemeChoice` values implemented in Steps 4–8 of this task.
- Produces: three selectable cards keyed by `theme-choice-card-system`, `theme-choice-card-galaxyNoir`, and `theme-choice-card-starlightPaper`.

- [ ] **Step 9: Write widget tests for the three options and 200% text**

Create the feature-test directory, then add a small memory controller and surface:

```powershell
New-Item -ItemType Directory -Force test/features/settings | Out-Null
```

```dart
class _MemoryThemeController extends ChangeNotifier
    implements AppThemeController {
  AppThemeChoice _value = AppThemeChoice.system;

  @override
  AppThemeChoice get value => _value;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppThemeChoice choice) async {
    _value = choice;
    notifyListeners();
  }
}

Widget _surface(_MemoryThemeController controller, {double textScale = 1}) {
  return AppThemeControllerScope(
    controller: controller,
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const SettingsScreen(),
        ),
      ),
    ),
  );
}

testWidgets('shows only system, Galaxy Noir, and Starlight Paper', (tester) async {
  final controller = _MemoryThemeController();
  await tester.pumpWidget(_surface(controller));

  expect(find.byKey(const ValueKey('theme-choice-card-system')), findsOneWidget);
  expect(find.byKey(const ValueKey('theme-choice-card-galaxyNoir')), findsOneWidget);
  expect(find.byKey(const ValueKey('theme-choice-card-starlightPaper')), findsOneWidget);
  expect(
    find.byWidgetPredicate(
      (widget) => widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>)
              .value
              .startsWith('theme-choice-card-'),
    ),
    findsNWidgets(3),
  );
});

testWidgets('theme cards reflow without overflow at 200 percent text', (tester) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_surface(_MemoryThemeController(), textScale: 2));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);
  expect(find.text('Galaxy Noir'), findsOneWidget);
  expect(find.text('Starlight Paper'), findsOneWidget);
});
```

- [ ] **Step 10: Run the settings tests and verify the fixed-height card fails at 200%**

```powershell
flutter test test/features/settings/settings_screen_test.dart
```

Expected: FAIL before the selector is reduced and the fixed `height: 156` is removed.

- [ ] **Step 11: Simplify copy, palettes, and sizing**

Use the three enum values only. Replace the fixed card height with flexible minimum constraints:

```dart
child: ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 132),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _themeChoiceTitle(choice),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ThemePalettePreview(choice: choice),
        const SizedBox(height: 10),
        Text(
          _themeChoiceSubtitle(choice),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  ),
),
```

Use these labels and tokens:

```dart
AppThemeTokens? _themeChoiceTokens(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.system => null,
  AppThemeChoice.galaxyNoir => AppTheme.galaxyNoir,
  AppThemeChoice.starlightPaper => AppTheme.starlightPaper,
};

List<Color> _themeChoicePalette(AppThemeChoice choice) {
  final tokens = _themeChoiceTokens(choice);
  if (tokens == null) {
    return [
      AppTheme.galaxyNoir.canvas,
      AppTheme.galaxyNoir.brand,
      AppTheme.starlightPaper.canvas,
      AppTheme.starlightPaper.brand,
    ];
  }
  return [tokens.canvas, tokens.surface, tokens.surfaceRaised, tokens.brand];
}

String _themeChoiceTitle(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.system => 'حسب النظام',
  AppThemeChoice.galaxyNoir => 'Galaxy Noir',
  AppThemeChoice.starlightPaper => 'Starlight Paper',
};

String _themeChoiceSubtitle(AppThemeChoice choice) => switch (choice) {
  AppThemeChoice.system => 'يتبع الوضع الداكن أو الفاتح في جهازك',
  AppThemeChoice.galaxyNoir => 'الوضع الداكن الأساسي للقراءة الهادئة',
  AppThemeChoice.starlightPaper => 'وضع فاتح مريح للقراءة النهارية',
};
```

Use `FontWeight.w700` for section/title emphasis and remove copy that promises unspecified future options.

- [ ] **Step 12: Update the full-app settings integration tests**

Replace the old multi-theme integration block in `test/widget_test.dart` with a two-mode integration test:

```dart
testWidgets('settings applies only the approved dark and light themes', (tester) async {
  final appThemeController = _TestAppThemeController();
  await tester.pumpWidget(
    GalaxyNovelsApp(
      homeRepository: _TestHomeRepository(_homeData),
      catalogRepository: const _TestCatalogRepository(),
      novelRepository: const _TestNovelRepository(),
      appThemeController: appThemeController,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();

  expect(find.byKey(const ValueKey('theme-choice-card-system')), findsOneWidget);
  expect(find.byKey(const ValueKey('theme-choice-card-galaxyNoir')), findsOneWidget);
  expect(find.byKey(const ValueKey('theme-choice-card-starlightPaper')), findsOneWidget);
  expect(find.text('الفضاء السحيق / Deep Space'), findsNothing);

  await tester.tap(find.byKey(const ValueKey('theme-choice-card-starlightPaper')));
  await tester.pumpAndSettle();
  expect(appThemeController.value, AppThemeChoice.starlightPaper);
  expect(
    Theme.of(tester.element(find.text('Starlight Paper')))
        .extension<AppThemeTokens>()!
        .preset,
    AppThemePreset.starlightPaper,
  );

  await tester.tap(find.byKey(const ValueKey('theme-choice-card-galaxyNoir')));
  await tester.pumpAndSettle();
  expect(appThemeController.value, AppThemeChoice.galaxyNoir);
});
```

Update the existing narrow-phone test to look for `theme-choice-card-system`, `theme-choice-card-galaxyNoir`, and `theme-choice-card-starlightPaper`, then assert `tester.takeException()` is null. The dedicated settings test from Step 1 owns the 200% text-scaling assertion.

- [ ] **Step 13: Run the atomic theme migration tests and analysis**

```powershell
flutter test test/app/app_theme_test.dart test/app/app_theme_controller_test.dart test/app/galaxy_splash_screen_test.dart test/features/settings/settings_screen_test.dart test/widget_test.dart
flutter analyze
```

Expected: every focused test passes with no overflow exception, and analysis reports no issues. Do not run analysis between Steps 4 and 12 because removing enum cases and updating their exhaustive settings switches is one atomic compile migration.

- [ ] **Step 14: Commit the complete atomic theme task when it can be isolated**

```powershell
git add lib/app/app_theme.dart lib/app/app_theme_controller.dart lib/app/galaxy_novels_app.dart lib/features/settings/presentation/settings_screen.dart test/app/app_theme_test.dart test/app/app_theme_controller_test.dart test/app/galaxy_splash_screen_test.dart test/features/settings/settings_screen_test.dart test/widget_test.dart
git diff --cached --check
git commit -m "feat: establish Galaxy UI semantic themes"
```

`lib/app/galaxy_novels_app.dart` and `test/widget_test.dart` are already dirty, while `test/app/galaxy_splash_screen_test.dart` is an existing untracked file from earlier work. في الشجرة الحالية يُتوقع تخطي هذا commit كاملًا ما لم يمكن عزل كل hunks السابقة بأمان؛ لا تنشئ commit جزئيًا يفشل في clean checkout.

---

### Task 2: Layout and section primitives

**Files:**
- Create: `galaxy_novels_app/lib/shared/layout/app_breakpoints.dart`
- Create: `galaxy_novels_app/lib/shared/widgets/app_scaffold.dart`
- Create: `galaxy_novels_app/lib/shared/widgets/app_section_header.dart`
- Modify: `galaxy_novels_app/lib/shared/widgets/section_title.dart`
- Delete: `galaxy_novels_app/lib/shared/widgets/section_header.dart`
- Create: `galaxy_novels_app/test/shared/app_layout_primitives_test.dart`

**Interfaces:**
- Produces: `AppWindowClass.compact`, `.medium`, `.expanded`.
- Produces: `AppBreakpoints.classify(double width)` and `AppBreakpoints.screenPadding(double width)`.
- Produces: `AppScaffold` and `AppSectionHeader`.
- Preserves: `SectionTitle` as a deprecated wrapper for existing feature imports.

- [ ] **Step 1: Write breakpoint and 200% header tests**

```dart
test('classifies approved breakpoints', () {
  expect(AppBreakpoints.classify(599), AppWindowClass.compact);
  expect(AppBreakpoints.classify(600), AppWindowClass.medium);
  expect(AppBreakpoints.classify(839), AppWindowClass.medium);
  expect(AppBreakpoints.classify(840), AppWindowClass.expanded);
  expect(AppBreakpoints.screenPadding(599), 16);
  expect(AppBreakpoints.screenPadding(600), 24);
});

testWidgets('section header reflows at 200 percent text', (tester) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const Scaffold(
          body: AppSectionHeader(
            title: 'آخر التحديثات الطويلة',
            action: Text('عرض الكل'),
          ),
        ),
      ),
    ),
  );

  expect(tester.takeException(), isNull);
  expect(find.text('آخر التحديثات الطويلة'), findsOneWidget);
});
```

- [ ] **Step 2: Run and verify missing symbols fail**

```powershell
flutter test test/shared/app_layout_primitives_test.dart
```

Expected: FAIL because the three new foundation types do not exist.

- [ ] **Step 3: Implement breakpoints**

Create the new layout directory first:

```powershell
New-Item -ItemType Directory -Force lib/shared/layout | Out-Null
```

```dart
enum AppWindowClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;

  static AppWindowClass classify(double width) {
    if (width < medium) return AppWindowClass.compact;
    if (width < expanded) return AppWindowClass.medium;
    return AppWindowClass.expanded;
  }

  static double screenPadding(double width) => width < medium ? 16 : 24;
}
```

- [ ] **Step 4: Implement `AppScaffold`**

The widget owns only page chrome and constraints; it does not fetch data:

```dart
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.maxContentWidth = 1200,
    this.applyHorizontalPadding = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool applyHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = applyHorizontalPadding
                ? AppBreakpoints.screenPadding(constraints.maxWidth)
                : 0.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: body,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement a flexible section header and compatibility wrapper**

```dart
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    this.action,
    this.leadingIcon,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 8),
    super.key,
  });

  final String title;
  final Widget? action;
  final IconData? leadingIcon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (leadingIcon != null) Icon(leadingIcon, size: 20),
                  Text(title, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(child: action!),
            ),
          ],
        ],
      ),
    );
  }
}
```

Replace the old `SectionTitle` implementation with a wrapper returning `AppSectionHeader(title: title, action: action, leadingIcon: leadingIcon)`. Mark it deprecated in favor of `AppSectionHeader`. Delete unused `section_header.dart` after confirming `rg "section_header.dart|SectionHeader" lib test` returns no consumers.

- [ ] **Step 6: Run focused tests and current shared tests**

```powershell
flutter test test/shared/app_layout_primitives_test.dart test/shared/novel_components_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/shared/layout/app_breakpoints.dart lib/shared/widgets/app_scaffold.dart lib/shared/widgets/app_section_header.dart lib/shared/widgets/section_title.dart lib/shared/widgets/section_header.dart test/shared/app_layout_primitives_test.dart
git diff --cached --check
git commit -m "feat: add adaptive Galaxy UI layout primitives"
```

---

### Task 3: Unified loading, empty, error, and notice surfaces

**Files:**
- Create: `galaxy_novels_app/lib/shared/widgets/app_empty_state.dart`
- Create: `galaxy_novels_app/lib/shared/widgets/app_notice.dart`
- Create: `galaxy_novels_app/lib/shared/widgets/app_skeleton.dart`
- Create: `galaxy_novels_app/lib/shared/widgets/app_async_state.dart`
- Modify: `galaxy_novels_app/lib/shared/widgets/status_badge.dart`
- Create: `galaxy_novels_app/test/shared/app_async_state_test.dart`
- Modify: `galaxy_novels_app/test/shared/novel_components_test.dart`

**Interfaces:**
- Produces: `AppAsyncState.loading`, `.data`, `.empty`, `.error`.
- Produces: `AppNoticeKind.info`, `.success`, `.warning`, `.error`.
- Produces: `AppSkeleton(width, height, borderRadius, semanticLabel)`.
- Produces: `StatusBadge` foreground/background pairs sourced from theme containers.

- [ ] **Step 1: Write state-surface tests**

```dart
testWidgets('error state exposes a 44 pixel retry action', (tester) async {
  var retries = 0;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: AppAsyncState.error(
          title: 'تعذر تحميل المحتوى',
          message: 'تحقق من الاتصال ثم حاول مجددًا.',
          onRetry: () => retries += 1,
        ),
      ),
    ),
  );

  final retry = find.byKey(const ValueKey('app-async-retry'));
  expect(retry, findsOneWidget);
  expect(tester.getSize(retry).height, greaterThanOrEqualTo(44));
  await tester.tap(retry);
  expect(retries, 1);
});

testWidgets('loading state announces progress without raw exceptions', (tester) async {
  final semantics = tester.ensureSemantics();
  addTearDown(semantics.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: const Scaffold(body: AppAsyncState.loading()),
    ),
  );

  expect(find.bySemanticsLabel('جارٍ تحميل المحتوى'), findsOneWidget);
  expect(find.byType(AppSkeleton), findsWidgets);
});

testWidgets('empty state renders one direct action', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: AppAsyncState.empty(
          title: 'لا توجد عناصر',
          message: 'ابدأ باستكشاف المكتبة.',
          actionLabel: 'فتح المكتبة',
          onAction: () {},
        ),
      ),
    ),
  );

  expect(find.text('فتح المكتبة'), findsOneWidget);
});

```

In `novel_components_test.dart`, replace the old hardcoded red/green/purple assertion with:

```dart
testWidgets('status badges use semantic theme foregrounds', (tester) async {
  for (final theme in [AppTheme.dark(), AppTheme.light()]) {
    final tokens = theme.extension<AppThemeTokens>()!;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Column(
            children: [
              StatusBadge(label: 'مستمرة'),
              StatusBadge(label: 'مكتملة'),
              StatusBadge(label: 'متوقفة'),
            ],
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('مستمرة')).style?.color, tokens.onBrandContainer);
    expect(tester.widget<Text>(find.text('مكتملة')).style?.color, tokens.onSuccessContainer);
    expect(tester.widget<Text>(find.text('متوقفة')).style?.color, tokens.onWarningContainer);
  }
});
```

- [ ] **Step 2: Run and verify the missing components fail**

```powershell
flutter test test/shared/app_async_state_test.dart
```

Expected: FAIL because the state components do not exist.

- [ ] **Step 3: Implement `AppSkeleton` and `AppNotice`**

`AppSkeleton` is static in phase 1, eliminating shimmer cost and automatically respecting reduced-motion settings:

```dart
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.semanticLabel,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final box = SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: box)
        : Semantics(label: semanticLabel, liveRegion: true, child: box);
  }
}
```

`AppNotice` accepts safe display text only and maps its visual role explicitly:

```dart
enum AppNoticeKind { info, success, warning, error }

class AppNotice extends StatelessWidget {
  const AppNotice({
    required this.kind,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final AppNoticeKind kind;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final (background, foreground, icon) = switch (kind) {
      AppNoticeKind.info => (
        tokens.brandContainer,
        tokens.onBrandContainer,
        Icons.info_outline_rounded,
      ),
      AppNoticeKind.success => (
        tokens.successContainer,
        tokens.onSuccessContainer,
        Icons.check_circle_outline_rounded,
      ),
      AppNoticeKind.warning => (
        tokens.warningContainer,
        tokens.onWarningContainer,
        Icons.warning_amber_rounded,
      ),
      AppNoticeKind.error => (
        tokens.dangerContainer,
        tokens.onDangerContainer,
        Icons.error_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: kind == AppNoticeKind.error,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: TextStyle(color: foreground))),
              if (actionLabel != null && onAction != null)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: foreground),
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Update `StatusBadge` to use the same semantic pairs rather than alpha-blending fixed green/red/purple values:

```dart
enum _NovelStatus { ongoing, completed, stopped }

_NovelStatus? _normalizedStatus(String label) {
  final normalized = label.trim().toLowerCase();
  if (_matchesAny(normalized, const ['مستمرة', 'مستمر', 'ongoing'])) {
    return _NovelStatus.ongoing;
  }
  if (_matchesAny(normalized, const [
    'مكتملة',
    'مكتمل',
    'completed',
    'complete',
    'finished',
  ])) {
    return _NovelStatus.completed;
  }
  if (_matchesAny(normalized, const [
    'متوقفة',
    'متوقف',
    'موقوفة',
    'stopped',
    'paused',
    'on hold',
    'on-hold',
  ])) {
    return _NovelStatus.stopped;
  }
  return null;
}

final (background, foreground) = switch (_normalizedStatus(label)) {
  _NovelStatus.ongoing => (tokens.brandContainer, tokens.onBrandContainer),
  _NovelStatus.completed => (
    tokens.successContainer,
    tokens.onSuccessContainer,
  ),
  _NovelStatus.stopped => (
    tokens.warningContainer,
    tokens.onWarningContainer,
  ),
  null when emphasis == StatusBadgeEmphasis.gold => (
    tokens.warningContainer,
    tokens.onWarningContainer,
  ),
  null => (tokens.brandContainer, tokens.onBrandContainer),
};

return ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 28),
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
);
```

Keep the current Arabic/English aliases, but return a private `_NovelStatus` enum instead of a `Color`.

- [ ] **Step 4: Implement `AppEmptyState` and `AppAsyncState`**

Use named constructors over a public mutable status model:

```dart
enum AppAsyncStateKind { loading, data, empty, error }

class AppAsyncState extends StatelessWidget {
  const AppAsyncState.loading({this.loadingLabel = 'جارٍ تحميل المحتوى', super.key})
      : kind = AppAsyncStateKind.loading,
        child = null,
        title = null,
        message = null,
        actionLabel = null,
        onAction = null;

  const AppAsyncState.data({required this.child, super.key})
      : kind = AppAsyncStateKind.data,
        loadingLabel = null,
        title = null,
        message = null,
        actionLabel = null,
        onAction = null;

  const AppAsyncState.empty({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  })  : kind = AppAsyncStateKind.empty,
        loadingLabel = null,
        child = null;

  const AppAsyncState.error({
    required this.title,
    required this.message,
    required VoidCallback onRetry,
    super.key,
  })  : kind = AppAsyncStateKind.error,
        loadingLabel = null,
        child = null,
        actionLabel = 'إعادة المحاولة',
        onAction = onRetry;

  final AppAsyncStateKind kind;
  final String? loadingLabel;
  final Widget? child;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => switch (kind) {
    AppAsyncStateKind.loading => Semantics(
      label: loadingLabel,
      liveRegion: true,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            AppSkeleton(height: 160),
            SizedBox(height: 12),
            AppSkeleton(height: 20),
            SizedBox(height: 8),
            AppSkeleton(height: 20, width: 220),
          ],
        ),
      ),
    ),
    AppAsyncStateKind.data => child!,
    AppAsyncStateKind.empty => AppEmptyState(
      title: title!,
      message: message!,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
    AppAsyncStateKind.error => AppEmptyState(
      icon: Icons.cloud_off_rounded,
      title: title!,
      message: message!,
      actionLabel: actionLabel,
      onAction: onAction,
      actionKey: const ValueKey('app-async-retry'),
    ),
  };
}
```

Implement `AppEmptyState` as the single empty/error presentation primitive:

```dart
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  key: actionKey,
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run focused tests and analysis**

```powershell
flutter test test/shared/app_async_state_test.dart test/shared/novel_components_test.dart
flutter analyze
```

Expected: PASS and no analysis issues.

- [ ] **Step 6: Commit**

```powershell
git add lib/shared/widgets/app_empty_state.dart lib/shared/widgets/app_notice.dart lib/shared/widgets/app_skeleton.dart lib/shared/widgets/app_async_state.dart lib/shared/widgets/status_badge.dart test/shared/app_async_state_test.dart test/shared/novel_components_test.dart
git diff --cached --check
git commit -m "feat: add unified async UI states"
```

---

### Task 4: Adaptive, lazy application shell

**Files:**
- Create: `galaxy_novels_app/lib/features/shell/presentation/shell_destination.dart`
- Create: `galaxy_novels_app/lib/features/shell/presentation/adaptive_app_shell.dart`
- Modify: `galaxy_novels_app/lib/features/shell/presentation/app_shell.dart`
- Create: `galaxy_novels_app/test/features/shell/adaptive_app_shell_test.dart`

**Interfaces:**
- Produces: `ShellDestination.home`, `.library`, `.downloads`, `.history`, `.rankings` for the transitional phase-1 shell.
- Produces: `typedef ShellScreenBuilder = Widget Function(BuildContext context, ValueChanged<ShellDestination> selectDestination)`.
- Produces: `AdaptiveAppShell(screenBuilders, drawerBuilder, initialDestination)`.
- Preserves: current labels and access to every existing screen.

- [ ] **Step 1: Write lazy creation and breakpoint tests**

Create counters and injected builders:

```dart
Map<ShellDestination, int> _counts() => {
  for (final destination in ShellDestination.values) destination: 0,
};

Map<ShellDestination, ShellScreenBuilder> _builders(
  Map<ShellDestination, int> counts,
) => {
  for (final destination in ShellDestination.values)
    destination: (context, selectDestination) {
      counts[destination] = counts[destination]! + 1;
      return Center(
        key: ValueKey('screen-${destination.name}'),
        child: Text(destination.label),
      );
    },
};

Future<void> _pumpAt(
  WidgetTester tester,
  Size size,
  Map<ShellDestination, int> counts,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: AdaptiveAppShell(screenBuilders: _builders(counts)),
      ),
    ),
  );
  await tester.pump();
}

testWidgets('compact shell creates only visited tabs and preserves them', (tester) async {
  final counts = _counts();
  await _pumpAt(tester, const Size(390, 844), counts);

  expect(find.byType(NavigationBar), findsOneWidget);
  expect(counts[ShellDestination.home], 1);
  expect(counts[ShellDestination.downloads], 0);

  await tester.tap(find.text('التنزيلات'));
  await tester.pump();
  expect(counts[ShellDestination.downloads], 1);

  await tester.tap(find.text('الرئيسية'));
  await tester.pump();
  await tester.tap(find.text('التنزيلات'));
  await tester.pump();
  expect(counts[ShellDestination.downloads], 1);
});

testWidgets('medium shell uses NavigationRail', (tester) async {
  await _pumpAt(tester, const Size(700, 900), _counts());
  expect(find.byType(NavigationRail), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
});

testWidgets('expanded shell uses a permanent NavigationDrawer', (tester) async {
  await _pumpAt(tester, const Size(1000, 900), _counts());
  expect(find.byType(NavigationDrawer), findsOneWidget);
  expect(find.byType(NavigationRail), findsNothing);
});
```

- [ ] **Step 2: Run and verify the new shell symbols fail**

```powershell
flutter test test/features/shell/adaptive_app_shell_test.dart
```

Expected: FAIL because `ShellDestination` and `AdaptiveAppShell` do not exist.

- [ ] **Step 3: Define transitional destinations**

```dart
enum ShellDestination { home, library, downloads, history, rankings }

extension ShellDestinationPresentation on ShellDestination {
  String get label => switch (this) {
    ShellDestination.home => 'الرئيسية',
    ShellDestination.library => 'المكتبة',
    ShellDestination.downloads => 'التنزيلات',
    ShellDestination.history => 'السجل',
    ShellDestination.rankings => 'الترتيب',
  };

  IconData get icon => switch (this) {
    ShellDestination.home => Icons.home_outlined,
    ShellDestination.library => Icons.local_library_outlined,
    ShellDestination.downloads => Icons.download_outlined,
    ShellDestination.history => Icons.history_outlined,
    ShellDestination.rankings => Icons.leaderboard_outlined,
  };

  IconData get selectedIcon => switch (this) {
    ShellDestination.home => Icons.home,
    ShellDestination.library => Icons.local_library,
    ShellDestination.downloads => Icons.download,
    ShellDestination.history => Icons.history,
    ShellDestination.rankings => Icons.leaderboard,
  };
}
```

- [ ] **Step 4: Implement lazy page retention**

The state owns a map of only visited pages:

```dart
typedef ShellScreenBuilder = Widget Function(
  BuildContext context,
  ValueChanged<ShellDestination> selectDestination,
);

class AdaptiveAppShell extends StatefulWidget {
  AdaptiveAppShell({
    required this.screenBuilders,
    this.drawerBuilder,
    this.initialDestination = ShellDestination.home,
    super.key,
  }) : assert(
         ShellDestination.values.every(screenBuilders.containsKey),
         'A screen builder is required for every shell destination.',
       );

  final Map<ShellDestination, ShellScreenBuilder> screenBuilders;
  final WidgetBuilder? drawerBuilder;
  final ShellDestination initialDestination;

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  late ShellDestination _selected = widget.initialDestination;
  final Map<ShellDestination, Widget> _createdScreens = {};

  void _select(ShellDestination destination) {
    if (_selected == destination) return;
    setState(() => _selected = destination);
  }

  Widget _screen(ShellDestination destination) {
    return _createdScreens.putIfAbsent(
      destination,
      () => KeyedSubtree(
        key: PageStorageKey(destination.name),
        child: widget.screenBuilders[destination]!(context, _select),
      ),
    );
  }

  Widget _body() {
    _screen(_selected);
    return IndexedStack(
      index: ShellDestination.values.indexOf(_selected),
      children: [
        for (final destination in ShellDestination.values)
          _createdScreens[destination] ?? const SizedBox.shrink(),
      ],
    );
  }
}
```

- [ ] **Step 5: Implement responsive navigation chrome**

Use one `Scaffold` and switch only the navigation/body composition:

```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final selectedIndex = ShellDestination.values.indexOf(_selected);
      final windowClass = AppBreakpoints.classify(constraints.maxWidth);
      final body = _body();
      final drawer = widget.drawerBuilder?.call(context);

      return switch (windowClass) {
        AppWindowClass.compact => Scaffold(
          drawer: drawer,
          appBar: AppBar(title: Text(_selected.label)),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _select(ShellDestination.values[index]),
            destinations: [
              for (final destination in ShellDestination.values)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: destination.label,
                ),
            ],
          ),
        ),
        AppWindowClass.medium => Scaffold(
          drawer: drawer,
          appBar: AppBar(title: Text(_selected.label)),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) =>
                    _select(ShellDestination.values[index]),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in ShellDestination.values)
                    NavigationRailDestination(
                      icon: Icon(destination.icon),
                      selectedIcon: Icon(destination.selectedIcon),
                      label: Text(destination.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
        AppWindowClass.expanded => Scaffold(
          drawer: drawer,
          appBar: AppBar(title: Text(_selected.label)),
          body: Row(
            children: [
              SizedBox(
                width: 256,
                child: NavigationDrawer(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) =>
                      _select(ShellDestination.values[index]),
                  children: [
                    const SizedBox(height: 12),
                    for (final destination in ShellDestination.values)
                      NavigationDrawerDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      };
    },
  );
}
```

- [ ] **Step 6: Convert production `AppShell` into a thin builder map**

Replace the current stateful index owner with this stateless production composition; `AdaptiveAppShell` owns the selected state:

```dart
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveAppShell(
      drawerBuilder: (context) => const AppDrawer(),
      screenBuilders: {
        ShellDestination.home: (context, select) => const HomeScreen(),
        ShellDestination.library: (context, select) => const CatalogScreen(),
        ShellDestination.downloads: (context, select) => DownloadsScreen(
          onOpenLibrary: () => select(ShellDestination.library),
        ),
        ShellDestination.history: (context, select) => const HistoryScreen(),
        ShellDestination.rankings: (context, select) => const RankingsScreen(),
      },
    );
  }
}
```

Do not move destinations in this task. The final five-destination mapping is a phase-2 change performed together with visible download/ranking shortcuts.

- [ ] **Step 7: Run shell and whole-app widget tests**

```powershell
flutter test test/features/shell/adaptive_app_shell_test.dart test/widget_test.dart
```

Expected: PASS; the Arabic shell still exposes the same five current labels and creates unvisited screens lazily.

- [ ] **Step 8: Commit**

```powershell
git add lib/features/shell/presentation/shell_destination.dart lib/features/shell/presentation/adaptive_app_shell.dart lib/features/shell/presentation/app_shell.dart test/features/shell/adaptive_app_shell_test.dart
git diff --cached --check
git commit -m "feat: add lazy adaptive application shell"
```

---

### Task 5: Phase-1 quality gate

**Files:**
- Verify all files changed in Tasks 1–4.
- Do not modify feature behavior merely to make a broad test pass; diagnose failures first.

**Interfaces:**
- Consumes: the completed theme, layout, state, and shell foundations.
- Produces: a clean Android-debug phase-1 baseline ready for the discovery redesign plan.

- [ ] **Step 1: Format clean and newly created phase-1 Dart files**

```powershell
dart format lib/app/app_theme.dart lib/app/app_theme_controller.dart lib/features/settings/presentation/settings_screen.dart lib/shared/layout/app_breakpoints.dart lib/shared/widgets/app_scaffold.dart lib/shared/widgets/app_section_header.dart lib/shared/widgets/section_title.dart lib/shared/widgets/app_empty_state.dart lib/shared/widgets/app_notice.dart lib/shared/widgets/app_skeleton.dart lib/shared/widgets/app_async_state.dart lib/shared/widgets/status_badge.dart lib/features/shell/presentation/shell_destination.dart lib/features/shell/presentation/adaptive_app_shell.dart lib/features/shell/presentation/app_shell.dart test/app/app_theme_test.dart test/app/app_theme_controller_test.dart test/features/settings/settings_screen_test.dart test/shared/app_layout_primitives_test.dart test/shared/app_async_state_test.dart test/shared/novel_components_test.dart test/features/shell/adaptive_app_shell_test.dart
```

Expected: formatting completes without touching unrelated files. Verify the focused edits in dirty overlapping files separately rather than formatting their entire contents.

- [ ] **Step 2: Run static analysis**

```powershell
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 3: Run the complete test suite**

```powershell
flutter test
```

Expected: all tests pass. Record the final test count in the handoff.

- [ ] **Step 4: Build Android debug APK**

```powershell
flutter build apk --debug
```

Expected: build succeeds and produces `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 5: Inspect the final diff for scope and dirty-worktree safety**

```powershell
git diff --check
git status --short
git diff --stat
```

Expected: no whitespace errors; only phase-1 changes are attributed to this work. Pre-existing unrelated changes remain present and unstaged.

---

## Self-Review Record

- Spec coverage: phase 1 covers the two themes, semantic tokens and status badges, typography, 44px controls, breakpoints, shared scaffold/header, shared async states, reduced-motion-safe skeleton, and lazy adaptive shell.
- Deferred deliberately: final destination relocation, home/catalog/rankings cards, details, reader, comments, VIP, ads, account, privacy polish, and goldens belong to phases 2–4.
- Contract safety: phase 1 keeps all five current destinations and does not touch «آخر التحديثات», authentication gates, data repositories, or API models.
- Placeholder scan: implementation steps contain concrete interfaces, code, commands, and expected results; no deferred implementation marker remains.
- Type consistency: `AppThemeChoice`, `AppThemeTokens`, `AppWindowClass`, `AppBreakpoints`, `AppAsyncState`, `ShellDestination`, and `ShellScreenBuilder` names remain consistent across producer and consumer tasks.
