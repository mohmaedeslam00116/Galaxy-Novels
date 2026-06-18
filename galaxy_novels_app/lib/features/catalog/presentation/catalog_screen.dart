import 'package:flutter/material.dart';

import '../../../shared/widgets/novel_list_tile.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ابحث عن رواية أو مؤلف',
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(label: Text('الكل'), selected: true, onSelected: null),
            FilterChip(
              label: Text('مستمرة'),
              selected: false,
              onSelected: null,
            ),
            FilterChip(
              label: Text('مكتملة'),
              selected: false,
              onSelected: null,
            ),
            FilterChip(
              label: Text('الأحدث'),
              selected: false,
              onSelected: null,
            ),
          ],
        ),
        SizedBox(height: 12),
        NovelListTile(
          title: 'حارس النجوم',
          subtitle: 'أكشن، خيال علمي',
          meta: '82 فصل - مستمرة',
        ),
        NovelListTile(
          title: 'مدن الرماد',
          subtitle: 'دراما، بقاء',
          meta: '41 فصل - مستمرة',
        ),
        NovelListTile(
          title: 'بوابة الشمال',
          subtitle: 'مغامرة، فانتازيا',
          meta: '126 فصل - مكتملة',
        ),
      ],
    );
  }
}
