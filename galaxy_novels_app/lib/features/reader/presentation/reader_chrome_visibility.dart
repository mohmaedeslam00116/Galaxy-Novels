import 'package:flutter/material.dart';

class ReaderChromeVisibilityKeys {
  const ReaderChromeVisibilityKeys({
    required this.excludeSemantics,
    required this.ignorePointer,
  });

  final Key excludeSemantics;
  final Key ignorePointer;
}

class ReaderChromeVisibility extends StatelessWidget {
  const ReaderChromeVisibility({
    required this.visible,
    required this.hiddenOffset,
    required this.keys,
    required this.child,
    super.key,
  });

  final bool visible;
  final Offset hiddenOffset;
  final ReaderChromeVisibilityKeys keys;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final curve = visible ? Curves.easeOutCubic : Curves.easeInCubic;
    Widget animatedChild = AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: curve,
      child: child,
    );
    if (!disableAnimations) {
      animatedChild = AnimatedSlide(
        offset: visible ? Offset.zero : hiddenOffset,
        duration: duration,
        curve: curve,
        child: animatedChild,
      );
    }

    return ExcludeSemantics(
      key: keys.excludeSemantics,
      excluding: !visible,
      child: IgnorePointer(
        key: keys.ignorePointer,
        ignoring: !visible,
        child: animatedChild,
      ),
    );
  }
}

class ReaderDockedChromeVisibility extends StatelessWidget {
  const ReaderDockedChromeVisibility({
    required this.visible,
    required this.keys,
    required this.child,
    super.key,
  });

  final bool visible;
  final ReaderChromeVisibilityKeys keys;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final curve = visible ? Curves.easeOutCubic : Curves.easeInCubic;
    return ExcludeSemantics(
      key: keys.excludeSemantics,
      excluding: !visible,
      child: IgnorePointer(
        key: keys.ignorePointer,
        ignoring: !visible,
        child: ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: visible ? 1 : 0,
            duration: duration,
            curve: curve,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: duration,
              curve: curve,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
