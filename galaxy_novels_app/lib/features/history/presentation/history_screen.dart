import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(title: 'آخر القراءات'),
        NovelListTile(
          title: 'ظلال المجرة',
          subtitle: 'الفصل 24',
          meta: '68% - اليوم',
        ),
        NovelListTile(
          title: 'بوابة الشمال',
          subtitle: 'الفصل 7',
          meta: '31% - أمس',
        ),
      ],
    );
  }
}
