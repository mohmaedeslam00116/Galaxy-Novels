import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/shared/widgets/app_async_state.dart';
import 'package:galaxy_novels_app/shared/widgets/app_empty_state.dart';
import 'package:galaxy_novels_app/shared/widgets/app_notice.dart';
import 'package:galaxy_novels_app/shared/widgets/app_skeleton.dart';

void main() {
  testWidgets('error state exposes and invokes a 44 pixel retry action', (
    tester,
  ) async {
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

  testWidgets('error state is a live container with an accessible retry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
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

    try {
      final errorRegion = find.byKey(
        const ValueKey('app-async-error-semantics'),
      );
      expect(errorRegion, findsOneWidget);
      expect(
        tester
            .getSemantics(errorRegion)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );

      final retry = find.bySemanticsLabel('إعادة المحاولة');
      expect(retry, findsOneWidget);
      await tester.tap(retry);
      expect(retries, 1);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('loading state is a live progress announcement', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: AppAsyncState.loading()),
      ),
    );

    try {
      final loading = find.bySemanticsLabel('جارٍ تحميل المحتوى');
      expect(loading, findsOneWidget);
      expect(
        tester
            .getSemantics(loading)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(find.byType(AppSkeleton), findsNWidgets(3));
      expect(find.textContaining('Exception'), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty state exposes its direct action when fully configured', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppAsyncState.empty(
            title: 'لا توجد عناصر',
            message: 'ابدأ باستكشاف المكتبة.',
            actionLabel: 'فتح المكتبة',
            onAction: () => actions += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('فتح المكتبة'));

    expect(actions, 1);
  });

  testWidgets('empty state omits incomplete action configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppEmptyState(
                title: 'الأولى',
                message: 'رسالة',
                actionLabel: 'بلا معالج',
              ),
              AppEmptyState(
                title: 'الثانية',
                message: 'رسالة',
                onAction: _unusedAction,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('بلا معالج'), findsNothing);
  });

  testWidgets('data state renders the supplied child unchanged', (
    tester,
  ) async {
    const dataKey = ValueKey('loaded-data');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppAsyncState.data(child: Text('المحتوى', key: dataKey)),
        ),
      ),
    );

    expect(find.byKey(dataKey), findsOneWidget);
    expect(find.text('المحتوى'), findsOneWidget);
  });

  testWidgets('notice maps every role to semantic theme colors', (
    tester,
  ) async {
    final theme = AppTheme.dark();
    final tokens = theme.extension<AppThemeTokens>()!;
    const cases = <AppNoticeKind, String>{
      AppNoticeKind.info: 'معلومة',
      AppNoticeKind.success: 'نجاح',
      AppNoticeKind.warning: 'تنبيه',
      AppNoticeKind.error: 'خطأ آمن',
    };
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: [
              for (final entry in cases.entries)
                AppNotice(kind: entry.key, message: entry.value),
            ],
          ),
        ),
      ),
    );

    final expectedForegrounds = <String, Color>{
      'معلومة': tokens.onBrandContainer,
      'نجاح': tokens.onSuccessContainer,
      'تنبيه': tokens.onWarningContainer,
      'خطأ آمن': tokens.onDangerContainer,
    };
    for (final entry in expectedForegrounds.entries) {
      expect(
        tester.widget<Text>(find.text(entry.key)).style?.color,
        entry.value,
      );
    }
  });

  testWidgets('notice reflows a long actionable message at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: AppNotice(
              kind: AppNoticeKind.warning,
              message:
                  'تعذر تنزيل الفصل مؤقتًا. تحقق من الشبكة ثم حاول مجددًا.',
              actionLabel: 'إعادة المحاولة الآن',
              onAction: () => actions += 1,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final action = find.byType(TextButton);
    expect(action, findsOneWidget);
    final actionSize = tester.getSize(action);
    expect(actionSize.width, greaterThanOrEqualTo(44));
    expect(actionSize.height, greaterThanOrEqualTo(44));

    await tester.tap(action);

    expect(actions, 1);
  });

  testWidgets('error notice is a live announcement', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: AppNotice(
            kind: AppNoticeKind.error,
            message: 'تعذر إكمال العملية.',
          ),
        ),
      ),
    );

    try {
      final notice = find.bySemanticsLabel('تعذر إكمال العملية.');
      expect(notice, findsOneWidget);
      expect(
        tester
            .getSemantics(notice)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'skeleton exposes an optional live semantic label without motion',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppSkeleton(height: 24, semanticLabel: 'تحميل البطاقة'),
          ),
        ),
      );

      try {
        expect(find.bySemanticsLabel('تحميل البطاقة'), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
      } finally {
        semantics.dispose();
      }
    },
  );
}

void _unusedAction() {}
