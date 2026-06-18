import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';
import '../../../shared/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SectionHeader(title: 'أكمل القراءة'),
        NovelListTile(
          title: 'ظلال المجرة',
          subtitle: 'آخر قراءة: الفصل 24',
          meta: 'تقدم القراءة 68%',
        ),
        SectionHeader(title: 'أحدث الفصول'),
        NovelListTile(
          title: 'حارس النجوم',
          subtitle: 'الفصل 82 متاح الآن',
          meta: 'منذ 12 دقيقة',
        ),
        NovelListTile(
          title: 'مدن الرماد',
          subtitle: 'الفصل 41 متاح الآن',
          meta: 'منذ ساعة',
        ),
        SectionHeader(title: 'روايات محدثة'),
        NovelListTile(
          title: 'بوابة الشمال',
          subtitle: 'خيال، أكشن، مغامرة',
          meta: '126 فصل',
        ),
      ],
    );
  }
}
