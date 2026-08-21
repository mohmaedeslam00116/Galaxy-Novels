import 'package:flutter/material.dart';

import '../../../../data/models/novel_details_data.dart';
import '../../../../design_system/novel/galaxy_chapter_row.dart';

class NovelChapterTile extends StatelessWidget {
  const NovelChapterTile({
    required this.chapter,
    required this.onTap,
    super.key,
  });

  final NovelChapter chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final number = chapter.number.isNotEmpty
        ? chapter.number
        : '${chapter.position}';
    final subtitle = chapter.displayTitle.isNotEmpty
        ? chapter.displayTitle
        : chapter.dateLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GalaxyChapterRow(
        chapter: GalaxyChapterRowData(
          title: chapter.label.isNotEmpty ? chapter.label : 'فصل',
          subtitle: subtitle.isNotEmpty ? subtitle : null,
          leadingLabel: number,
        ),
        onTap: onTap,
        showAction: false,
        showNavigationIndicator: true,
      ),
    );
  }
}
