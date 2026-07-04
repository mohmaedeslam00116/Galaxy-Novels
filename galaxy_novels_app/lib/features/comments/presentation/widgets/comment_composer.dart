import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../account/application/auth_repository.dart';
import '../../../account/domain/auth_session.dart';
import '../../application/comments_controller.dart';
import '../../domain/public_comment.dart';

class CommentComposer extends StatefulWidget {
  const CommentComposer({
    required this.controller,
    required this.authRepository,
    this.replyTarget,
    this.onSignIn,
    this.onSubmitted,
    this.onCancelReply,
    super.key,
  });

  final CommentsController controller;
  final AuthRepository? authRepository;
  final PublicComment? replyTarget;
  final VoidCallback? onSignIn;
  final VoidCallback? onSubmitted;
  final VoidCallback? onCancelReply;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _textController = TextEditingController();
  bool _isSpoiler = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = widget.authRepository;
    if (authRepository == null) {
      return _buildEditor(context, isAuthenticated: true);
    }
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: authRepository,
      builder: (context, session, _) {
        return _buildEditor(
          context,
          isAuthenticated: session.status == AuthSessionStatus.authenticated,
        );
      },
    );
  }

  Widget _buildEditor(BuildContext context, {required bool isAuthenticated}) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isAuthenticated
              ? _AuthenticatedComposer(
                  controller: widget.controller,
                  textController: _textController,
                  isSpoiler: _isSpoiler,
                  replyTarget: widget.replyTarget,
                  onSpoilerChanged: (value) =>
                      setState(() => _isSpoiler = value),
                  onCancelReply: widget.onCancelReply,
                  onSubmitted: () {
                    _textController.clear();
                    setState(() => _isSpoiler = false);
                    widget.onSubmitted?.call();
                  },
                )
              : Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: tokens.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'سجل الدخول لكتابة تعليق.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (widget.onSignIn != null) ...[
                      const SizedBox(width: 10),
                      OutlinedButton(
                        key: const ValueKey('comments-open-account'),
                        onPressed: widget.onSignIn,
                        child: const Text('فتح حسابي'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _AuthenticatedComposer extends StatelessWidget {
  const _AuthenticatedComposer({
    required this.controller,
    required this.textController,
    required this.isSpoiler,
    required this.onSpoilerChanged,
    this.replyTarget,
    this.onCancelReply,
    this.onSubmitted,
  });

  final CommentsController controller;
  final TextEditingController textController;
  final bool isSpoiler;
  final ValueChanged<bool> onSpoilerChanged;
  final PublicComment? replyTarget;
  final VoidCallback? onCancelReply;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CommentsState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final tokens =
            Theme.of(context).extension<AppThemeTokens>() ??
            AppTheme.galaxyNoir;
        final error = state.submitErrorMessage;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (replyTarget != null) ...[
              _ReplyTargetBar(comment: replyTarget!, onCancel: onCancelReply),
              const SizedBox(height: 10),
            ],
            TextField(
              key: const ValueKey('comments-content-field'),
              controller: textController,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'اكتب تعليقك...',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tokens.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                FilterChip(
                  key: const ValueKey('comments-spoiler-toggle'),
                  label: const Text('حرق'),
                  selected: isSpoiler,
                  onSelected: state.isSubmitting ? null : onSpoilerChanged,
                ),
                const Spacer(),
                FilledButton.icon(
                  key: const ValueKey('comments-submit-button'),
                  onPressed: state.isSubmitting
                      ? null
                      : () => unawaited(_submit(context)),
                  icon: state.isSubmitting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(state.isSubmitting ? 'جار الإرسال' : 'إرسال'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final outcome = await controller.submitComment(
      content: textController.text,
      parentId: replyTarget?.id ?? 0,
      isSpoiler: isSpoiler,
    );
    if (outcome.status == CommentSubmitStatus.saved) {
      onSubmitted?.call();
    }
  }
}

class _ReplyTargetBar extends StatelessWidget {
  const _ReplyTargetBar({required this.comment, this.onCancel});

  final PublicComment comment;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'رد على ${comment.authorName}',
                key: const ValueKey('comments-reply-target'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: tokens.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              tooltip: 'إلغاء الرد',
              onPressed: onCancel,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
