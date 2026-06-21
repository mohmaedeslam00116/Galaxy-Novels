import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/reader_content_data.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../data/repositories/reader_repository.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../application/reader_preferences_repository.dart';
import 'native_reader_content.dart';
import 'reader_preferences.dart';
import 'reader_settings_sheet.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.contentApi,
    this.chapterTitle,
    this.novelTitle,
    super.key,
  });

  final String contentApi;
  final String? chapterTitle;
  final String? novelTitle;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late String _contentApi;
  String? _chapterTitle;
  ReaderPreferences _preferences = ReaderPreferences.defaults;
  Future<ReaderChapterContent>? _future;
  ReaderRepository? _repository;
  ReadingHistoryRepository? _historyRepository;
  DownloadsRepository? _downloadsRepository;
  ReaderPreferencesRepository? _preferencesRepository;

  @override
  void initState() {
    super.initState();
    _contentApi = widget.contentApi;
    _chapterTitle = widget.chapterTitle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.of(context);
    final repository = dependencies.readerRepository;
    final historyRepository = dependencies.readingHistoryRepository;
    final downloadsRepository = dependencies.downloadsRepository;
    final preferencesRepository = dependencies.readerPreferencesRepository;
    if (_repository != repository ||
        _historyRepository != historyRepository ||
        _downloadsRepository != downloadsRepository) {
      _repository = repository;
      _historyRepository = historyRepository;
      _downloadsRepository = downloadsRepository;
      _future = _loadChapter(_contentApi);
    }

    if (_preferencesRepository != preferencesRepository) {
      _preferencesRepository?.removeListener(_syncPreferences);
      _preferencesRepository = preferencesRepository;
      _preferences = preferencesRepository.value;
      preferencesRepository.addListener(_syncPreferences);
      unawaited(preferencesRepository.load());
    }
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentApi != oldWidget.contentApi ||
        widget.chapterTitle != oldWidget.chapterTitle) {
      _contentApi = widget.contentApi;
      _chapterTitle = widget.chapterTitle;
      _future = _loadChapter(_contentApi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chapterTitle ?? 'القارئ')),
      body: FutureBuilder<ReaderChapterContent>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _ReaderLoadingView();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _ReaderErrorView(
              message: 'تعذر تحميل الفصل',
              details: snapshot.error?.toString(),
              onRetry: _retry,
            );
          }

          return NativeReaderContent(
            content: snapshot.data!,
            preferences: _preferences,
            onOpenChapter: _openChapter,
            onOpenSettings: _openReaderSettings,
          );
        },
      ),
    );
  }

  void _retry() {
    final repository = AppDependencies.of(context).readerRepository;
    setState(() {
      _repository = repository;
      _future = _loadChapter(_contentApi);
    });
  }

  void _openChapter(String contentApi, String title) {
    if (contentApi.isEmpty) {
      return;
    }

    final repository = AppDependencies.of(context).readerRepository;
    setState(() {
      _repository = repository;
      _contentApi = contentApi;
      _chapterTitle = title;
      _future = _loadChapter(contentApi);
    });
  }

  Future<ReaderChapterContent> _loadChapter(String contentApi) async {
    final repository = _repository;
    final downloadsRepository = _downloadsRepository;
    if (repository == null || downloadsRepository == null) {
      throw StateError('Reader repository is not ready.');
    }

    final localContent = await downloadsRepository.findReaderContent(
      contentApi,
    );
    if (localContent != null) {
      await downloadsRepository.markOpened(contentApi);
      await _recordProgress(localContent);
      return localContent;
    }

    final content = await repository.loadChapter(contentApi);
    await _recordProgress(content);
    return content;
  }

  Future<void> _recordProgress(ReaderChapterContent content) async {
    final historyRepository = _historyRepository;
    if (historyRepository == null) {
      return;
    }

    await historyRepository.record(
      ReadingProgress(
        novelId: content.novelId,
        novelTitle: widget.novelTitle ?? '',
        chapterId: content.id,
        chapterTitle: content.effectiveTitle,
        contentApi: _contentApi,
        chapterPosition: content.position,
        chaptersTotal: content.total,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _openReaderSettings() {
    showReaderSettingsSheet(
      context: context,
      preferences: _preferences,
      onChanged: (preferences) => unawaited(_savePreferences(preferences)),
    );
  }

  void _syncPreferences() {
    final preferences = _preferencesRepository?.value;
    if (!mounted || preferences == null || preferences == _preferences) {
      return;
    }
    setState(() => _preferences = preferences);
  }

  Future<void> _savePreferences(ReaderPreferences preferences) async {
    try {
      await _preferencesRepository?.update(preferences);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حفظ إعدادات القراءة')));
    }
  }

  @override
  void dispose() {
    _preferencesRepository?.removeListener(_syncPreferences);
    super.dispose();
  }
}

class _ReaderLoadingView extends StatelessWidget {
  const _ReaderLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(strokeWidth: 3),
      ),
    );
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
