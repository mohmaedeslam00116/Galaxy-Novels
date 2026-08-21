import 'package:flutter/material.dart';

import 'galaxy_motion.dart';

PageRoute<T> galaxyPageRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RouteSettings? settings,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final duration = reduceMotion ? Duration.zero : GalaxyMotion.route;
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotion) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: GalaxyMotion.curve,
        reverseCurve: GalaxyMotion.curve.flipped,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.018),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
