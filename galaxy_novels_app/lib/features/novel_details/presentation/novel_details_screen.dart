import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../data/models/novel_details_data.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/novel_repository.dart';
import '../../../data/repositories/reading_history_repository.dart';
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
import 'novel_details_visual_tokens.dart';
import 'novel_details_transition.dart';
import 'widgets/favorite_toggle_button.dart';
import 'widgets/novel_details_content.dart';

const _isVipDirectContentRouteAvailable = true;

class NovelDetailsScreen extends StatefulWidget {
  const NovelDetailsScreen({
    required this.manifestPath,
    this.transition,
    super.key,
  });

  final String manifestPath;
  final NovelDetailsTransitionData? transition;

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  Future<NovelDetailsLoadResult>? _future;
  NovelRepository? _repository;
  AuthRepository? _authRepository;
  FavoritesRepository? _favoritesRepository;
  NovelEngagementRepository? _novelEngagementRepository;
  CommentsRepository? _commentsRepository;
  ReadingHistoryRepository? _readingHistoryRepository;
  VipRepository? _vipRepository;
  NovelEngagementController? _novelEngagementController;
  VipChaptersController? _vipChaptersController;
  int? _loadedNovelId;
  String _loadedNovelTitle = '';
  String _loadedNovelCover = '';
  ReadingProgress? _readingProgress;
  int _readingProgressGeneration = 0;

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

    final readingHistoryRepository = dependencies.readingHistoryRepository;
    if (_readingHistoryRepository != readingHistoryRepository) {
      _readingHistoryRepository?.removeListener(_handleReadingHistoryChanged);
      _readingHistoryRepository = readingHistoryRepository;
      readingHistoryRepository.addListener(_handleReadingHistoryChanged);
      unawaited(_refreshReadingProgress());
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NovelDetailsLoadResult>(
      future: _future,
      builder: (context, snapshot) {
        final loadResult = snapshot.data;
        final tokens = NovelDetailsVisualTokens.of(context);
        final motionTransition = MediaQuery.disableAnimationsOf(context)
            ? null
            : widget.transition;
        return Scaffold(
          backgroundColor: tokens.background,
          appBar: loadResult == null
              ? AppBar(
                  backgroundColor: tokens.background,
                  surfaceTintColor: Colors.transparent,
                  title: Text(widget.transition?.title ?? 'تفاصيل الرواية'),
                )
              : null,
          body: _buildBody(snapshot, motionTransition),
        );
      },
    );
  }

  Widget _buildBody(
    AsyncSnapshot<NovelDetailsLoadResult> snapshot,
    NovelDetailsTransitionData? transition,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return NovelDetailsSkeleton(transition: transition);
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
          readingProgress: _readingProgress,
          commentsRepository: _commentsRepository!,
          authRepository: _authRepository!,
          vipController: _vipChaptersController!,
          isVipNativeReaderAvailable: _isVipDirectContentRouteAvailable,
          onRead: _openReader,
          onOpenVipChapter: _openVipReader,
          onRate: _openRatingSheet,
          onSignIn: _openAccountScreen,
          onRetryEngagement: engagementController.retry,
          favoriteAction: FavoriteToggleButton(
            novelId: snapshot.data!.details.id,
            authRepository: _authRepository!,
            favoritesRepository: _favoritesRepository!,
            onPressed: () => _toggleFavorite(snapshot.data!.details),
          ),
          heroTag: transition?.heroTag,
        );
      },
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
      _loadedNovelCover = novelLoad.details.bestCover;
      _recreateVipController(novelLoad.details.id);
      unawaited(_novelEngagementController?.loadNovel(novelLoad.details.id));
      unawaited(_refreshReadingProgress());
    }
    return novelLoad;
  }

  void _handleAuthChanged() => _loadFavoritesIfAuthenticated();

  void _loadFavoritesIfAuthenticated() {
    if (_authRepository?.value.status == AuthSessionStatus.authenticated) {
      unawaited(_favoritesRepository?.load());
    }
  }

  void _handleReadingHistoryChanged() {
    unawaited(_refreshReadingProgress());
  }

  Future<void> _refreshReadingProgress() async {
    final repository = _readingHistoryRepository;
    if (repository == null) {
      return;
    }

    final generation = ++_readingProgressGeneration;
    late final List<ReadingProgress> history;
    try {
      history = await repository.load();
    } catch (_) {
      return;
    }
    if (!mounted ||
        generation != _readingProgressGeneration ||
        !identical(repository, _readingHistoryRepository)) {
      return;
    }

    final novelId = _loadedNovelId;
    ReadingProgress? nextProgress;
    if (novelId != null) {
      for (final progress in history) {
        if (progress.novelId == novelId) {
          nextProgress = progress;
          break;
        }
      }
    }

    if (_sameReadingProgress(_readingProgress, nextProgress)) {
      return;
    }
    setState(() => _readingProgress = nextProgress);
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
    final toggleResult = await _favoritesRepository!.toggle(
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
    if (!mounted || toggleResult == FavoriteToggleResult.signInRequired) {
      return;
    }
    if (toggleResult == FavoriteToggleResult.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ المفضلة على الجهاز.')),
      );
      return;
    }
    if (toggleResult == FavoriteToggleResult.limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى للمفضلة هو 300 رواية.')),
      );
      return;
    }
    final message = toggleResult == FavoriteToggleResult.added
        ? 'أضيفت الرواية إلى المفضلة'
        : 'أزيلت الرواية من المفضلة';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSignInMessage() {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('سجّل الدخول لإضافة الرواية إلى مفضلتك.'),
        action: SnackBarAction(
          label: 'حسابي',
          onPressed: () => _pushAccountScreen(navigator),
        ),
      ),
    );
  }

  void _openAccountScreen() {
    _pushAccountScreen(Navigator.of(context));
  }

  void _pushAccountScreen(NavigatorState navigator) {
    if (!navigator.mounted) return;
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.account),
        builder: (_) => const AccountScreen(),
      ),
    );
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
        settings: const RouteSettings(name: AppScreenNames.reader),
        builder: (context) => ReaderScreen(
          contentApi: chapter.effectiveContentApi,
          chapterTitle: chapter.label,
          novelTitle: novelTitle,
          coverUrl: _loadedNovelCover,
        ),
      ),
    );
  }

  void _openVipReader(String contentApi, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.reader),
        builder: (context) => ReaderScreen(
          contentApi: contentApi,
          chapterTitle: title,
          novelTitle: _loadedNovelTitle,
          coverUrl: _loadedNovelCover,
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

  @override
  void dispose() {
    _readingProgressGeneration++;
    _readingHistoryRepository?.removeListener(_handleReadingHistoryChanged);
    _authRepository?.removeListener(_handleAuthChanged);
    _novelEngagementController?.dispose();
    _vipChaptersController?.dispose();
    super.dispose();
  }
}

bool _sameReadingProgress(ReadingProgress? current, ReadingProgress? next) {
  return current?.novelId == next?.novelId &&
      current?.chapterId == next?.chapterId &&
      current?.contentApi == next?.contentApi &&
      current?.updatedAt == next?.updatedAt;
}
