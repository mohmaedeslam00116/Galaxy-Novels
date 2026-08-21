import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/platform/app_json_document_picker.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_advanced_terminology_repository.dart';
import 'package:galaxy_novels_app/features/reader/data/stored_reader_advanced_terminology_repository.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_advanced_terminology.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_advanced_terminology_screen.dart';

void main() {
  testWidgets('imports a valid pack after showing a preview', (tester) async {
    final repository = _repository(unlocked: true);
    await repository.load();
    await tester.pumpWidget(
      _surface(
        ReaderAdvancedTerminologyScreen(
          repository: repository,
          documentPicker: _FakePicker(_packBytes()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('advanced-terms-import')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('معاينة الحزمة'), findsOneWidget);
    expect(find.textContaining('قاعدتا استبدال'), findsOneWidget);
    expect(find.textContaining('جملة حماية واحدة'), findsOneWidget);
    expect(find.textContaining('2.5.45'), findsOneWidget);
    expect(find.textContaining('galaxynovels.com'), findsOneWidget);
    expect(find.textContaining('كل فصلين'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('advanced-terms-confirm-import')),
    );
    await tester.pumpAndSettle();

    expect(repository.value.pack, isNotNull);
    expect(find.text('إدارة قواعد الحزمة'), findsOneWidget);
    expect(find.text('الاستبدالات'), findsWidgets);
  });

  testWidgets('hiding tools disables the pack but keeps its data', (
    tester,
  ) async {
    final repository = _repository(unlocked: true);
    await repository.load();
    final preview = parseReaderTerminologyPack(_packBytes());
    await repository.replacePack(preview, features: preview.initialFeatures);
    await tester.pumpWidget(
      _surface(
        ReaderAdvancedTerminologyScreen(
          repository: repository,
          documentPicker: const _FakePicker(null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('advanced-terms-hide-tools')),
      300,
    );
    await tester.tap(find.byKey(const ValueKey('advanced-terms-hide-tools')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إخفاء وتعطيل'));
    await tester.pumpAndSettle();

    expect(repository.value.accessUnlocked, isFalse);
    expect(repository.value.packEnabled, isFalse);
    expect(repository.value.pack, isNotNull);
  });
}

Widget _surface(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark(),
    locale: const Locale('ar'),
    home: Directionality(textDirection: TextDirection.rtl, child: child),
  );
}

StoredReaderAdvancedTerminologyRepository _repository({
  required bool unlocked,
}) {
  return StoredReaderAdvancedTerminologyRepository(
    stateStore: _MemoryStateStore(),
    accessStore: _MemoryAccessStore(unlocked),
  );
}

Uint8List _packBytes() {
  return Uint8List.fromList(
    utf8.encode(
      jsonEncode({
        'schema_version': 1,
        'type': 'wor_reader_publish_commands',
        'theme_version': '2.5.45',
        'site_url': 'https://galaxynovels.com/',
        'settings': {
          'guard_enabled': 1,
          'guard_every': 2,
          'guard_sentences': ['رسالة حماية'],
          'filter_enabled': 1,
          'word_rules': [
            {'from': 'إله', 'to': 'حاكم'},
          ],
          'phrase_rules': [
            {'from': 'القوة الإلهية', 'to': 'القوة السامية'},
          ],
          'exceptions': ['لا إله إلا الله'],
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

class _FakePicker implements AppJsonDocumentPicker {
  const _FakePicker(this.bytes);

  final Uint8List? bytes;

  @override
  Future<Uint8List?> pickJson() async => bytes;
}

class _MemoryStateStore implements ReaderAdvancedTerminologyStateStore {
  String? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _MemoryAccessStore implements ReaderAdvancedTerminologyAccessStore {
  _MemoryAccessStore(this.value);

  bool value;

  @override
  Future<bool> read() async => value;

  @override
  Future<void> write(bool value) async => this.value = value;
}
