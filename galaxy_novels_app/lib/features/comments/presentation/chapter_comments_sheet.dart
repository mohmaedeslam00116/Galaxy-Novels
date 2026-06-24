import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../application/comments_controller.dart';
import '../application/comments_repository.dart';
import '../domain/comment_target.dart';
import 'comments_sliver_section.dart';

class ChapterCommentsSheet extends StatefulWidget {
  const ChapterCommentsSheet({
    required this.repository,
    required this.target,
    super.key,
  });

  final CommentsRepository repository;
  final CommentTarget target;

  @override
  State<ChapterCommentsSheet> createState() => _ChapterCommentsSheetState();
}

class _ChapterCommentsSheetState extends State<ChapterCommentsSheet> {
  late final CommentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CommentsController(
      repository: widget.repository,
      target: widget.target,
    );
    unawaited(_controller.loadInitial());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Material(
          key: const ValueKey('chapter-comments-sheet'),
          color: tokens.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _SheetHeader(onClose: () => Navigator.of(context).pop()),
                Expanded(
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      CommentsSliverSection(
                        controller: _controller,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  tooltip: 'إغلاق تعليقات الفصل',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'تعليقات الفصل',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(Icons.forum_outlined, color: tokens.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
