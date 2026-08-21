import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/models/reader_content_data.dart';
import 'package:galaxy_novels_app/features/downloads/data/downloaded_chapter_file_store.dart';
import 'package:galaxy_novels_app/features/downloads/data/secure_download_key_store.dart';

void main() {
  late Directory directory;
  late DownloadedChapterFileStore files;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('galaxy_chapters_');
    files = DownloadedChapterFileStore(
      rootDirectory: directory,
      keyStore: _FixedKeyStore(_key(1)),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  test('public chapters round-trip through stable JSON', () async {
    final publicPath = await files.writePublic('public:4', _content);
    final decoded = await files.readPublic(publicPath);

    expect(decoded.id, _content.id);
    expect(decoded.novelId, _content.novelId);
    expect(decoded.contentHtml, _content.contentHtml);
    expect(decoded.navigation.previousApi, _content.navigation.previousApi);
    expect(File(publicPath).existsSync(), isTrue);
    expect(File('$publicPath.part').existsSync(), isFalse);
  });

  test(
    'VIP chapters are encrypted and round-trip with the device key',
    () async {
      final vipPath = await files.writeVip('vip:9', _content);
      final raw = await File(vipPath).readAsString();
      final decoded = await files.readVip(vipPath);

      expect(raw, startsWith('GNVIP1\n'));
      expect(raw, isNot(contains(_content.contentHtml)));
      expect(decoded.id, _content.id);
      expect(decoded.contentHtml, _content.contentHtml);
      expect(offlineChapterUri('vip:9'), 'galaxy-download://chapter/vip%3A9');
    },
  );

  test('a different device key cannot decrypt a VIP chapter', () async {
    final vipPath = await files.writeVip('vip:9', _content);
    final wrongKeyFiles = DownloadedChapterFileStore(
      rootDirectory: directory,
      keyStore: _FixedKeyStore(_key(2)),
    );

    expect(
      () => wrongKeyFiles.readVip(vipPath),
      throwsA(isA<DownloadFileCorruptException>()),
    );
  });

  test('truncated encrypted content is rejected explicitly', () async {
    final path = await files.writeVip('vip:9', _content);
    await File(path).writeAsString('GNVIP1\ntruncated');

    expect(
      () => files.readVip(path),
      throwsA(isA<DownloadFileCorruptException>()),
    );
  });

  test(
    'reconcile removes part files and reports missing final files',
    () async {
      final existing = await files.writePublic('public:4', _content);
      final orphan = File(
        '${directory.path}${Platform.pathSeparator}orphan.part',
      );
      await orphan.writeAsString('partial');
      final missing =
          '${directory.path}${Platform.pathSeparator}missing.gnchapter';

      final result = await files.reconcile([existing, missing]);

      expect(result.removedPartPaths, [orphan.path]);
      expect(result.missingPaths, [missing]);
      expect(orphan.existsSync(), isFalse);
    },
  );

  test('delete ignores absent files and removes an existing chapter', () async {
    final path = await files.writePublic('public:4', _content);

    await files.delete(path);
    await files.delete(path);

    expect(File(path).existsSync(), isFalse);
  });

  test('temporary-file cleanup is idempotent', () async {
    final temporary = File(
      '${directory.path}${Platform.pathSeparator}completed-download.tmp',
    );
    await temporary.writeAsString('done');

    await deleteDownloadTemporaryFile(temporary);
    await deleteDownloadTemporaryFile(temporary);

    expect(temporary.existsSync(), isFalse);
  });
}

SecretKey _key(int seed) {
  return SecretKey(List<int>.generate(32, (index) => (index + seed) % 256));
}

class _FixedKeyStore implements DownloadKeyStore {
  const _FixedKeyStore(this.key);

  final SecretKey key;

  @override
  Future<SecretKey> readOrCreate() async => key;
}

const _content = ReaderChapterContent(
  id: 9,
  novelId: 3,
  label: 'الفصل التاسع',
  title: 'عنوان الفصل',
  displayTitle: 'الفصل التاسع: عنوان الفصل',
  position: 9,
  total: 40,
  contentHtml: '<p>محتوى خاص لا ينبغي ظهوره خامًا</p>',
  navigation: ReaderChapterNavigation(
    previousApi: '/chapters/8',
    nextApi: '/chapters/10',
    previousId: 8,
    nextId: 10,
  ),
);
