import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_advanced_terminology_repository.dart';
import 'package:galaxy_novels_app/features/reader/data/stored_reader_advanced_terminology_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_term_replacement.dart';

void main() {
  test(
    'imports a pack and restores it with separately stored access',
    () async {
      final stateStore = _MemoryStateStore();
      final accessStore = _MemoryAccessStore();
      final repository = StoredReaderAdvancedTerminologyRepository(
        stateStore: stateStore,
        accessStore: accessStore,
      );
      final preview = _preview();

      await repository.unlock();
      await repository.replacePack(
        preview,
        features: preview.initialFeatures.copyWith(footerRemoval: false),
      );

      expect(repository.value.accessUnlocked, isTrue);
      expect(repository.value.packEnabled, isTrue);
      expect(repository.value.features.footerRemoval, isFalse);
      expect(repository.value.pack?.replacements, hasLength(1));

      final restored = StoredReaderAdvancedTerminologyRepository(
        stateStore: stateStore,
        accessStore: accessStore,
      );
      await restored.load();
      expect(restored.value.accessUnlocked, isTrue);
      expect(restored.value.packEnabled, isTrue);
      expect(restored.value.pack?.siteUrl, 'https://galaxynovels.com/');
    },
  );

  test(
    'hiding tools disables transformations but preserves imported data',
    () async {
      final repository = StoredReaderAdvancedTerminologyRepository(
        stateStore: _MemoryStateStore(),
        accessStore: _MemoryAccessStore(),
      );
      await repository.unlock();
      await repository.replacePack(
        _preview(),
        features: ReaderPackFeatureSelection.enabled,
      );

      await repository.hideTools();

      expect(repository.value.accessUnlocked, isFalse);
      expect(repository.value.packEnabled, isFalse);
      expect(repository.value.pack, isNotNull);
    },
  );

  test(
    'failed state write leaves the visible repository value unchanged',
    () async {
      final stateStore = _MemoryStateStore()..failWrites = true;
      final repository = StoredReaderAdvancedTerminologyRepository(
        stateStore: stateStore,
        accessStore: _MemoryAccessStore(initial: true),
      );
      await repository.load();
      final before = repository.value;

      await expectLater(
        repository.replacePack(
          _preview(),
          features: ReaderPackFeatureSelection.enabled,
        ),
        throwsStateError,
      );

      expect(repository.value, same(before));
    },
  );

  test('corrupt pack state preserves the separately stored unlock', () async {
    final stateStore = _MemoryStateStore()..value = '{not-json';
    final repository = StoredReaderAdvancedTerminologyRepository(
      stateStore: stateStore,
      accessStore: _MemoryAccessStore(initial: true),
    );

    await repository.load();

    expect(repository.value.accessUnlocked, isTrue);
    expect(repository.value.pack, isNull);
    expect(repository.value.packEnabled, isFalse);
  });

  test('upserts scoped removals and edits pack rule overlays', () async {
    final repository = StoredReaderAdvancedTerminologyRepository(
      stateStore: _MemoryStateStore(),
      accessStore: _MemoryAccessStore(initial: true),
    );
    await repository.load();
    await repository.replacePack(
      _preview(),
      features: ReaderPackFeatureSelection.enabled,
    );
    const removal = ReaderTextRemovalRule(
      source: 'عبارة مزعجة',
      scope: ReaderTermScope.currentNovel,
      novelId: 12,
    );

    await repository.savePersonalRemoval(removal);
    await repository.setReplacementOverride('إله', 'سلطان');
    await repository.setRuleEnabled(
      ReaderAdvancedRuleKind.exception,
      'لا إله إلا الله',
      false,
    );

    expect(repository.value.personalRemovals, [removal]);
    expect(repository.value.replacementOverrides['إله'], 'سلطان');
    expect(repository.value.disabledExceptions, contains('لا إله إلا الله'));

    await repository.restoreRule(ReaderAdvancedRuleKind.replacement, 'إله');
    expect(repository.value.replacementOverrides, isEmpty);
  });

  test(
    'new pack retains overlays only for sources it still contains',
    () async {
      final repository = StoredReaderAdvancedTerminologyRepository(
        stateStore: _MemoryStateStore(),
        accessStore: _MemoryAccessStore(initial: true),
      );
      await repository.load();
      await repository.replacePack(
        _preview(),
        features: ReaderPackFeatureSelection.enabled,
      );
      await repository.setReplacementOverride('إله', 'سلطان');
      await repository.setRuleEnabled(
        ReaderAdvancedRuleKind.removal,
        'رسالة حماية',
        false,
      );
      await repository.savePersonalException('استثناء شخصي');

      await repository.replacePack(
        _preview(
          source: 'وحش',
          replacement: 'مخلوق',
          guard: 'رسالة جديدة',
          exception: 'استثناء جديد',
        ),
        features: ReaderPackFeatureSelection.enabled,
      );

      expect(repository.value.replacementOverrides, isEmpty);
      expect(repository.value.disabledGuardSentences, isEmpty);
      expect(repository.value.personalExceptions, ['استثناء شخصي']);
    },
  );
}

ReaderTerminologyImportPreview _preview({
  String source = 'إله',
  String replacement = 'حاكم',
  String guard = 'رسالة حماية',
  String exception = 'لا إله إلا الله',
}) {
  return parseReaderTerminologyPack(
    utf8.encode(
      jsonEncode({
        'schema_version': 1,
        'type': 'wor_reader_publish_commands',
        'theme_version': '2.5.45',
        'site_url': 'https://galaxynovels.com/',
        'settings': {
          'guard_enabled': 1,
          'guard_every': 2,
          'guard_sentences': [guard],
          'filter_enabled': 1,
          'word_rules': [
            {'from': source, 'to': replacement},
          ],
          'phrase_rules': <Object?>[],
          'exceptions': [exception],
          'footer_enabled': 1,
          'footer_every': 2,
          'footer_content': '<p>انتهى الفصل</p>',
          'defaults_inline': {'guard': 1, 'filter': 1, 'footer': 1},
          'defaults_bulk': {'guard': 1, 'filter': 1, 'footer': 1},
        },
      }),
    ),
  );
}

class _MemoryStateStore implements ReaderAdvancedTerminologyStateStore {
  String? value;
  bool failWrites = false;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('write failed');
    this.value = value;
  }
}

class _MemoryAccessStore implements ReaderAdvancedTerminologyAccessStore {
  _MemoryAccessStore({bool initial = false}) : value = initial;

  bool value;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool value) async => this.value = value;
}
