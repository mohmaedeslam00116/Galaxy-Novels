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
import '../../comments/application/comments_repository.dart';
import '../../favorites/application/favorites_repository.dart';
import '../../favorites/domain/favorite_item.dart';
import '../../novel_engagement/application/novel_engagement_controller.dart';
import '../../novel_engagement/application/novel_engagement_repository.dart';
import '../../novel_engagement/presentation/novel_rating_sheet.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../vip/application/vip_chapters_controller.dart';
import '../../vip/application/vip_repository.dart';
import 'widgets/novel_details_content.dart';

const _isVipNativeReaderAvailable = true;

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
  NovelEngagementRepository? _novelEngagementRepository;
  CommentsRepository? _commentsRepository;
  VipRepository? _vipRepository;
  NovelEngagementController? _novelEngagementController;
  VipChaptersController? _vipChaptersController;
  int? _loadedNovelId;
  String _loadedNovelTitle = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.of(context);
    final vipRepository = dependencies.vipRepository;
    if (_vipRepository != vipRepository) {
      _vipRepository = vipRepository;
      final novelId = _loadedNovelId;
      if (novelId != null) {
        _recreateVipController(novelId);
      }
    }

    final repository = dependencies.novelRepository;
    if (_repository != repository) {
      _repository = repository;
      _future = _loadNovel(repository);
    }

    final authRepository = dependencies.authRepository;
    final authRepositoryChanged = _authRepository != authRepository;
    if (_authRepository != authRepository) {
      _authRepository?.removeListener(_handleAuthChanged);
      _authRepository = authRepository;
      authRepository.addListener(_handleAuthChanged);
    }
    _favoritesRepository = dependencies.favoritesRepository;
    _commentsRepository = dependencies.commentsRepository;
    _loadFavoritesIfAuthenticated();

    final engagementRepository = dependencies.novelEngagementRepository;
    if (_novelEngagementRepository != engagementRepository ||
        authRepositoryChanged) {
      _novelEngagementController?.dispose();
      _novelEngagementRepository = engagementRepository;
      _novelEngagementController = NovelEngagementController(
        repository: engagementRepository,
        authRepository: authRepository,
      );
      final novelId = _loadedNovelId;
      if (novelId != null) {
        unawaited(_novelEngagementController!.loadNovel(novelId));
      }
    }

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

          final engagementController = _novelEngagementController!;
          return ValueListenableBuilder<NovelEngagementState>(
            valueListenable: engagementController,
            builder: (context, engagementState, _) {
              return NovelDetailsContent(
                loadResult: snapshot.data!,
                engagementState: engagementState,
                commentsRepository: _commentsRepository!,
                authRepository: _authRepository!,
                vipController: _vipChaptersController!,
                isVipNativeReaderAvailable: _isVipNativeReaderAvailable,
                onRead: _openReader,
                onOpenVipChapter: _openVipReader,
                onDownloadChapters: () => _openDownloadSheet(snapshot.data!),
                onToggleFavorite: () => _toggleFavorite(snapshot.data!.details),
                onRate: _openRatingSheet,
                onSignIn: _openAccountScreen,
                onRetryEngagement: engagementController.retry,
              );
            },
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
      _future = _loadNovel(repository);
    });
  }

  Future<NovelDetailsLoadResult> _loadNovel(NovelRepository repository) async {
    final novelLoad = await repository.loadNovel(widget.manifestPath);
    if (mounted && identical(_repository, repository)) {
      _loadedNovelId = novelLoad.details.id;
      _loadedNovelTitle = novelLoad.details.title;
      _recreateVipController(novelLoad.details.id);
      unawaited(_novelEngagementController?.loadNovel(novelLoad.details.id));
    }
    return novelLoad;
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
        action: SnackBarAction(label: 'حسابي', onPressed: _openAccountScreen),
      ),
    );
  }

  void _openAccountScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AccountScreen()));
  }

  Future<void> _openRatingSheet() async {
    final controller = _novelEngagementController;
    if (controller == null) {
      return;
    }
    if (_authRepository?.value.status != AuthSessionStatus.authenticated) {
      _openAccountScreen();
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => NovelRatingSheet(
        initialRating: controller.value.userState?.myRating ?? 0,
        onSubmit: controller.submitRating,
      ),
    );
    if (!mounted || saved != true) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ تقييمك')));
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

  void _openVipReader(String contentApi, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReaderScreen(
          contentApi: contentApi,
          chapterTitle: title,
          novelTitle: _loadedNovelTitle,
        ),
      ),
    );
  }

  void _recreateVipController(int novelId) {
    final repository = _vipRepository;
    if (repository == null) {
      return;
    }
    _vipChaptersController?.dispose();
    _vipChaptersController = VipChaptersController(
      repository: repository,
      novelId: novelId,
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
    _novelEngagementController?.dispose();
    _vipChaptersController?.dispose();
    super.dispose();
  }
}
