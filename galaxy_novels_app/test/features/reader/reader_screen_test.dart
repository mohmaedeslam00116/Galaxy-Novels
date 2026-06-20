import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/data/repositories/reader_repository.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';

void main() {
  testWidgets('loads chapter content and renders it natively', (tester) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsOneWidget);
    expect(find.text('عنوان الفصل'), findsOneWidget);
    expect(find.text('نص الفصل الأول'), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.text('عنوان الفصل التالي'), findsOneWidget);
    expect(find.text('نص الفصل التالي'), findsOneWidget);
  });

  testWidgets('toggles floating controls when tapping reader content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _TestReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
          chapterTitle: 'الفصل 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-content-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsOneWidget);

    await tester.tap(find.text('نص الفصل الأول'));
    await tester.pumpAndSettle();

    expect(find.text('التالي'), findsNothing);
  });

  testWidgets('shows an error when chapter content fails', (tester) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        readerRepository: const _FailingReaderRepository(),
        child: const ReaderScreen(
          contentApi: '/wp-json/wor-reader-app/v1/chapters/10',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل الفصل'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}

class _ReaderTestApp extends StatelessWidget {
  const _ReaderTestApp({
    required this.child,
    this.readerRepository = const _TestReaderRepository(),
  });

  final Widget child;
  final ReaderRepository readerRepository;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: const AppConfig(),
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      readerRepository: readerRepository,
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }
}

class _TestReaderRepository implements ReaderRepository {
  const _TestReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    if (contentApi.endsWith('/11')) {
      return const ReaderChapterContent(
        id: 11,
        novelId: 1,
        label: 'الفصل 2',
        title: '',
        displayTitle: 'عنوان الفصل التالي',
        position: 2,
        total: 2,
        contentHtml: '<p>نص الفصل التالي</p>',
        navigation: ReaderChapterNavigation(
          previousApi: '/wp-json/wor-reader-app/v1/chapters/10',
          nextApi: '',
          previousId: 10,
          nextId: 0,
        ),
      );
    }

    return const ReaderChapterContent(
      id: 10,
      novelId: 1,
      label: 'الفصل 1',
      title: '',
      displayTitle: 'عنوان الفصل',
      position: 1,
      total: 2,
      contentHtml: '<p>نص الفصل الأول</p>',
      navigation: ReaderChapterNavigation(
        previousApi: '',
        nextApi: '/wp-json/wor-reader-app/v1/chapters/11',
        previousId: 0,
        nextId: 11,
      ),
    );
  }
}

class _FailingReaderRepository implements ReaderRepository {
  const _FailingReaderRepository();

  @override
  Future<ReaderChapterContent> loadChapter(String contentApi) async {
    throw Exception('reader failed');
  }
}
