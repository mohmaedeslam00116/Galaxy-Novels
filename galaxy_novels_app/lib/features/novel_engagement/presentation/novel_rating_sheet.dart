import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../application/novel_engagement_controller.dart';

class NovelRatingSheet extends StatefulWidget {
  const NovelRatingSheet({
    required this.initialRating,
    required this.onSubmit,
    super.key,
  });

  final int initialRating;
  final Future<RatingSubmitOutcome> Function(int rating) onSubmit;

  @override
  State<NovelRatingSheet> createState() => _NovelRatingSheetState();
}

class _NovelRatingSheetState extends State<NovelRatingSheet> {
  late int _selectedRating = widget.initialRating.clamp(0, 5);
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'قيّم الرواية',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectedRating == 0
                  ? 'اختر تقييمك من نجمة إلى خمس نجوم'
                  : 'تقييمك المختار: $_selectedRating من 5',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var rating = 1; rating <= 5; rating++)
                  Semantics(
                    selected: rating <= _selectedRating,
                    child: IconButton(
                      key: ValueKey('personal-rating-$rating'),
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                              _selectedRating = rating;
                              _errorMessage = null;
                            }),
                      tooltip: _ratingTooltip(rating),
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      iconSize: 32,
                      color: rating <= _selectedRating
                          ? tokens.gold
                          : tokens.textSecondary,
                      icon: Icon(
                        rating <= _selectedRating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                      ),
                    ),
                  ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _selectedRating == 0 || _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('حفظ التقييم'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final outcome = await widget.onSubmit(_selectedRating);
    if (!mounted) {
      return;
    }
    if (outcome.status == RatingSubmitStatus.saved) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = outcome.errorMessage ?? _fallbackMessage(outcome.status);
    });
  }
}

String _ratingTooltip(int rating) {
  return switch (rating) {
    1 => 'نجمة واحدة',
    2 => 'نجمتان',
    3 => 'ثلاث نجوم',
    4 => 'أربع نجوم',
    _ => 'خمس نجوم',
  };
}

String _fallbackMessage(RatingSubmitStatus status) {
  return switch (status) {
    RatingSubmitStatus.signInRequired => 'سجّل الدخول لإرسال تقييمك.',
    RatingSubmitStatus.busy => 'يجري حفظ تقييمك الآن.',
    _ => 'تعذر حفظ التقييم. حاول مجددًا.',
  };
}
