import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('design system never imports feature, data, or repository layers', () {
    final designSystemDirectory = Directory('lib/design_system');

    expect(designSystemDirectory.existsSync(), isTrue);
    final forbiddenImports = <String>[];
    for (final sourceFile
        in designSystemDirectory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      final source = sourceFile.readAsStringSync();
      if (source.contains('/features/') ||
          source.contains('/data/') ||
          source.contains('/repositories/')) {
        forbiddenImports.add(sourceFile.path);
      }
    }

    expect(forbiddenImports, isEmpty);
  });

  test('phase one screens depend on the shared design system', () {
    const migratedFiles = [
      'lib/features/home/presentation/home_poster_card.dart',
      'lib/features/home/presentation/home_section_header.dart',
      'lib/features/catalog/presentation/widgets/catalog_novel_tile.dart',
      'lib/features/novel_details/presentation/widgets/novel_details_header.dart',
      'lib/features/novel_details/presentation/widgets/readable_chapter_tile.dart',
    ];

    for (final path in migratedFiles) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('design_system/'),
        reason: '$path must remain an adapter over Galaxy Design System.',
      );
      expect(source, isNot(contains('BackdropFilter(')));
      expect(source, isNot(contains('BoxShadow(')));
    }
  });
}
