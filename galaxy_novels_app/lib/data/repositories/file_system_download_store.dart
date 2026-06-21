import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/downloaded_chapter.dart';
import 'local_download_store.dart';

class FileSystemDownloadStore
    implements
        LocalDownloadStore,
        ClearableDownloadStore,
        DownloadContentStore {
  FileSystemDownloadStore({
    Directory? rootDirectory,
    LocalDownloadStore? legacyStore,
  }) : _rootDirectory = rootDirectory,
       _legacyStore = legacyStore;

  static const _indexVersion = 2;
  static const _directoryName = 'downloads_v2';
  static const _indexFileName = 'index.json';

  final Directory? _rootDirectory;
  final LocalDownloadStore? _legacyStore;
  Directory? _fallbackDirectory;

  @override
  Future<List<DownloadedChapter>> readChapters() async {
    final directory = await _directory();
    final indexFile = File(_join(directory.path, _indexFileName));
    if (!await indexFile.exists()) {
      return _migrateLegacy();
    }

    try {
      final decoded = jsonDecode(await indexFile.readAsString());
      if (decoded is! Map || decoded['version'] != _indexVersion) {
        return const [];
      }
      final entries = decoded['chapters'];
      if (entries is! List) {
        return const [];
      }

      final chapters = await Future.wait(
        entries.whereType<Map>().map((entry) => _readEntry(directory, entry)),
      );
      return chapters.whereType<DownloadedChapter>().toList(growable: false);
    } on FileSystemException {
      return const [];
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  Future<void> writeChapters(List<DownloadedChapter> chapters) async {
    final directory = await _directory();
    await directory.create(recursive: true);

    final entries = <Map<String, dynamic>>[];
    final activeFiles = <String>{};
    for (final chapter in chapters) {
      final contentFileName = _contentFileName(chapter);
      activeFiles.add(contentFileName);
      final contentFile = File(_join(directory.path, contentFileName));
      if (chapter.contentHtml.isNotEmpty && !await contentFile.exists()) {
        await _writeAtomic(contentFile, chapter.contentHtml);
      }

      final metadata = Map<String, dynamic>.from(chapter.toJson())
        ..remove('contentHtml')
        ..['contentFile'] = contentFileName;
      entries.add(metadata);
    }

    final index = jsonEncode({'version': _indexVersion, 'chapters': entries});
    await _writeAtomic(File(_join(directory.path, _indexFileName)), index);
    await _removeOrphanedContentFiles(directory, activeFiles);
  }

  @override
  Future<void> clear() async {
    final directory = await _directory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<String?> readChapterContent(DownloadedChapter chapter) async {
    final directory = await _directory();
    final contentFile = File(_join(directory.path, _contentFileName(chapter)));
    if (!await contentFile.exists()) {
      return null;
    }
    try {
      return await contentFile.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  Future<List<DownloadedChapter>> _migrateLegacy() async {
    final legacyStore = _legacyStore;
    if (legacyStore == null) {
      return const [];
    }

    final chapters = await legacyStore.readChapters();
    if (chapters.isEmpty) {
      return const [];
    }

    await writeChapters(chapters);
    if (legacyStore case final ClearableDownloadStore clearableStore) {
      await clearableStore.clear();
    } else {
      await legacyStore.writeChapters(const []);
    }
    return readChapters();
  }

  Future<DownloadedChapter?> _readEntry(Directory directory, Map entry) async {
    final metadata = _asMap(entry);
    final contentFileName = metadata.remove('contentFile')?.toString() ?? '';
    if (!_isSafeFileName(contentFileName)) {
      return null;
    }

    final contentFile = File(_join(directory.path, contentFileName));
    if (!await contentFile.exists()) {
      return null;
    }

    return DownloadedChapter.fromJson({...metadata, 'contentHtml': ''});
  }

  Future<Directory> _directory() async {
    final configured = _rootDirectory;
    if (configured != null) {
      return configured;
    }
    try {
      final supportDirectory = await getApplicationSupportDirectory();
      return Directory(_join(supportDirectory.path, _directoryName));
    } on MissingPluginException {
      return _fallbackDirectory ??= await Directory.systemTemp.createTemp(
        'galaxy_novels_downloads_',
      );
    }
  }

  Future<void> _removeOrphanedContentFiles(
    Directory directory,
    Set<String> activeFiles,
  ) async {
    await for (final entity in directory.list()) {
      if (entity is! File) {
        continue;
      }
      final name = _fileName(entity.path);
      if (name.endsWith('.html') && !activeFiles.contains(name)) {
        await entity.delete();
      }
    }
  }
}

Future<void> _writeAtomic(File target, String contents) async {
  await target.parent.create(recursive: true);
  final temporary = File('${target.path}.next');
  await temporary.writeAsString(contents, flush: true);
  if (await target.exists()) {
    await target.delete();
  }
  await temporary.rename(target.path);
}

String _contentFileName(DownloadedChapter chapter) {
  final apiHash = _fnv1a32(chapter.contentApi).toRadixString(16);
  return '${chapter.novelId}_${chapter.chapterId}_$apiHash.html';
}

int _fnv1a32(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

bool _isSafeFileName(String value) {
  return value.isNotEmpty &&
      value == _fileName(value) &&
      value.endsWith('.html');
}

String _join(String parent, String child) {
  return '$parent${Platform.pathSeparator}$child';
}

String _fileName(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

Map<String, dynamic> _asMap(Map value) {
  return value.map((key, value) => MapEntry(key.toString(), value));
}
