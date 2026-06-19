# Galaxy Novels Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first public chapter reader that opens Galaxy Novels chapter HTML in app-reader mode from the existing novel details screen.

**Architecture:** Keep the current imperative `Navigator.push` approach and pass reader data by constructor. Put reader URL normalization in a small testable helper, keep the actual WebView behind a thin widget, and let `ReaderScreen` own loading, retry, and error chrome.

**Tech Stack:** Flutter, Material 3, `webview_flutter`, Flutter unit tests, Flutter widget tests.

---

## File Structure

- Create `lib/features/reader/data/reader_url_builder.dart`
  - Builds the final public reader URI from `AppConfig` and a chapter URL.
- Create `lib/features/reader/presentation/reader_web_view.dart`
  - Wraps `webview_flutter` and reports progress/errors to the screen.
- Create `lib/features/reader/presentation/reader_screen.dart`
  - Presents app chrome, loading progress, retry state, and the WebView body.
- Modify `lib/features/novel_details/presentation/novel_details_screen.dart`
  - Replace the placeholder SnackBar with navigation to `ReaderScreen`.
- Modify `pubspec.yaml`
  - Add `webview_flutter`.
- Create `test/features/reader/reader_url_builder_test.dart`
  - Unit tests for reader URL normalization.
- Create `test/features/reader/reader_screen_test.dart`
  - Widget tests for reader chrome, fake WebView, and invalid URL/retry states.
- Modify `test/widget_test.dart`
  - Update the novel details flow to assert tapping `ابدأ القراءة` opens the reader.

## Task 1: Reader URL Builder

**Files:**
- Create: `lib/features/reader/data/reader_url_builder.dart`
- Create: `test/features/reader/reader_url_builder_test.dart`

- [ ] **Step 1: Write the failing URL builder tests**

Create `test/features/reader/reader_url_builder_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/config/app_config.dart';
import 'package:galaxy_novels_app/features/reader/data/reader_url_builder.dart';

void main() {
  const config = AppConfig(siteBaseUrl: 'https://galaxynovels.com/');

  test('resolves a relative chapter URL and enables app reader mode', () {
    final uri = buildPublicReaderUri(
      config: config,
      chapterUrl: '/novel/example/chapter-1/',
    );

    expect(
      uri.toString(),
      'https://galaxynovels.com/novel/example/chapter-1/?wr_app_reader=1',
    );
  });

  test('preserves existing query parameters', () {
    final uri = buildPublicReaderUri(
      config: config,
      chapterUrl: '/novel/example/chapter-1/?from=app',
    );

    expect(uri.queryParameters['from'], 'app');
    expect(uri.queryParameters['wr_app_reader'], '1');
  });

  test('normalizes an existing app reader query value', () {
    final uri = buildPublicReaderUri(
      config: config,
      chapterUrl: 'https://galaxynovels.com/novel/example/chapter-1/?wr_app_reader=0',
    );

    expect(uri.queryParameters['wr_app_reader'], '1');
  });
}
```

- [ ] **Step 2: Run the failing URL builder tests**

Run:

```powershell
flutter test test/features/reader/reader_url_builder_test.dart
```

Expected: FAIL because `reader_url_builder.dart` does not exist.

- [ ] **Step 3: Implement the URL builder**

Create `lib/features/reader/data/reader_url_builder.dart`:

```dart
import '../../../core/config/app_config.dart';

Uri buildPublicReaderUri({
  required AppConfig config,
  required String chapterUrl,
}) {
  final resolved = config.resolve(chapterUrl);
  final queryParameters = Map<String, String>.from(resolved.queryParameters);
  queryParameters['wr_app_reader'] = '1';
  return resolved.replace(queryParameters: queryParameters);
}
```

- [ ] **Step 4: Run the URL builder tests**

Run:

```powershell
flutter test test/features/reader/reader_url_builder_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit URL builder**

Run:

```powershell
git add lib/features/reader/data/reader_url_builder.dart test/features/reader/reader_url_builder_test.dart
git commit -m "feat: add reader URL builder"
```

## Task 2: WebView Dependency And Wrapper

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/features/reader/presentation/reader_web_view.dart`

- [ ] **Step 1: Add the WebView dependency**

Run:

```powershell
flutter pub add webview_flutter
```

Expected: `pubspec.yaml` and `pubspec.lock` include `webview_flutter`.

- [ ] **Step 2: Create the WebView wrapper**

Create `lib/features/reader/presentation/reader_web_view.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

typedef ReaderErrorCallback = void Function(String message);

class ReaderWebViewConfig {
  const ReaderWebViewConfig({
    required this.initialUri,
    required this.userAgent,
    required this.onProgress,
    required this.onLoadError,
  });

  final Uri initialUri;
  final String userAgent;
  final ValueChanged<int> onProgress;
  final ReaderErrorCallback onLoadError;
}

class ReaderWebView extends StatefulWidget {
  const ReaderWebView({required this.config, super.key});

  final ReaderWebViewConfig config;

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setUserAgent(widget.config.userAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: widget.config.onProgress,
          onWebResourceError: (error) {
            widget.config.onLoadError(error.description);
          },
          onNavigationRequest: (request) {
            final requestedUri = Uri.tryParse(request.url);
            if (requestedUri == null) {
              return NavigationDecision.prevent;
            }
            if (requestedUri.host == widget.config.initialUri.host) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.config.initialUri);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
```

- [ ] **Step 3: Run dependency resolution**

Run:

```powershell
flutter pub get
```

Expected: dependency resolution succeeds.

- [ ] **Step 4: Commit WebView wrapper**

Run:

```powershell
git add pubspec.yaml pubspec.lock lib/features/reader/presentation/reader_web_view.dart
git commit -m "feat: add reader webview wrapper"
```

## Task 3: Reader Screen

**Files:**
- Create: `lib/features/reader/presentation/reader_screen.dart`
- Create: `test/features/reader/reader_screen_test.dart`

- [ ] **Step 1: Write the failing reader screen widget tests**

Create `test/features/reader/reader_screen_test.dart`:

```dart
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
  const _ReaderTestApp({
    required this.child,
    this.config = const AppConfig(),
  });

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
```

- [ ] **Step 2: Run the failing reader screen tests**

Run:

```powershell
flutter test test/features/reader/reader_screen_test.dart
```

Expected: FAIL because `reader_screen.dart` does not exist.

- [ ] **Step 3: Implement `ReaderScreen`**

Create `lib/features/reader/presentation/reader_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../data/reader_url_builder.dart';
import 'reader_web_view.dart';

typedef ReaderWebViewBuilder =
    Widget Function(BuildContext context, ReaderWebViewConfig config);

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.chapterUrl,
    this.chapterTitle,
    this.webViewBuilder,
    super.key,
  });

  final String chapterUrl;
  final String? chapterTitle;
  final ReaderWebViewBuilder? webViewBuilder;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _progress = 0;
  String? _error;
  int _reloadToken = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = AppDependencies.of(context).config;
    final Uri readerUri;

    try {
      readerUri = buildPublicReaderUri(
        config: config,
        chapterUrl: widget.chapterUrl,
      );
    } on Object {
      return Scaffold(
        appBar: AppBar(title: const Text('القارئ')),
        body: const _ReaderErrorView(message: 'تعذر فتح الفصل'),
      );
    }

    final webViewConfig = ReaderWebViewConfig(
      initialUri: readerUri,
      userAgent: config.userAgent,
      onProgress: (value) {
        if (!mounted) {
          return;
        }
        setState(() {
          _progress = value;
          if (value > 0) {
            _error = null;
          }
        });
      },
      onLoadError: (message) {
        if (!mounted) {
          return;
        }
        setState(() => _error = message);
      },
    );

    final builder = widget.webViewBuilder;

    return Scaffold(
      appBar: AppBar(title: Text(widget.chapterTitle ?? 'القارئ')),
      body: Column(
        children: [
          if (_progress < 100 && _error == null)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100,
              minHeight: 2,
            ),
          Expanded(
            child: _error == null
                ? (builder ?? _defaultWebViewBuilder)(
                    context,
                    webViewConfig,
                  )
                : _ReaderErrorView(
                    message: 'تعذر تحميل الفصل',
                    details: _error,
                    onRetry: () {
                      setState(() {
                        _error = null;
                        _progress = 0;
                        _reloadToken++;
                      });
                    },
                  ),
          ),
        ],
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }

  Widget _defaultWebViewBuilder(
    BuildContext context,
    ReaderWebViewConfig config,
  ) {
    return ReaderWebView(key: ValueKey(_reloadToken), config: config);
  }
}

class _ReaderErrorView extends StatelessWidget {
  const _ReaderErrorView({required this.message, this.details, this.onRetry});

  final String message;
  final String? details;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              color: theme.colorScheme.primary,
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run the reader screen tests**

Run:

```powershell
flutter test test/features/reader/reader_screen_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit reader screen**

Run:

```powershell
git add lib/features/reader/presentation/reader_screen.dart test/features/reader/reader_screen_test.dart
git commit -m "feat: add public reader screen"
```

## Task 4: Navigate From Novel Details

**Files:**
- Modify: `lib/features/novel_details/presentation/novel_details_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing navigation assertion**

Modify the existing `opens novel details from the catalog` test in `test/widget_test.dart` after the `expect(find.text('ابدأ القراءة'), findsOneWidget);` line:

```dart
    await tester.tap(find.text('ابدأ القراءة'));
    await tester.pumpAndSettle();

    expect(find.text('الفصل 1'), findsWidgets);
    expect(find.text('القارئ سيكون في المرحلة التالية'), findsNothing);
```

Expected behavior: this should fail while the placeholder SnackBar still exists.

- [ ] **Step 2: Run the failing widget test**

Run:

```powershell
flutter test test/widget_test.dart --plain-name "opens novel details from the catalog"
```

Expected: FAIL because tapping `ابدأ القراءة` does not navigate to `ReaderScreen`.

- [ ] **Step 3: Navigate to `ReaderScreen` from details**

Modify `lib/features/novel_details/presentation/novel_details_screen.dart`:

```dart
import '../../reader/presentation/reader_screen.dart';
```

Replace `_showReaderPlaceholder` with:

```dart
  void _openReader(String chapterUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(chapterUrl: chapterUrl),
      ),
    );
  }
```

Replace:

```dart
            onRead: _showReaderPlaceholder,
```

with:

```dart
            onRead: _openReader,
```

- [ ] **Step 4: Run the details navigation test**

Run:

```powershell
flutter test test/widget_test.dart --plain-name "opens novel details from the catalog"
```

Expected: PASS.

- [ ] **Step 5: Commit details navigation**

Run:

```powershell
git add lib/features/novel_details/presentation/novel_details_screen.dart test/widget_test.dart
git commit -m "feat: open reader from novel details"
```

## Task 5: Verification

**Files:**
- Verify all changed Dart files and tests.

- [ ] **Step 1: Format changed files**

Run:

```powershell
dart format lib/features/reader lib/features/novel_details/presentation/novel_details_screen.dart test/features/reader test/widget_test.dart
```

Expected: formatter exits successfully.

- [ ] **Step 2: Analyze the project**

Run:

```powershell
dart analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run focused tests**

Run:

```powershell
flutter test test/features/reader test/widget_test.dart --plain-name "opens novel details from the catalog"
```

Expected: all focused tests pass.

- [ ] **Step 4: Run the full test suite**

Run:

```powershell
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Build a debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK builds successfully.

- [ ] **Step 6: Report final status**

Run:

```powershell
git status --short
```

Expected: only unrelated pre-existing untracked files remain.
