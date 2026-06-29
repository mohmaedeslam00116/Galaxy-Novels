import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/chapter_summary.dart';
import '../../../data/models/home_data.dart';
import '../../../data/models/novel_summary.dart';
import '../../../data/models/reading_progress.dart' as local_progress;
import '../../../data/repositories/home_repository.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../shared/widgets/novel_poster_tile.dart';
import '../../../shared/widgets/section_title.dart';
import '../../novel_details/presentation/novel_details_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import 'home_continue_reading.dart';
import 'latest_updates_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeRepository? _repository;
  ReadingHistoryRepository? _historyRepository;
  Future<HomeData>? _homeFuture;
  Future<List<local_progress.ReadingProgress>>? _historyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final dependencies = AppDependencies.of(context);
    final repository = dependencies.homeRepository;
    final historyRepository = dependencies.readingHistoryRepository;
    if (_repository != repository) {
      _repository = repository;
      _homeFuture = repository.loadHome();
    }
    if (_historyRepository != historyRepository) {
      _historyRepository?.removeListener(_refreshHistory);
      _historyRepository = historyRepository;
      historyRepository.addListener(_refreshHistory);
      _historyFuture = historyRepository.load();
    }
  }

  @override
  void dispose() {
    _historyRepository?.removeListener(_refreshHistory);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _HomeStateMessage(message: 'جار تحميل الرئيسية...');
        }

        if (snapshot.hasError) {
          return const _HomeStateMessage(message: 'تعذر تحميل الرئيسية الآن');
        }

        final home = snapshot.data;
        if (home == null) {
          return const _HomeStateMessage(message: 'لا توجد بيانات للعرض');
        }

        return FutureBuilder<List<local_progress.ReadingProgress>>(
          future: _historyFuture,
          builder: (context, historySnapshot) {
            final history = historySnapshot.data ?? const [];
            if (home.isEmpty && history.isEmpty) {
              return const _HomeStateMessage(message: 'لا توجد بيانات للعرض');
            }
            return _buildHome(home, history.isEmpty ? null : history.first);
          },
        );
      },
    );
  }

  Widget _buildHome(
    HomeData home,
    local_progress.ReadingProgress? localProgress,
  ) {
    final novelsById = {for (final novel in home.recentNovels) novel.id: novel};
    final HomeContinueReadingEntry? continueReading;
    if (localProgress != null) {
      continueReading = HomeContinueReadingEntry.fromLocal(localProgress);
    } else if (home.continueReading != null) {
      continueReading = HomeContinueReadingEntry.fromHome(
        home.continueReading!,
      );
    } else {
      continueReading = null;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        if (continueReading != null) ...[
          const SectionTitle(
            title: 'أكمل القراءة',
            leadingIcon: Icons.play_circle_outline_rounded,
          ),
          HomeContinueReadingTile(
            key: const ValueKey('continue-reading-tile'),
            progress: continueReading,
            onTap: _continueReadingAction(continueReading),
          ),
        ],
        if (home.recentNovels.isNotEmpty) ...[
          const SectionTitle(
            title: 'روايات محدثة',
            leadingIcon: Icons.auto_stories_outlined,
          ),
          _RecentNovelsStrip(
            novels: home.recentNovels,
            onNovelTap: _openNovelDetails,
          ),
        ],
        if (home.latestChapters.isNotEmpty)
          LatestUpdatesSection(
            key: const ValueKey('latest-updates-section'),
            chapters: home.latestChapters,
            novelsById: novelsById,
            onChapterTap: _openLatestChapter,
          ),
      ],
    );
  }

  void _refreshHistory() {
    final repository = _historyRepository;
    if (repository == null || !mounted) {
      return;
    }
    setState(() {
      _historyFuture = repository.load();
    });
  }

  void _openContinueReading(HomeContinueReadingEntry progress) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: progress.contentApi,
          chapterTitle: progress.chapterTitle,
          novelTitle: progress.novelTitle,
        ),
      ),
    );
  }

  VoidCallback? _continueReadingAction(HomeContinueReadingEntry progress) {
    if (progress.contentApi.isEmpty) {
      return null;
    }
    return () => _openContinueReading(progress);
  }

  void _openLatestChapter(ChapterSummary chapter) {
    final contentApi = chapter.effectiveContentApi;
    if (contentApi.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: contentApi,
          chapterTitle: chapter.label.isNotEmpty
              ? chapter.label
              : chapter.title,
          novelTitle: chapter.novelTitle,
        ),
      ),
    );
  }

  void _openNovelDetails(String manifestPath) {
    if (manifestPath.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NovelDetailsScreen(manifestPath: manifestPath),
      ),
    );
  }
}

class _RecentNovelsStrip extends StatelessWidget {
  const _RecentNovelsStrip({required this.novels, required this.onNovelTap});

  final List<NovelSummary> novels;
  final ValueChanged<String> onNovelTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('updated-novels-strip'),
      height: NovelPosterTile.height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: novels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final novel = novels[index];
          final onTap = novel.manifest.isEmpty
              ? null
              : () => onNovelTap(novel.manifest);
          return NovelPosterTile(
            title: novel.title,
            imageUrl: novel.coverThumbnail,
            statusLabel: novel.statusLabel,
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _HomeStateMessage extends StatelessWidget {
  const _HomeStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
