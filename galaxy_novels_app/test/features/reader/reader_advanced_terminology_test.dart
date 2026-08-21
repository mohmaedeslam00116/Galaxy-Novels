import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_text_transformer.dart';

void main() {
  group('Reader terminology pack parser', () {
    test(
      'parses the supplied production pack when its path is provided',
      () async {
        const path = String.fromEnvironment('READER_PACK_TEST_PATH');
        if (path.isEmpty) return;

        final file = File(path);
        expect(await file.exists(), isTrue, reason: 'Pack fixture must exist.');
        final preview = parseReaderTerminologyPack(await file.readAsBytes());

        expect(preview.rawReplacementCount, 68);
        expect(preview.pack.replacements, hasLength(67));
        expect(preview.duplicateReplacementCount, 1);
        expect(preview.pack.exceptions, hasLength(18));
        expect(preview.pack.guardSentences, hasLength(87));
        expect(preview.pack.footerText, isNotEmpty);
      },
    );

    test(
      'parses v1 pack, deduplicates identical rules, and keeps metadata',
      () {
        final preview = parseReaderTerminologyPack(
          utf8.encode(_validPackJson()),
        );

        expect(preview.pack.type, 'wor_reader_publish_commands');
        expect(preview.pack.schemaVersion, 1);
        expect(preview.pack.themeVersion, '2.5.45');
        expect(preview.rawReplacementCount, 3);
        expect(preview.pack.replacements, hasLength(2));
        expect(preview.duplicateReplacementCount, 1);
        expect(preview.pack.guardSentences, ['رسالة حماية طويلة']);
        expect(preview.pack.exceptions, ['لا إله إلا الله']);
        expect(preview.pack.footerText, contains('انتهى الفصل'));
        expect(preview.pack.defaultsInline, {
          'guard': true,
          'filter': true,
          'footer': true,
        });
        expect(preview.pack.defaultsBulk, preview.pack.defaultsInline);
        expect(preview.initialFeatures.replacements, isTrue);
        expect(preview.initialFeatures.guardRemoval, isTrue);
        expect(preview.initialFeatures.footerRemoval, isTrue);
      },
    );

    test(
      'rejects conflicting replacements without returning a partial pack',
      () {
        final json = _validPackJson().replaceFirst(
          '{"from":"إله","to":"حاكم"}',
          '{"from":"إله","to":"سلطان"}',
        );

        expect(
          () => parseReaderTerminologyPack(utf8.encode(json)),
          throwsA(
            isA<ReaderTerminologyImportException>().having(
              (error) => error.code,
              'code',
              ReaderTerminologyImportError.conflictingRule,
            ),
          ),
        );
      },
    );

    test('rejects unsupported type and schema', () {
      expect(
        () => parseReaderTerminologyPack(
          utf8.encode(_validPackJson(type: 'unknown')),
        ),
        throwsA(isA<ReaderTerminologyImportException>()),
      );
      expect(
        () => parseReaderTerminologyPack(
          utf8.encode(_validPackJson(schemaVersion: 2)),
        ),
        throwsA(isA<ReaderTerminologyImportException>()),
      );
    });
  });

  group('Reader text transformer', () {
    final pack = parseReaderTerminologyPack(utf8.encode(_validPackJson())).pack;

    test(
      'removes exact injected text while preserving the rest of paragraph',
      () {
        final result = transformReaderText(
          text: 'بداية الفصل. رسالة حماية طويلة ثم تابع البطل طريقه.',
          novelId: 7,
          personalReplacements: const [],
          advancedState: ReaderAdvancedTerminologyState.defaults.copyWith(
            accessUnlocked: true,
            packEnabled: true,
            pack: pack,
          ),
        );

        expect(result.text, 'بداية الفصل. ثم تابع البطل طريقه.');
        expect(result.isEmpty, isFalse);
      },
    );

    test('protects exceptions and does not cascade replacement output', () {
      const personalRules = [
        ReaderTermReplacement(
          source: 'الحاكم',
          replacement: 'السلطان',
          scope: ReaderTermScope.allNovels,
          novelId: 0,
        ),
      ];
      final result = transformReaderText(
        text: 'قال: لا إله إلا الله، ثم ظهر إله قديم.',
        novelId: 7,
        personalReplacements: personalRules,
        advancedState: ReaderAdvancedTerminologyState.defaults.copyWith(
          accessUnlocked: true,
          packEnabled: true,
          pack: pack,
        ),
      );

      expect(result.text, 'قال: لا إله إلا الله، ثم ظهر حاكم قديم.');
      expect(
        result.segments.where((segment) => segment.isReplacement).single.text,
        'حاكم',
      );
    });

    test('current novel personal rule overrides global and pack rules', () {
      const personalRules = [
        ReaderTermReplacement(
          source: 'إله',
          replacement: 'زعيم',
          scope: ReaderTermScope.allNovels,
          novelId: 0,
        ),
        ReaderTermReplacement(
          source: 'إله',
          replacement: 'ملك',
          scope: ReaderTermScope.currentNovel,
          novelId: 7,
        ),
      ];
      final state = ReaderAdvancedTerminologyState.defaults.copyWith(
        accessUnlocked: true,
        packEnabled: true,
        pack: pack,
      );

      expect(
        transformReaderText(
          text: 'إله قديم',
          novelId: 7,
          personalReplacements: personalRules,
          advancedState: state,
        ).text,
        'ملك قديم',
      );
      expect(
        transformReaderText(
          text: 'إله قديم',
          novelId: 8,
          personalReplacements: personalRules,
          advancedState: state,
        ).text,
        'زعيم قديم',
      );
    });

    test('explicit personal removal can remove a protected phrase', () {
      final state = ReaderAdvancedTerminologyState.defaults.copyWith(
        accessUnlocked: true,
        packEnabled: true,
        pack: pack,
        personalRemovals: const [
          ReaderTextRemovalRule(
            source: 'لا إله إلا الله',
            scope: ReaderTermScope.allNovels,
            novelId: 0,
          ),
        ],
      );

      expect(
        transformReaderText(
          text: 'قال لا إله إلا الله ثم جلس.',
          novelId: 7,
          personalReplacements: const [],
          advancedState: state,
        ).text,
        'قال ثم جلس.',
      );
    });

    test('matches normalized spaces without changing unrelated NBSP', () {
      final result = transformReaderText(
        text: 'هنا\u00A0القوة\u00A0الإلهية',
        novelId: 7,
        personalReplacements: const [],
        advancedState: ReaderAdvancedTerminologyState.defaults.copyWith(
          accessUnlocked: true,
          packEnabled: true,
          pack: pack,
        ),
      );

      expect(result.text, 'هنا\u00A0القوة السامية');
    });
  });
}

String _validPackJson({
  String type = 'wor_reader_publish_commands',
  int schemaVersion = 1,
}) {
  return jsonEncode({
    'schema_version': schemaVersion,
    'type': type,
    'theme_version': '2.5.45',
    'site_url': 'https://galaxynovels.com/',
    'settings': {
      'guard_enabled': 1,
      'guard_every': 2,
      'guard_sentences': ['رسالة حماية طويلة'],
      'filter_enabled': 1,
      'word_rules': [
        {'from': 'إله', 'to': 'حاكم'},
        {'from': 'إله', 'to': 'حاكم'},
      ],
      'phrase_rules': [
        {'from': 'القوة الإلهية', 'to': 'القوة السامية'},
      ],
      'exceptions': ['لا إله إلا الله'],
      'footer_enabled': 1,
      'footer_every': 2,
      'footer_content': '<p>✦ انتهى الفصل ✦<br>قراءة ممتعة</p>',
      'defaults_inline': {'guard': 1, 'filter': 1, 'footer': 1},
      'defaults_bulk': {'guard': 1, 'filter': 1, 'footer': 1},
    },
  });
}
