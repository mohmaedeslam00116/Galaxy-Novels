enum AppWindowClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const medium = 600.0;
  static const expanded = 840.0;

  static AppWindowClass classify(double width) {
    if (width < medium) return AppWindowClass.compact;
    if (width < expanded) return AppWindowClass.medium;
    return AppWindowClass.expanded;
  }

  static double screenPadding(double width) => width < medium ? 16 : 24;
}
