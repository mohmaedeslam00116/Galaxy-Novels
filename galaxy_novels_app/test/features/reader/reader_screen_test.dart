import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_dependencies.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/data/repositories/fake_catalog_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_home_repository.dart';
import 'package:galaxy_novels_app/data/repositories/fake_novel_repository.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_screen.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_web_view.dart';

void main() {
  testWidgets('renders reader chrome and passes config to the web view', (
    tester,
  ) async {
    ReaderWebViewConfig? capturedConfig;

    await tester.pumpWidget(
      _ReaderTestApp(
        child: ReaderScreen(
          chapterUrl: '/novel/example/chapter-1/',
          chapterTitle: 'الفصل 1',
          webViewBuilder: (context, config) {
            capturedConfig = config;
            return const Text('fake webview');
          },
        ),
      ),
    );

    expect(find.text('الفصل 1'), findsOneWidget);
    expect(find.text('fake webview'), findsOneWidget);
    expect(
      capturedConfig?.initialUri.toString(),
      'https://galaxynovels.com/novel/example/chapter-1/?wr_app_reader=1',
    );
    expect(capturedConfig?.userAgent, 'WorReaderApp/1.0 Android');
  });

  testWidgets('shows an error for invalid relative URLs without a base URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _ReaderTestApp(
        config: const AppConfig(siteBaseUrl: null),
        child: const ReaderScreen(chapterUrl: '/chapter-1/'),
      ),
    );

    expect(find.text('تعذر فتح الفصل'), findsOneWidget);
  });
}

class _ReaderTestApp extends StatelessWidget {
  const _ReaderTestApp({required this.child, this.config = const AppConfig()});

  final Widget child;
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      config: config,
      homeRepository: const FakeHomeRepository(),
      catalogRepository: const FakeCatalogRepository(),
      novelRepository: const FakeNovelRepository(result: null),
      child: MaterialApp(
        locale: const Locale('ar'),
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );
  }
}
