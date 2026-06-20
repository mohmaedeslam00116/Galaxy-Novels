import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';
import '../../reader/presentation/reader_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ReadingHistoryRepository? _repository;
  Future<List<ReadingProgress>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).readingHistoryRepository;
    if (_repository != repository) {
      _repository?.removeListener(_refresh);
      _repository = repository;
      _repository?.addListener(_refresh);
      _future = repository.load();
    }
  }

  @override
  void dispose() {
    _repository?.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReadingProgress>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const _HistoryMessage(title: 'تعذر تحميل سجل القراءة');
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const _HistoryMessage(title: 'لا يوجد سجل قراءة بعد');
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const SectionHeader(title: 'آخر القراءات'),
            for (final item in items)
              NovelListTile(
                title: item.displayNovelTitle,
                subtitle: item.displayChapterTitle,
                meta: 'آخر قراءة',
                onTap: () => _openReader(item),
              ),
          ],
        );
      },
    );
  }

  void _refresh() {
    final repository = _repository;
    if (repository == null || !mounted) {
      return;
    }

    setState(() {
      _future = repository.load();
    });
  }

  void _openReader(ReadingProgress progress) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: progress.contentApi,
          chapterTitle: progress.displayChapterTitle,
          novelTitle: progress.displayNovelTitle,
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
