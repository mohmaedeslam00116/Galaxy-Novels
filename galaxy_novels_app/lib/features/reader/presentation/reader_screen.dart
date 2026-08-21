import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../core/platform/app_system_settings.dart';
import '../../../data/models/reader_content_data.dart';
import '../../../data/models/reading_progress.dart';
import '../../../data/repositories/reader_repository.dart';
import '../../../data/repositories/reading_history_repository.dart';
import '../../../shared/widgets/app_async_state.dart';
import '../../account/presentation/account_screen.dart';
import '../../ads/application/standard_ad_visibility_policy.dart';
import '../../app_review/application/app_review_prompt_controller.dart';
import '../../downloads/application/download_repository.dart';
import '../../comments/domain/comment_target.dart';
import '../../comments/presentation/chapter_comments_sheet.dart';
import '../../reading_activity/application/reading_activity_recorder.dart';
import '../application/reader_display_controller.dart';
import '../application/reader_advanced_terminology_repository.dart';
import '../application/reader_preferences_repository.dart';
import '../application/reader_speech_controller.dart';
import '../application/reader_speech_narration.dart';
import '../application/reader_term_replacement_repository.dart';
import '../data/shared_preferences_reader_term_replacement_store.dart';
import '../data/stored_reader_term_replacement_repository.dart';
import '../domain/reader_term_replacement.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_speech_models.dart';
import 'native_reader_content.dart';
import 'reader_chrome_palette.dart';
import 'reader_chrome_visibility.dart';
import 'reader_preferences.dart';
import 'reader_reading_column.dart';
import 'reader_settings_sheet.dart';
import 'reader_speech_player.dart';
import 'reader_stitch_chrome.dart';
import 'reader_term_replacement_dialog.dart';
import 'reader_text_removal_dialog.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    required this.contentApi,
    this.chapterTitle,
    this.novelTitle,
    this.coverUrl = '',
    this.systemSettings = const AppSystemSettings(),
    super.key,
  });

  final String contentApi;
  final String? chapterTitle;
  final String? novelTitle;
  final String coverUrl;
  final AppSystemSettings systemSettings;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver {
  late String _contentApi;
  String? _chapterTitle;
  ReaderPreferences _preferences = ReaderPreferences.defaults;
  Future<ReaderChapterContent>? _future;
  ReaderRepository? _repository;
  ReadingHistoryRepository? _historyRepository;
  ReaderPreferencesRepository? _preferencesRepository;
  ReaderTermReplacementRepository? _termRepository;
  StoredReaderTermReplacementRepository? _ownedTermRepository;
  List<ReaderTermReplacement> _termReplacements = const [];
  ReaderAdvancedTerminologyRepository? _advancedTerminologyRepository;
  ReaderAdvancedTerminologyState _advancedTerminologyState =
      ReaderAdvancedTerminologyState.defaults;
  ReadingActivityRecorder? _activityRecorder;
  ReadingActivitySession? _activitySession;
  AppReviewPromptController? _reviewPromptController;
  final ReaderDisplayController _displayController =
      const ReaderDisplayController();
  bool _activityPaused = false;
  bool _readerChromeVisible = false;
  bool _chapterTransitionPending = false;
  bool _reviewSessionStarted = false;
  int _currentNovelId = 0;
  int _currentChapterId = 0;
  ReaderSpeechController? _speechController;
  _RepositoryReaderSpeechChapterSource? _speechChapterSource;
  ReaderSpeechState _speechState = ReaderSpeechState.idle;
  int _visibleBlockIndex = 0;
  bool _speechFollowEnabled = true;
  int _speechTextRefreshGeneration = 0;

  @override
  void initState() {
    super.initState();
    _contentApi = widget.contentApi;
    _chapterTitle = widget.chapterTitle;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.of(context);
    final repository = dependencies.readerRepository;
    final historyRepository = dependencies.readingHistoryRepository;
    final preferencesRepository = dependencies.readerPreferencesRepository;
    final termRepository =
        dependencies.readerTermReplacementRepository ??
        (_ownedTermRepository ??= StoredReaderTermReplacementRepository(
          store: SharedPreferencesReaderTermReplacementStore(),
        ));
    final activityRecorder = dependencies.readingActivityRecorder;
    _bindSpeechController(
      dependencies.readerSpeechController,
      repository: repository,
    );
    if (_activityRecorder != activityRecorder) {
      _finishActivitySession();
      _activityRecorder = activityRecorder;
    }
    final reviewPromptController = dependencies.appReviewPromptController;
    if (_reviewPromptController != reviewPromptController) {
      if (_reviewSessionStarted) {
        unawaited(_reviewPromptController?.finishReadingSession());
      }
      _reviewPromptController = reviewPromptController;
      _reviewSessionStarted = reviewPromptController != null;
      reviewPromptController?.startReadingSession();
    }
    if (_repository != repository || _historyRepository != historyRepository) {
      _repository = repository;
      _historyRepository = historyRepository;
      _readerChromeVisible = false;
      _future = _loadChapter(_contentApi);
    }

    if (_preferencesRepository != preferencesRepository) {
      _preferencesRepository?.removeListener(_syncPreferences);
      _preferencesRepository = preferencesRepository;
      _preferences = preferencesRepository.value;
      unawaited(_displayController.apply(_preferences));
      preferencesRepository.addListener(_syncPreferences);
      unawaited(preferencesRepository.load());
    }
    if (_termRepository != termRepository) {
      _termRepository?.removeListener(_syncTermReplacements);
      _termRepository = termRepository;
      _termReplacements = termRepository.value;
      termRepository.addListener(_syncTermReplacements);
      unawaited(termRepository.load());
    }
    final advancedTerminologyRepository =
        dependencies.readerAdvancedTerminologyRepository;
    if (_advancedTerminologyRepository != advancedTerminologyRepository) {
      _advancedTerminologyRepository?.removeListener(_syncAdvancedTerminology);
      _advancedTerminologyRepository = advancedTerminologyRepository;
      _advancedTerminologyState =
          advancedTerminologyRepository?.value ??
          ReaderAdvancedTerminologyState.defaults;
      advancedTerminologyRepository?.addListener(_syncAdvancedTerminology);
      if (advancedTerminologyRepository != null) {
        unawaited(advancedTerminologyRepository.load());
      }
    }
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentApi != oldWidget.contentApi ||
        widget.chapterTitle != oldWidget.chapterTitle) {
      _contentApi = widget.contentApi;
      _chapterTitle = widget.chapterTitle;
      _finishActivitySession();
      _readerChromeVisible = false;
      _future = _loadChapter(_contentApi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReaderChapterContent>(
      future: _future,
      builder: (context, snapshot) => _readerScaffold(context, snapshot),
    );
  }

  Widget _readerScaffold(
    BuildContext context,
    AsyncSnapshot<ReaderChapterContent> snapshot,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return Scaffold(
        appBar: _normalAppBar(),
        body: const _ReaderLoadingView(),
      );
    }
    if (snapshot.hasError || !snapshot.hasData) {
      return Scaffold(
        appBar: _normalAppBar(),
        body: _readerFailure(snapshot.error),
      );
    }
    return _loadedReaderScaffold(context, snapshot.data!);
  }

  Widget _loadedReaderScaffold(
    BuildContext context,
    ReaderChapterContent content,
  ) {
    final tabletLandscape = isReaderTabletLandscape(MediaQuery.of(context));
    final chromePalette = resolveReaderChromePalette(
      scheme: Theme.of(context).colorScheme,
    );
    final readerTopBar = ReaderStitchTopBar(
      title: _chapterTitle ?? 'القارئ',
      palette: chromePalette,
      toolbarHeight: tabletLandscape ? 56 : 64,
      actions: (
        autoScrollEnabled: _preferences.autoScrollEnabled,
        speechActive: _speechState.isActive,
        onSpeech: _speechController == null
            ? null
            : () => unawaited(_openSpeechPanel(content)),
        onSettings: _openReaderSettings,
        onToggleAutoScroll: _toggleAutoScroll,
      ),
    );
    final readerContent = NativeReaderContent(
      content: content,
      preferences: _preferences,
      controlsVisible: _readerChromeVisible,
      onRetry: _retry,
      onControlsVisibilityChanged: _setReaderChromeVisibility,
      onOpenChapter: _openChapter,
      onOpenNextChapter: _openNextChapter,
      onOpenComments: () => _openChapterComments(content),
      onReadingActivity: _recordReadingActivity,
      onFontScaleCommitted: _commitFontScale,
      speechState: _speechState,
      speechFollowEnabled: _speechFollowEnabled,
      onSpeechFollowChanged: (enabled) {
        if (_speechFollowEnabled != enabled) {
          setState(() => _speechFollowEnabled = enabled);
        }
      },
      onVisibleBlockChanged: (index) => _visibleBlockIndex = index,
      onStartSpeechFromBlock: _speechController == null
          ? null
          : (index) => _startSpeechFromBlock(content, index),
      termReplacements: _termReplacements,
      advancedTerminologyState: _advancedTerminologyState,
      onTermLongPressed: (source) {
        return _openTermEditor(source: source, novelId: content.novelId);
      },
      onTermRemovalRequested: _advancedTerminologyState.accessUnlocked
          ? (source) =>
                _openTextRemovalEditor(source: source, novelId: content.novelId)
          : null,
    );
    return Scaffold(
      bottomNavigationBar: _speechController == null
          ? null
          : ReaderSpeechMiniPlayer(
              controller: _speechController!,
              onExpand: () => unawaited(_openSpeechPanel(content)),
            ),
      body: SafeArea(
        bottom: false,
        child: tabletLandscape
            ? Column(
                children: [
                  ReaderDockedChromeVisibility(
                    visible: _readerChromeVisible,
                    keys: const ReaderChromeVisibilityKeys(
                      excludeSemantics: ValueKey(
                        'reader-app-bar-exclude-semantics',
                      ),
                      ignorePointer: ValueKey('reader-app-bar-ignore-pointer'),
                    ),
                    child: readerTopBar,
                  ),
                  Expanded(child: readerContent),
                ],
              )
            : Stack(
                children: [
                  Positioned.fill(child: readerContent),
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    end: 0,
                    child: ReaderChromeVisibility(
                      visible: _readerChromeVisible,
                      hiddenOffset: const Offset(0, -1),
                      keys: const ReaderChromeVisibilityKeys(
                        excludeSemantics: ValueKey(
                          'reader-app-bar-exclude-semantics',
                        ),
                        ignorePointer: ValueKey(
                          'reader-app-bar-ignore-pointer',
                        ),
                      ),
                      child: readerTopBar,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  AppBar _normalAppBar() => AppBar(title: Text(_chapterTitle ?? 'القارئ'));

  Widget _readerFailure(Object? error) {
    if (error is DownloadVipLockedException) {
      final message = switch (error.reason) {
        DownloadVipLockReason.signedOut =>
          'سجّل الدخول بحساب VIP لفتح هذا الفصل المحفوظ.',
        DownloadVipLockReason.expired =>
          'انتهت صلاحية العضوية المرتبطة بهذا الفصل المحفوظ.',
        DownloadVipLockReason.verificationRequired =>
          'اتصل بالإنترنت وحدّث حسابك للتحقق من عضوية VIP.',
      };
      return AppAsyncState.empty(
        title: 'فصل VIP مقفل',
        message: message,
        actionLabel: 'فتح حسابي',
        onAction: _openAccount,
      );
    }
    return AppAsyncState.error(
      title: 'تعذر تحميل الفصل',
      message: 'تحقق من اتصالك ثم أعد المحاولة.',
      onRetry: _retry,
    );
  }

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.account),
        builder: (context) => const AccountScreen(),
      ),
    );
  }

  void _retry() {
    final repository = AppDependencies.of(context).readerRepository;
    setState(() {
      _finishActivitySession();
      _repository = repository;
      _readerChromeVisible = false;
      _future = _loadChapter(_contentApi);
    });
  }

  void _openChapter(String contentApi, String title) {
    if (contentApi.isEmpty || _chapterTransitionPending) {
      return;
    }

    _chapterTransitionPending = true;
    try {
      final dependencies = AppDependencies.of(context);
      final repository = dependencies.readerRepository;
      _finishActivitySession();
      setState(() {
        _repository = repository;
        _contentApi = contentApi;
        _chapterTitle = title;
        _readerChromeVisible = false;
        _future = _loadChapter(contentApi);
      });
    } finally {
      _chapterTransitionPending = false;
    }
  }

  Future<void> _openNextChapter(String contentApi, String title) async {
    if (contentApi.isEmpty || _chapterTransitionPending) return;

    _chapterTransitionPending = true;
    final dependencies = AppDependencies.of(context);
    _finishActivitySession();
    try {
      final canShowAd = StandardAdVisibilityPolicy.canShow(
        dependencies.authRepository.value,
      );
      try {
        final shown = await dependencies.fullScreenAdRepository
            .showReaderInterstitialIfDue(canShow: canShowAd);
        if (shown) _reviewPromptController?.markFullScreenAdShown();
      } on Exception {
        // Advertising must never block the next chapter.
      }
      if (!mounted) return;
      final repository = dependencies.readerRepository;
      setState(() {
        _repository = repository;
        _contentApi = contentApi;
        _chapterTitle = title;
        _readerChromeVisible = false;
        _future = _loadChapter(contentApi);
      });
    } finally {
      _chapterTransitionPending = false;
    }
  }

  Future<ReaderChapterContent> _loadChapter(String contentApi) async {
    final repository = _repository;
    if (repository == null) {
      throw StateError('Reader repository is not ready.');
    }

    final content = await repository.loadChapter(contentApi);
    await _completeChapterLoad(content, contentApi);
    return content;
  }

  Future<void> _completeChapterLoad(
    ReaderChapterContent content,
    String contentApi,
  ) async {
    if (!mounted || contentApi != _contentApi) {
      return;
    }
    _currentNovelId = content.novelId;
    _currentChapterId = content.id;
    await _recordProgress(content, contentApi);
    if (!mounted || contentApi != _contentApi) {
      return;
    }
    _syncLoadedChapterTitle(content);
    _startActivitySession(content);
  }

  void _syncLoadedChapterTitle(ReaderChapterContent content) {
    final title = content.effectiveTitle;
    if (title.isEmpty || title == _chapterTitle) {
      return;
    }
    setState(() => _chapterTitle = title);
  }

  Future<void> _recordProgress(
    ReaderChapterContent content,
    String contentApi,
  ) async {
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
        contentApi: contentApi,
        coverUrl: widget.coverUrl,
        chapterPosition: content.position,
        chaptersTotal: content.total,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  void _startActivitySession(ReaderChapterContent content) {
    _finishActivitySession();
    final session = _activityRecorder?.startChapter(
      novelId: content.novelId,
      chapterId: content.id,
    );
    _activitySession = session;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (session != null && lifecycleState != AppLifecycleState.resumed) {
      _activityPaused = true;
      unawaited(session.pause());
    }
  }

  void _recordReadingActivity(int progress) {
    _activitySession?.recordInteraction(progress);
    final chapterId = _currentChapterId;
    if (chapterId > 0 &&
        progress >= AppReviewPromptController.completionThreshold) {
      unawaited(
        _reviewPromptController?.recordChapterProgress(
          chapterId: chapterId,
          progress: progress,
        ),
      );
    }
  }

  void _setReaderChromeVisibility(bool visible) {
    if (_readerChromeVisible == visible) {
      return;
    }
    setState(() => _readerChromeVisible = visible);
  }

  void _finishActivitySession() {
    final session = _activitySession;
    _activitySession = null;
    _activityPaused = false;
    if (session != null) {
      unawaited(session.finish());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final session = _activitySession;
    if (session == null) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (_activityPaused) {
        _activityPaused = false;
        session.resume();
      }
      unawaited(_displayController.apply(_preferences));
      return;
    }
    if (!_activityPaused) {
      _activityPaused = true;
      unawaited(session.pause());
    }
  }

  Future<void> _openReaderSettings() async {
    await showReaderSettingsSheet(
      context: context,
      preferences: _preferences,
      onChanged: (preferences) => unawaited(_savePreferences(preferences)),
      termRepository: _termRepository,
      advancedTerminologyRepository: _advancedTerminologyRepository,
      termReplacements: _termReplacements,
      novelId: _currentNovelId,
      onEditTerm: (replacement) {
        unawaited(
          _openTermEditor(
            source: replacement.source,
            novelId: replacement.novelId > 0
                ? replacement.novelId
                : _currentNovelId,
            existing: replacement,
          ),
        );
      },
      onDeleteTerm: (replacement) {
        unawaited(_deleteTermReplacement(replacement));
      },
    );
    if (mounted && _preferences.autoScrollEnabled) {
      _setReaderChromeVisibility(false);
    }
  }

  void _toggleAutoScroll() {
    final enabled = !_preferences.autoScrollEnabled;
    unawaited(
      _savePreferences(_preferences.copyWith(autoScrollEnabled: enabled)),
    );
    if (enabled) _setReaderChromeVisibility(false);
  }

  void _commitFontScale(double fontScale) {
    final boundedScale = fontScale
        .clamp(ReaderPreferences.minFontScale, ReaderPreferences.maxFontScale)
        .toDouble();
    if (boundedScale == _preferences.fontScale) return;
    unawaited(_savePreferences(_preferences.copyWith(fontScale: boundedScale)));
  }

  Future<void> _openChapterComments(ReaderChapterContent content) async {
    if (content.id <= 0) {
      return;
    }
    final dependencies = AppDependencies.of(context);
    final repository = dependencies.commentsRepository;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChapterCommentsSheet(
        repository: repository,
        target: CommentTarget.chapter(content.id),
        authRepository: dependencies.authRepository,
        onSignIn: _openAccountScreen,
      ),
    );
  }

  Future<void> _openSpeechPanel(ReaderChapterContent content) async {
    final controller = _speechController;
    if (controller == null) return;
    final notificationsAllowed = await widget.systemSettings
        .requestNotificationPermission();
    if (!notificationsAllowed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يمكن تشغيل الصوت، لكن يجب السماح بالإشعارات لإظهار أدوات شاشة القفل.',
          ),
        ),
      );
    }
    await _prepareSpeechChapter(content);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ReaderSpeechPanel(controller: controller),
      ),
    );
  }

  Future<void> _startSpeechFromBlock(
    ReaderChapterContent content,
    int blockIndex,
  ) async {
    final controller = _speechController;
    if (controller == null) return;
    await _prepareSpeechChapter(content);
    await controller.startFromBlock(blockIndex);
    await controller.play();
  }

  Future<void> _prepareSpeechChapter(ReaderChapterContent content) async {
    final controller = _speechController;
    if (controller == null) return;
    final chapter = _speechChapter(content, _contentApi);
    final current = controller.value.chapter;
    if (current?.hasSameContentIdentity(chapter) ?? false) {
      return;
    }
    _speechFollowEnabled = true;
    await controller.prepareChapter(
      chapter,
      visibleBlockIndex: _visibleBlockIndex,
    );
  }

  ReaderSpeechChapter _speechChapter(
    ReaderChapterContent content,
    String contentApi,
  ) {
    return buildReaderSpeechChapter(
      ReaderSpeechChapterRequest(
        content: content,
        contentApi: contentApi,
        novelTitle: widget.novelTitle ?? '',
        coverUrl: widget.coverUrl,
        personalReplacements: _termReplacements,
        advancedState: _advancedTerminologyState,
      ),
    );
  }

  void _bindSpeechController(
    ReaderSpeechController? controller, {
    required ReaderRepository repository,
  }) {
    if (!identical(_speechController, controller)) {
      _speechController?.removeListener(_syncSpeechState);
      _speechChapterSource?.detach();
      _speechController = controller;
      _speechState = controller?.value ?? ReaderSpeechState.idle;
      controller?.addListener(_syncSpeechState);
      _speechChapterSource = controller == null
          ? null
          : _RepositoryReaderSpeechChapterSource(
              repository: repository,
              novelTitle: widget.novelTitle ?? '',
              coverUrl: widget.coverUrl,
              personalReplacements: _termReplacements,
              advancedState: _advancedTerminologyState,
              onChapterStarted: _openSpeechChapterWithoutAd,
            );
      final source = _speechChapterSource;
      if (source != null) controller!.bindChapterSource(source);
      return;
    }
    _speechChapterSource?.update(
      repository: repository,
      personalReplacements: _termReplacements,
      advancedState: _advancedTerminologyState,
    );
  }

  void _syncSpeechState() {
    final state = _speechController?.value;
    if (!mounted || state == null || state == _speechState) return;
    setState(() => _speechState = state);
  }

  Future<void> _openSpeechChapterWithoutAd(
    ReaderChapterContent content,
    String contentApi,
  ) async {
    if (!mounted) return;
    _speechTextRefreshGeneration += 1;
    _finishActivitySession();
    setState(() {
      _contentApi = contentApi;
      _chapterTitle = content.effectiveTitle;
      _readerChromeVisible = false;
      _speechFollowEnabled = true;
      _future = Future.value(content);
    });
    await _completeChapterLoad(content, contentApi);
  }

  void _openAccountScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppScreenNames.account),
        builder: (_) => const AccountScreen(),
      ),
    );
  }

  void _syncPreferences() {
    final preferences = _preferencesRepository?.value;
    if (!mounted || preferences == null || preferences == _preferences) {
      return;
    }
    setState(() => _preferences = preferences);
    unawaited(_displayController.apply(preferences));
  }

  void _syncTermReplacements() {
    final replacements = _termRepository?.value;
    if (!mounted || replacements == null) return;
    setState(() => _termReplacements = replacements);
    _speechChapterSource?.update(personalReplacements: replacements);
    _refreshActiveSpeechText();
  }

  void _syncAdvancedTerminology() {
    final state = _advancedTerminologyRepository?.value;
    if (!mounted || state == null || state == _advancedTerminologyState) {
      return;
    }
    setState(() => _advancedTerminologyState = state);
    _speechChapterSource?.update(advancedState: state);
    _refreshActiveSpeechText();
  }

  void _refreshActiveSpeechText() {
    final controller = _speechController;
    final chapterFuture = _future;
    final contentApi = _contentApi;
    if (controller == null ||
        chapterFuture == null ||
        controller.value.chapter?.contentApi != contentApi ||
        !controller.value.isActive) {
      return;
    }
    final generation = ++_speechTextRefreshGeneration;
    unawaited(() async {
      try {
        final content = await chapterFuture;
        if (!mounted ||
            generation != _speechTextRefreshGeneration ||
            contentApi != _contentApi ||
            content.id != controller.value.chapter?.chapterId) {
          return;
        }
        final wasPlaying =
            controller.value.status == ReaderSpeechStatus.playing;
        final currentBlock = controller.value.blockIndex;
        await controller.prepareChapter(
          _speechChapter(content, contentApi),
          visibleBlockIndex: currentBlock,
        );
        if (wasPlaying &&
            mounted &&
            generation == _speechTextRefreshGeneration &&
            contentApi == _contentApi) {
          await controller.play();
        }
      } on Exception {
        if (mounted && generation == _speechTextRefreshGeneration) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحديث نص القراءة الصوتية.')),
          );
        }
      }
    }());
  }

  Future<void> _openTermEditor({
    required String source,
    required int novelId,
    ReaderTermReplacement? existing,
  }) async {
    final normalizedSource = source.trim();
    if (normalizedSource.isEmpty || !mounted) return;
    final currentRule =
        existing ?? _termReplacementForSource(normalizedSource, novelId);
    final replacement = await showReaderTermReplacementDialog(
      context: context,
      source: normalizedSource,
      novelId: novelId,
      existing: currentRule,
    );
    if (replacement == null || !mounted) return;
    await _saveTermReplacement(replacement, currentRule);
  }

  Future<void> _saveTermReplacement(
    ReaderTermReplacement replacement,
    ReaderTermReplacement? currentRule,
  ) async {
    try {
      await _termRepository?.save(replacement, replacing: currentRule);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المصطلح وتطبيقه على النص')),
      );
    } catch (_) {
      _showTermStorageError('تعذر حفظ المصطلح');
    }
  }

  ReaderTermReplacement? _termReplacementForSource(String source, int novelId) {
    ReaderTermReplacement? globalRule;
    for (final rule in _termReplacements) {
      if (rule.source != source) continue;
      if (rule.scope == ReaderTermScope.currentNovel &&
          rule.novelId == novelId) {
        return rule;
      }
      if (rule.scope == ReaderTermScope.allNovels) globalRule = rule;
    }
    return globalRule;
  }

  Future<void> _deleteTermReplacement(ReaderTermReplacement replacement) async {
    final confirmed = await _confirmTermDeletion(replacement.source);
    if (!confirmed) return;
    try {
      await _termRepository?.remove(replacement);
    } catch (_) {
      _showTermStorageError('تعذر حذف المصطلح');
    }
  }

  Future<void> _openTextRemovalEditor({
    required String source,
    required int novelId,
  }) async {
    final normalizedSource = source.trim();
    if (normalizedSource.isEmpty || !mounted) return;
    final rule = await showReaderTextRemovalDialog(
      context: context,
      source: normalizedSource,
      novelId: novelId,
    );
    if (rule == null || !mounted) return;
    try {
      await _advancedTerminologyRepository?.savePersonalRemoval(rule);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إخفاء النص أثناء القراءة')),
      );
    } catch (_) {
      _showTermStorageError('تعذر حفظ قاعدة الإخفاء');
    }
  }

  Future<bool> _confirmTermDeletion(String source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المصطلح؟'),
        content: Text('سيعود ظهور «$source» بصيغته الأصلية في النص.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showTermStorageError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    _speechTextRefreshGeneration += 1;
    WidgetsBinding.instance.removeObserver(this);
    _finishActivitySession();
    if (_reviewSessionStarted) {
      unawaited(_reviewPromptController?.finishReadingSession());
      _reviewSessionStarted = false;
    }
    unawaited(_displayController.restore());
    _preferencesRepository?.removeListener(_syncPreferences);
    _termRepository?.removeListener(_syncTermReplacements);
    _advancedTerminologyRepository?.removeListener(_syncAdvancedTerminology);
    _speechController?.removeListener(_syncSpeechState);
    _speechChapterSource?.detach();
    _ownedTermRepository?.dispose();
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

typedef _SpeechChapterStarted =
    Future<void> Function(ReaderChapterContent content, String contentApi);

class _RepositoryReaderSpeechChapterSource
    implements ReaderSpeechChapterSource {
  _RepositoryReaderSpeechChapterSource({
    required ReaderRepository repository,
    required this.novelTitle,
    required this.coverUrl,
    required List<ReaderTermReplacement> personalReplacements,
    required ReaderAdvancedTerminologyState advancedState,
    required _SpeechChapterStarted onChapterStarted,
  }) : _repository = repository,
       _personalReplacements = personalReplacements,
       _advancedState = advancedState,
       _onChapterStarted = onChapterStarted;

  ReaderRepository _repository;
  final String novelTitle;
  final String coverUrl;
  List<ReaderTermReplacement> _personalReplacements;
  ReaderAdvancedTerminologyState _advancedState;
  _SpeechChapterStarted? _onChapterStarted;
  final Map<String, ReaderChapterContent> _loadedContent = {};

  void update({
    ReaderRepository? repository,
    List<ReaderTermReplacement>? personalReplacements,
    ReaderAdvancedTerminologyState? advancedState,
  }) {
    _repository = repository ?? _repository;
    _personalReplacements = personalReplacements ?? _personalReplacements;
    _advancedState = advancedState ?? _advancedState;
  }

  void detach() {
    _onChapterStarted = null;
  }

  @override
  Future<ReaderSpeechChapter> loadChapter(String contentApi) async {
    final content = await _repository.loadChapter(contentApi);
    _loadedContent[contentApi] = content;
    return buildReaderSpeechChapter(
      ReaderSpeechChapterRequest(
        content: content,
        contentApi: contentApi,
        novelTitle: novelTitle,
        coverUrl: coverUrl,
        personalReplacements: _personalReplacements,
        advancedState: _advancedState,
      ),
    );
  }

  @override
  Future<void> didStartChapter(ReaderSpeechChapter chapter) async {
    final content = _loadedContent.remove(chapter.contentApi);
    final callback = _onChapterStarted;
    if (content != null && callback != null) {
      await callback(content, chapter.contentApi);
    }
  }
}
