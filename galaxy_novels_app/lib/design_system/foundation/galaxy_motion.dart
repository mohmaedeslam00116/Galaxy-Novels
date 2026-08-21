import 'package:flutter/material.dart';

abstract final class GalaxyMotion {
  static const press = Duration(milliseconds: 120);
  static const stateChange = Duration(milliseconds: 180);
  static const emphasis = Duration(milliseconds: 220);
  static const route = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;

  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
