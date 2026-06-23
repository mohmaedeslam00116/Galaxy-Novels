import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../../data/repositories/novel_repository.dart';
import '../../downloads/application/download_manager.dart';
import '../../downloads/presentation/download_chapters_sheet.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../../account/presentation/account_screen.dart';
import '../../favorites/application/favorites_repository.dart';
import '../../favorites/domain/favorite_item.dart';
import '../../reader/presentation/reader_screen.dart';
import 'widgets/novel_details_content.dart';

class NovelDetailsScreen extends StatefulWidget {
  const NovelDetailsScreen({required this.manifestPath, super.key});

  final String manifestPath;

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  Future<NovelDetailsLoadResult>? _future;
  NovelRepository? _repository;
  DownloadsRepository? _downloadsRepository;
  DownloadManager? _downloadManager;
  AuthRepository? _authRepository;
  FavoritesRepository? _favoritesRepository;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppDependencies.of(context).novelRepository;
    if (_repository != repository) {
      _repository = repository;
      _future = repository.loadNovel(widget.manifestPath);
    }

    final dependencies = AppDependencies.of(context);
    final authRepository = dependencies.authRepository;
    if (_authRepository != authRepository) {
      _authRepository?.removeListener(_handleAuthChanged);
      _authRepository = authRepository;
      authRepository.addListener(_handleAuthChanged);
    }
    _favoritesRepository = dependencies.favoritesRepository;
    _loadFavoritesIfAuthenticated();

    final downloadsRepository = dependencies.downloadsRepository;
    if (_downloadsRepository != downloadsRepository) {
      _downloadsRepository = downloadsRepository;
      unawaited(downloadsRepository.load());
    }
    _downloadManager = dependencies.downloadManager;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الرواية')),
      body: FutureBuilder<NovelDetailsLoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const NovelDetailsSkeleton();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return NovelDetailsMessage(
              title: 'تعذر تحميل تفاصيل الرواية الآن',
              actionLabel: 'إعادة المحاولة',
              onAction: _retry,
            );
          }

          return NovelDetailsContent(
            loadResult: snapshot.data!,
            onRead: _openReader,
            onDownloadChapters: () => _openDownloadSheet(snapshot.data!),
            onToggleFavorite: () => _toggleFavorite(snapshot.data!.details),
          );
        },
      ),
    );
  }

  void _retry() {
    final repository = _repository;
    if (repository == null) {
      return;
    }
    setState(() {
      _future = repository.loadNovel(widget.manifestPath);
    });
  }

  void _handleAuthChanged() => _loadFavoritesIfAuthenticated();

  void _loadFavoritesIfAuthenticated() {
    if (_authRepository?.value.status == AuthSessionStatus.authenticated) {
      unawaited(_favoritesRepository?.load());
    }
  }

  Future<void> _toggleFavorite(NovelDetails details) async {
    final authRepository = _authRepository!;
    if (authRepository.value.status == AuthSessionStatus.idle ||
        authRepository.value.status == AuthSessionStatus.failure) {
      await authRepository.restoreSession();
    }
    if (!mounted) {
      return;
    }
    if (authRepository.value.status != AuthSessionStatus.authenticated) {
      _showSignInMessage();
      return;
    }

    await _favoritesRepository!.load();
    final result = await _favoritesRepository!.toggle(
      FavoriteItem(
        id: details.id,
        title: details.title,
        url: details.url,
        cover: details.bestCover,
        manifestPath: details.manifest.isEmpty
            ? widget.manifestPath
            : details.manifest,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
    );
    if (!mounted || result == FavoriteToggleResult.signInRequired) {
      return;
    }
    if (result == FavoriteToggleResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ المفضلة على الجهاز.')),
      );
      return;
    }
    if (result == FavoriteToggleResult.limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى للمفضلة هو 300 رواية.')),
      );
      return;
    }
    final message = result == FavoriteToggleResult.added
        ? 'أضيفت الرواية إلى المفضلة'
        : 'أزيلت الرواية من المفضلة';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSignInMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('سجّل الدخول لإضافة الرواية إلى مفضلتك.'),
        action: SnackBarAction(
          label: 'حسابي',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
            );
          },
        ),
      ),
    );
  }

  void _openReader(NovelChapter chapter, String novelTitle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: chapter.effectiveContentApi,
          chapterTitle: chapter.label,
          novelTitle: novelTitle,
        ),
      ),
    );
  }

  Future<void> _openDownloadSheet(NovelDetailsLoadResult result) async {
    final repository = _downloadsRepository;
    if (repository == null || result.chapters.isEmpty) {
      return;
    }
    if (_downloadManager?.state.value.isActive ?? false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يوجد تنزيل جار بالفعل')));
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ValueListenableBuilder<DownloadsState>(
          valueListenable: repository.state,
          builder: (context, downloadsState, _) {
            return DownloadChaptersSheet(
              details: result.details,
              chapters: result.chapters,
              downloadsState: downloadsState,
              onStart: (chapters) => _startBatchDownload(result, chapters),
            );
          },
        );
      },
    );
  }

  void _startBatchDownload(
    NovelDetailsLoadResult result,
    List<NovelChapter> chapters,
  ) {
    final manager = _downloadManager;
    if (manager == null || chapters.isEmpty) {
      return;
    }

    final requests = chapters
        .map(
          (chapter) => ChapterDownloadRequest(
            novelId: result.details.id,
            novelTitle: result.details.title,
            novelCover: result.details.bestCover,
            chapter: chapter,
          ),
        )
        .toList(growable: false);

    try {
      unawaited(manager.startBatch(requests).catchError((_) {}));
    } on DownloadJobInProgressException {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يوجد تنزيل جار بالفعل')));
    }
  }

  @override
  void dispose() {
    _authRepository?.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
