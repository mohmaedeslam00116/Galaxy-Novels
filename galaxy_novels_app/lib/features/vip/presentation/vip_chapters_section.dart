import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/section_title.dart';
import '../application/vip_chapters_controller.dart';
import '../data/vip_reader_request.dart';
import '../domain/vip_chapter.dart';

class VipChaptersSection extends StatefulWidget {
  const VipChaptersSection({
    required this.controller,
    required this.canReadPrivate,
    required this.nativeReaderAvailable,
    required this.onSignIn,
    required this.onOpenVipChapter,
    super.key,
  });

  final VipChaptersController controller;
  final bool canReadPrivate;
  final bool nativeReaderAvailable;
  final VoidCallback onSignIn;
  final void Function(String contentApi, String title) onOpenVipChapter;

  @override
  State<VipChaptersSection> createState() => _VipChaptersSectionState();
}

class _VipChaptersSectionState extends State<VipChaptersSection> {
  @override
  void initState() {
    super.initState();
    _loadIfAllowed();
  }

  @override
  void didUpdateWidget(covariant VipChaptersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        (!oldWidget.canReadPrivate && widget.canReadPrivate)) {
      _loadIfAllowed();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canReadPrivate) {
      return SliverToBoxAdapter(
        child: _VipMessage(
          icon: Icons.workspace_premium_outlined,
          title: 'فصول VIP',
          message:
              'هذه الفصول متاحة للمشتركين فقط. الشراء داخل التطبيق مؤجل حاليا.',
          actionLabel: 'حسابي',
          onAction: widget.onSignIn,
        ),
      );
    }

    return ValueListenableBuilder<VipChaptersState>(
      valueListenable: widget.controller,
      builder: (context, state, _) {
        return SliverMainAxisGroup(
          slivers: [
            const SliverToBoxAdapter(
              child: SectionTitle(
                title: 'فصول VIP الخاصة',
                leadingIcon: Icons.workspace_premium_outlined,
              ),
            ),
            switch (state.status) {
              VipChaptersStatus.idle ||
              VipChaptersStatus.loading => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
              VipChaptersStatus.loginRequired => SliverToBoxAdapter(
                child: _VipMessage(
                  icon: Icons.login_rounded,
                  title: 'سجّل الدخول',
                  message: state.errorMessage ?? 'سجّل الدخول لعرض فصول VIP.',
                  actionLabel: 'حسابي',
                  onAction: widget.onSignIn,
                ),
              ),
              VipChaptersStatus.subscriptionRequired => SliverToBoxAdapter(
                child: _VipMessage(
                  icon: Icons.lock_outline_rounded,
                  title: 'اشتراك VIP مطلوب',
                  message:
                      state.errorMessage ??
                      'لا يوجد اشتراك VIP فعال لهذا الحساب.',
                ),
              ),
              VipChaptersStatus.failure => SliverToBoxAdapter(
                child: _VipMessage(
                  icon: Icons.cloud_off_outlined,
                  title: 'تعذر تحميل فصول VIP',
                  message: state.errorMessage ?? 'حاول مرة أخرى بعد قليل.',
                  actionLabel: 'إعادة المحاولة',
                  onAction: widget.controller.retry,
                ),
              ),
              VipChaptersStatus.ready => _VipChapterSliverList(
                state: state,
                nativeReaderAvailable: widget.nativeReaderAvailable,
                onOpen: _openChapter,
                onLoadMore: widget.controller.loadMore,
              ),
            },
          ],
        );
      },
    );
  }

  void _loadIfAllowed() {
    if (widget.canReadPrivate) {
      widget.controller.loadInitial();
    }
  }

  void _openChapter(VipChapter chapter) {
    final contentApi = chapter.contentApi.isNotEmpty
        ? chapter.contentApi
        : VipReaderRequest.chapter(chapter.id);
    if (!widget.nativeReaderAvailable && chapter.contentApi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('قراءة فصول VIP داخل التطبيق تنتظر تحديث السيرفر.'),
        ),
      );
      return;
    }

    widget.onOpenVipChapter(contentApi, chapter.displayLabel);
  }
}

class _VipChapterSliverList extends StatelessWidget {
  const _VipChapterSliverList({
    required this.state,
    required this.nativeReaderAvailable,
    required this.onOpen,
    required this.onLoadMore,
  });

  final VipChaptersState state;
  final bool nativeReaderAvailable;
  final ValueChanged<VipChapter> onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: _VipMessage(
          icon: Icons.workspace_premium_outlined,
          title: 'لا توجد فصول VIP متاحة',
          message: 'لا توجد فصول خاصة لهذه الرواية الآن.',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == state.chapters.length) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: OutlinedButton.icon(
                onPressed: state.isLoadingMore ? null : onLoadMore,
                icon: state.isLoadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: const Text('تحميل المزيد'),
              ),
            );
          }

          final chapter = state.chapters[index];
          return _VipChapterRow(
            chapter: chapter,
            nativeReaderAvailable: nativeReaderAvailable,
            onTap: () => onOpen(chapter),
          );
        },
        childCount: state.chapters.length + (state.hasMore ? 1 : 0),
        addAutomaticKeepAlives: false,
      ),
    );
  }
}

class _VipChapterRow extends StatelessWidget {
  const _VipChapterRow({
    required this.chapter,
    required this.nativeReaderAvailable,
    required this.onTap,
  });

  final VipChapter chapter;
  final bool nativeReaderAvailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final secondary = chapter.title.isNotEmpty
        ? chapter.title
        : chapter.publicAt;
    final canOpen = nativeReaderAvailable || chapter.contentApi.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          height: 74,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: tokens.gold.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.gold.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: tokens.gold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (secondary.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                canOpen
                    ? Icons.chevron_left_rounded
                    : Icons.lock_outline_rounded,
                color: tokens.gold,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipMessage extends StatelessWidget {
  const _VipMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tokens.gold),
              const SizedBox(height: 10),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
