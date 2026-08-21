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
    this.focusNode,
    this.replyTarget,
    this.onSignIn,
    this.onSubmitted,
    this.onCancelReply,
    super.key,
  });

  final CommentsController controller;
  final AuthRepository? authRepository;
  final FocusNode? focusNode;
  final PublicComment? replyTarget;
  final VoidCallback? onSignIn;
  final VoidCallback? onSubmitted;
  final VoidCallback? onCancelReply;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _textController = TextEditingController();
  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _isSpoiler = false;
  String? _submitAnnouncement;

  @override
  void initState() {
    super.initState();
    _setFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant CommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _setFocusNode(widget.focusNode);
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    _textController.dispose();
    super.dispose();
  }

  void _setFocusNode(FocusNode? suppliedFocusNode) {
    _ownsFocusNode = suppliedFocusNode == null;
    _focusNode = suppliedFocusNode ?? FocusNode();
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
                  focusNode: _focusNode,
                  isSpoiler: _isSpoiler,
                  submitAnnouncement: _submitAnnouncement,
                  replyTarget: widget.replyTarget,
                  onSpoilerChanged: (value) =>
                      setState(() => _isSpoiler = value),
                  onCancelReply: widget.onCancelReply,
                  onSubmit: _submit,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final message = Row(
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
                      ],
                    );
                    final accountAction = widget.onSignIn == null
                        ? null
                        : OutlinedButton(
                            key: const ValueKey('comments-open-account'),
                            onPressed: widget.onSignIn,
                            child: const Text('فتح حسابي'),
                          );

                    if (constraints.maxWidth < 360 && accountAction != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          message,
                          const SizedBox(height: 10),
                          accountAction,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: message),
                        if (accountAction != null) ...[
                          const SizedBox(width: 10),
                          accountAction,
                        ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitAnnouncement = 'جارٍ إرسال التعليق');
    final content = _textController.text;
    final parentId = widget.replyTarget?.id ?? 0;
    final isSpoiler = _isSpoiler;
    final outcome = await widget.controller.submitComment(
      content: content,
      parentId: parentId,
      isSpoiler: isSpoiler,
    );
    if (!mounted) {
      return;
    }
    _completeSubmission(outcome);
  }

  void _completeSubmission(CommentSubmitOutcome outcome) {
    if (outcome.status != CommentSubmitStatus.saved) {
      setState(() => _submitAnnouncement = outcome.errorMessage);
      return;
    }
    _textController.clear();
    setState(() {
      _isSpoiler = false;
      _submitAnnouncement = 'تم نشر تعليقك';
    });
    widget.onSubmitted?.call();
  }
}

class _AuthenticatedComposer extends StatelessWidget {
  const _AuthenticatedComposer({
    required this.controller,
    required this.textController,
    required this.focusNode,
    required this.isSpoiler,
    required this.submitAnnouncement,
    required this.onSpoilerChanged,
    required this.onSubmit,
    this.replyTarget,
    this.onCancelReply,
  });

  final CommentsController controller;
  final TextEditingController textController;
  final FocusNode focusNode;
  final bool isSpoiler;
  final String? submitAnnouncement;
  final ValueChanged<bool> onSpoilerChanged;
  final Future<void> Function() onSubmit;
  final PublicComment? replyTarget;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CommentsState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final tokens =
            Theme.of(context).extension<AppThemeTokens>() ??
            AppTheme.galaxyNoir;
        final announcement = submitAnnouncement ?? state.submitErrorMessage;
        final announcementIsError = state.submitErrorMessage != null;
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
              focusNode: focusNode,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'اكتب تعليقك...',
                border: OutlineInputBorder(),
              ),
            ),
            if (announcement != null) ...[
              const SizedBox(height: 8),
              Semantics(
                key: const ValueKey('comments-submit-announcement'),
                container: true,
                liveRegion: true,
                label: announcement,
                excludeSemantics: true,
                child: Text(
                  announcement,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: announcementIsError
                        ? tokens.danger
                        : tokens.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                FilterChip(
                  key: const ValueKey('comments-spoiler-toggle'),
                  label: const Text('حرق'),
                  selected: isSpoiler,
                  onSelected: state.isSubmitting ? null : onSpoilerChanged,
                ),
                FilledButton.icon(
                  key: const ValueKey('comments-submit-button'),
                  onPressed: state.isSubmitting
                      ? null
                      : () => unawaited(onSubmit()),
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
}

class _ReplyTargetBar extends StatelessWidget {
  const _ReplyTargetBar({required this.comment, this.onCancel});

  final PublicComment comment;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;
    final replyLabel = 'رد على ${comment.authorName}';

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
              child: Semantics(
                key: const ValueKey('comments-reply-announcement'),
                container: true,
                liveRegion: true,
                label: replyLabel,
                excludeSemantics: true,
                child: Text(
                  replyLabel,
                  key: const ValueKey('comments-reply-target'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.primary,
                    fontWeight: FontWeight.w900,
                  ),
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
