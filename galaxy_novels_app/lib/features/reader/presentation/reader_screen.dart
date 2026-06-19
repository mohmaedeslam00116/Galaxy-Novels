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
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          if (_progress < 100 && _error == null)
            LinearProgressIndicator(
              value: _progress == 0 ? null : _progress / 100,
              minHeight: 2,
            ),
          Expanded(
            child: _error == null
                ? (builder ?? _defaultWebViewBuilder)(context, webViewConfig)
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
