import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class ReaderBannerAdSlot extends StatefulWidget {
  const ReaderBannerAdSlot({
    required this.contentKey,
    required this.child,
    required this.height,
    super.key,
  });

  final String contentKey;
  final Widget child;
  final double height;

  static const double readerHeight = 56;

  @override
  State<ReaderBannerAdSlot> createState() => _ReaderBannerAdSlotState();
}

class _ReaderBannerAdSlotState extends State<ReaderBannerAdSlot> {
  bool _isHidden = false;

  @override
  void didUpdateWidget(covariant ReaderBannerAdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != oldWidget.contentKey) {
      _isHidden = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),
          PositionedDirectional(
            top: 4,
            end: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.62),
              shape: const CircleBorder(),
              child: InkWell(
                key: const ValueKey('reader-ad-close-button'),
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _isHidden = true),
                child: SizedBox.square(
                  dimension: 38,
                  child: Icon(
                    Icons.close_rounded,
                    color: tokens.textPrimary,
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
