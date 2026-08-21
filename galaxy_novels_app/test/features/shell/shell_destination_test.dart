import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/shell/presentation/shell_destination.dart';

void main() {
  test('shell destinations expose the approved Stitch order', () {
    expect(
      ShellDestination.values.map(
        (destination) => (
          destination.name,
          destination.label,
          destination.icon,
          destination.selectedIcon,
        ),
      ),
      const [
        ('home', 'الرئيسية', Icons.home_outlined, Icons.home),
        (
          'library',
          'المكتبة',
          Icons.local_library_outlined,
          Icons.local_library,
        ),
        (
          'readerJourney',
          'رحلة القارئ',
          Icons.auto_stories_outlined,
          Icons.auto_stories,
        ),
        ('rankings', 'الترتيب', Icons.bar_chart_outlined, Icons.bar_chart),
        ('account', 'حسابي', Icons.person_outline, Icons.person),
      ],
    );
  });
}
