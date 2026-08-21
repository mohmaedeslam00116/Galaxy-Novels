import 'package:flutter/material.dart';

import '../../../core/analytics/app_screen_names.dart';

enum ShellDestination { home, library, readerJourney, rankings, account }

extension ShellDestinationPresentation on ShellDestination {
  String get analyticsName => switch (this) {
    ShellDestination.home => AppScreenNames.home,
    ShellDestination.library => AppScreenNames.library,
    ShellDestination.readerJourney => AppScreenNames.readerJourney,
    ShellDestination.rankings => AppScreenNames.rankings,
    ShellDestination.account => AppScreenNames.account,
  };

  String get label => switch (this) {
    ShellDestination.home => 'الرئيسية',
    ShellDestination.library => 'المكتبة',
    ShellDestination.readerJourney => 'رحلة القارئ',
    ShellDestination.rankings => 'الترتيب',
    ShellDestination.account => 'حسابي',
  };

  IconData get icon => switch (this) {
    ShellDestination.home => Icons.home_outlined,
    ShellDestination.library => Icons.local_library_outlined,
    ShellDestination.readerJourney => Icons.auto_stories_outlined,
    ShellDestination.rankings => Icons.bar_chart_outlined,
    ShellDestination.account => Icons.person_outline,
  };

  IconData get selectedIcon => switch (this) {
    ShellDestination.home => Icons.home,
    ShellDestination.library => Icons.local_library,
    ShellDestination.readerJourney => Icons.auto_stories,
    ShellDestination.rankings => Icons.bar_chart,
    ShellDestination.account => Icons.person,
  };
}
