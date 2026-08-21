import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/models/novel_details_data.dart';
import '../../../../data/models/reading_progress.dart';
import '../../../../data/repositories/novel_repository.dart';
import '../../../../design_system/foundation/galaxy_adaptive.dart';
import '../../../../design_system/patterns/galaxy_novel_details_header.dart';
import '../../../../shared/widgets/novel_cover.dart';
import '../../../account/application/auth_repository.dart';
import '../../../account/domain/auth_session.dart';
import '../../../ads/application/inline_native_ad_repository.dart';
import '../../../ads/presentation/inline_native_ad_slot.dart';
import '../../../comments/application/comments_controller.dart';
import '../../../comments/application/comments_repository.dart';
import '../../../comments/domain/comment_target.dart';
import '../../../comments/presentation/comments_sliver_section.dart';
import '../../../novel_engagement/application/novel_engagement_controller.dart';
import '../../../vip/application/vip_chapters_controller.dart';
import '../novel_details_visual_tokens.dart';
import '../novel_details_transition.dart';
import '../visible_chapter_count.dart';
import 'novel_chapters_section.dart';
import 'novel_details_header.dart';
import 'novel_details_section_tabs.dart';
import 'novel_details_summary_card.dart';

class NovelDetailsContent extends StatefulWidget {
  const NovelDetailsContent({
    required this.loadResult,
    required this.engagementState,
    this.readingProgress,
    required this.commentsRepository,
    required this.authRepository,
    required this.vipController,
    required this.isVipNativeReaderAvailable,
    required this.onRead,
    required this.onOpenVipChapter,
    required this.onRate,
    required this.onSignIn,
    required this.onRetryEngagement,
    this.favoriteAction,
    this.heroTag,
    super.key,
  });

  final NovelDetailsLoadResult loadResult;
  final NovelEngagementState engagementState;
  final ReadingProgress? readingProgress;
  final CommentsRepository commentsRepository;
  final AuthRepository authRepository;
  final VipChaptersController vipController;
  final bool isVipNativeReaderAvailable;
  final void Function(NovelChapter chapter, String novelTitle) onRead;
  final void Function(String contentApi, String title) onOpenVipChapter;
  final VoidCallback onRate;
  final VoidCallback onSignIn;
  final VoidCallback onRetryEngagement;
  final Widget? favoriteAction;
  final Object? heroTag;

  @override
  State<NovelDetailsContent> createState() => _NovelDetailsContentState();
}

class _NovelDetailsContentState extends State<NovelDetailsContent> {
  NovelDetailsSection _section = NovelDetailsSection.chapters;
  CommentsController? _commentsController;

  @override
  void initState() {
    super.initState();
    _loadVipIfAllowed();
  }

  @override
  void didUpdateWidget(covariant NovelDetailsContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadResult.details.id != widget.loadResult.details.id ||
        oldWidget.commentsRepository != widget.commentsRepository) {
      _commentsController?.dispose();
      _commentsController = null;
      _section = NovelDetailsSection.chapters;
    }
    if (oldWidget.vipController != widget.vipController ||
        oldWidget.loadResult.details.id != widget.loadResult.details.id ||
        oldWidget.engagementState.userState?.vip.canReadPrivate !=
            widget.engagementState.userState?.vip.canReadPrivate) {
      _loadVipIfAllowed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadResult = widget.loadResult;
    final details = loadResult.details;
    final firstReadableChapter = _firstReadableChapter(loadResult.chapters);
    final continuationChapter = _continuationChapter(
      loadResult.chapters,
      widget.readingProgress?.chapterId ??
          widget.engagementState.userState?.lastRead.chapterId ??
          0,
    );
    final readChapter = continuationChapter ?? firstReadableChapter;
    final tokens = NovelDetailsVisualTokens.of(context);
    final maximumContentWidth =
        GalaxyAdaptive.of(context) == GalaxyLayoutTier.expanded
        ? 1120.0
        : 768.0;

    return ColoredBox(
      color: tokens.background,
      child: Center(
        child: ConstrainedBox(
          key: const ValueKey('novel-details-content-column'),
          constraints: BoxConstraints(maxWidth: maximumContentWidth),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: tokens.background,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 16,
                title: GalaxyCollapsingDetailsBar(
                  key: const ValueKey('novel-details-collapsing-bar'),
                  title: details.title,
                  readLabel: readChapter == null ? null : 'متابعة',
                  onRead: readChapter == null
                      ? null
                      : () => widget.onRead(readChapter, details.title),
                ),
              ),
              SliverToBoxAdapter(
                child: ValueListenableBuilder<VipChaptersState>(
                  valueListenable: widget.vipController,
                  builder: (context, vipState, _) {
                    return NovelDetailsHeader(
                      details: details,
                      chaptersCount: visibleNovelChapterCount(
                        publicChapterCount: details.chaptersCount,
                        loadedPublicChapterCount: loadResult.chapters.length,
                        canReadPrivate:
                            widget
                                .engagementState
                                .userState
                                ?.vip
                                .canReadPrivate ??
                            false,
                        vipState: vipState,
                      ),
                      engagementState: widget.engagementState,
                      onRate: widget.onRate,
                      onSignIn: widget.onSignIn,
                      onRetryEngagement: widget.onRetryEngagement,
                      heroTag: widget.heroTag,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _ReadAction(
                  label: continuationChapter == null
                      ? 'ابدأ القراءة'
                      : 'متابعة ${continuationChapter.label}',
                  onPressed: readChapter == null
                      ? null
                      : () => widget.onRead(readChapter, details.title),
                  favoriteAction: widget.favoriteAction,
                ),
              ),
              if (details.summary.isNotEmpty)
                SliverToBoxAdapter(
                  child: NovelDetailsSummaryCard(summary: details.summary),
                ),
              const SliverToBoxAdapter(
                child: InlineNativeAdSlot(
                  placement: InlineNativeAdPlacement.novelDetails,
                ),
              ),
              SliverToBoxAdapter(
                child: NovelDetailsSectionTabs(
                  selected: _section,
                  onSelected: _selectSection,
                  chaptersCount: visibleNovelChapterCount(
                    publicChapterCount: details.chaptersCount,
                    loadedPublicChapterCount: loadResult.chapters.length,
                    canReadPrivate:
                        widget.engagementState.userState?.vip.canReadPrivate ??
                        false,
                    vipState: widget.vipController.value,
                  ),
                ),
              ),
              switch (_section) {
                NovelDetailsSection.chapters =>
                  ValueListenableBuilder<AuthSessionState>(
                    valueListenable: widget.authRepository,
                    builder: (context, session, _) {
                      return NovelChaptersSection(
                        result: loadResult,
                        vipController: widget.vipController,
                        canReadPrivate:
                            widget
                                .engagementState
                                .userState
                                ?.vip
                                .canReadPrivate ??
                            false,
                        isAuthenticated:
                            session.status == AuthSessionStatus.authenticated,
                        isVipDirectContentRouteAvailable:
                            widget.isVipNativeReaderAvailable,
                        readingProgress: widget.readingProgress,
                        onRead: widget.onRead,
                        onOpenVipChapter: widget.onOpenVipChapter,
                        onSignIn: widget.onSignIn,
                      );
                    },
                  ),
                NovelDetailsSection.comments => CommentsSliverSection(
                  controller: _commentsController!,
                  authRepository: widget.authRepository,
                  onSignIn: widget.onSignIn,
                ),
              },
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSection(NovelDetailsSection section) {
    if (_section == section) return;
    if (section == NovelDetailsSection.comments) {
      final controller = _commentsController ??= CommentsController(
        repository: widget.commentsRepository,
        target: CommentTarget.novel(widget.loadResult.details.id),
        authRepository: widget.authRepository,
      );
      setState(() => _section = section);
      unawaited(controller.loadInitial());
      return;
    }
    setState(() => _section = section);
  }

  @override
  void dispose() {
    _commentsController?.dispose();
    super.dispose();
  }

  void _loadVipIfAllowed() {
    final canReadPrivate =
        widget.engagementState.userState?.vip.canReadPrivate ?? false;
    if (canReadPrivate &&
        widget.loadResult.details.vipScheduleManifest.isNotEmpty) {
      unawaited(widget.vipController.loadInitial());
    }
  }
}

class _ReadAction extends StatelessWidget {
  const _ReadAction({
    required this.label,
    required this.onPressed,
    this.favoriteAction,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? favoriteAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = NovelDetailsVisualTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('novel-details-read-action'),
              onPressed: onPressed,
              icon: const Icon(Icons.menu_book_outlined),
              label: Text(
                onPressed == null ? 'لا يوجد فصل متاح' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                backgroundColor: tokens.primary,
                foregroundColor: tokens.onPrimary,
                disabledBackgroundColor: tokens.surfaceHigh,
                disabledForegroundColor: tokens.textSecondary,
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (favoriteAction != null) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 58, minHeight: 58),
              child: Center(child: favoriteAction),
            ),
          ],
        ],
      ),
    );
  }
}

NovelChapter? _firstReadableChapter(List<NovelChapter> chapters) {
  for (final chapter in chapters) {
    if (chapter.effectiveContentApi.isNotEmpty) return chapter;
  }
  return null;
}

NovelChapter? _continuationChapter(List<NovelChapter> chapters, int chapterId) {
  if (chapterId <= 0) return null;
  for (final chapter in chapters) {
    if (chapter.id == chapterId && chapter.effectiveContentApi.isNotEmpty) {
      return chapter;
    }
  }
  return null;
}

class NovelDetailsSkeleton extends StatelessWidget {
  const NovelDetailsSkeleton({this.transition, super.key});

  final NovelDetailsTransitionData? transition;

  @override
  Widget build(BuildContext context) {
    final tokens = NovelDetailsVisualTokens.of(context);
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tokens.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return ColoredBox(
      color: tokens.background,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Center(
            child: transition == null
                ? bar(168, 252)
                : Hero(
                    tag: transition!.heroTag,
                    transitionOnUserGestures: true,
                    child: NovelCover(
                      title: transition!.title,
                      imageUrl: transition!.coverUrl,
                      width: 168,
                      height: 252,
                      borderRadius: 16,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Center(child: bar(210, 24)),
          const SizedBox(height: 9),
          Center(child: bar(150, 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(child: bar(0, 78)),
              ],
            ],
          ),
          const SizedBox(height: 22),
          bar(double.infinity, 58),
          const SizedBox(height: 22),
          bar(double.infinity, 156),
          const SizedBox(height: 18),
          bar(double.infinity, 58),
        ],
      ),
    );
  }
}

class NovelDetailsMessage extends StatelessWidget {
  const NovelDetailsMessage({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
