import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';

class RankingsScreen extends StatelessWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(title: 'ترتيب الشهر'),
        NovelListTile(
          rank: 1,
          title: 'حارس النجوم',
          subtitle: 'الأكثر قراءة هذا الشهر',
          meta: '82 فصل',
        ),
        NovelListTile(
          rank: 2,
          title: 'مدن الرماد',
          subtitle: 'صعود سريع في القراءة',
          meta: '41 فصل',
        ),
        NovelListTile(
          rank: 3,
          title: 'بوابة الشمال',
          subtitle: 'رواية مكتملة',
          meta: '126 فصل',
        ),
      ],
    );
  }
}
