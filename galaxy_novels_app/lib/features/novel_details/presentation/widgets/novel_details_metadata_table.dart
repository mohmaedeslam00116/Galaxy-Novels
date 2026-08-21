import 'package:flutter/material.dart';

import '../../../../data/models/novel_details_data.dart';
import '../../../../design_system/patterns/galaxy_progressive_info_table.dart';

class NovelDetailsMetadataTable extends StatelessWidget {
  const NovelDetailsMetadataTable({required this.details, super.key});

  final NovelDetails details;

  @override
  Widget build(BuildContext context) {
    final secondaryItems = <GalaxyInfoItem>[
      if (details.originalTitle.trim().isNotEmpty)
        GalaxyInfoItem(
          key: const ValueKey('novel-metadata-original-title'),
          icon: Icons.title_rounded,
          label: 'الاسم الأصلي',
          value: details.originalTitle.trim(),
        ),
      if (details.country.trim().isNotEmpty)
        GalaxyInfoItem(
          key: const ValueKey('novel-metadata-country'),
          icon: Icons.public_rounded,
          label: 'البلد',
          value: _countryLabel(details.country),
        ),
      if (details.updatedAt case final updatedAt?)
        GalaxyInfoItem(
          key: const ValueKey('novel-metadata-updated-at'),
          icon: Icons.update_rounded,
          label: 'آخر تحديث',
          value: _dateLabel(updatedAt),
        ),
    ];
    return GalaxyProgressiveInfoTable(
      key: const ValueKey('novel-details-metadata-table'),
      primaryItems: [
        GalaxyInfoItem(
          key: const ValueKey('novel-metadata-author'),
          icon: Icons.person_outline_rounded,
          label: 'الكاتب',
          value: _orUnavailable(details.author),
        ),
        GalaxyInfoItem(
          key: const ValueKey('novel-metadata-translator'),
          icon: Icons.translate_rounded,
          label: 'المترجم',
          value: _orUnavailable(details.translator),
        ),
      ],
      secondaryItems: secondaryItems,
    );
  }
}

String _orUnavailable(String rawValue) {
  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? 'غير متوفر' : trimmed;
}

String _countryLabel(String rawValue) {
  final normalized = rawValue.trim().toLowerCase();
  return switch (normalized) {
    'cn' || 'china' => 'الصين',
    'kr' || 'korea' || 'south korea' => 'كوريا الجنوبية',
    'jp' || 'japan' => 'اليابان',
    'us' || 'usa' || 'united states' => 'الولايات المتحدة',
    _ => rawValue.trim(),
  };
}

String _dateLabel(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
}
