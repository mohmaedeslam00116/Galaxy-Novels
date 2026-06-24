import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'public_cache_client.dart';

typedef CacheDirectoryProvider = Future<Directory> Function();

class FileSystemPublicCacheStore implements PublicCacheStore {
  FileSystemPublicCacheStore({CacheDirectoryProvider? directoryProvider})
    : _directoryProvider = directoryProvider ?? _defaultDirectoryProvider;

  final CacheDirectoryProvider _directoryProvider;

  @override
  Future<String?> read(String key) async {
    final file = await _fileForKey(key);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> write(String key, String value) async {
    final file = await _fileForKey(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(value, flush: true);
  }

  Future<File> _fileForKey(String key) async {
    final root = await _directoryProvider();
    return File('${root.path}${Platform.pathSeparator}${_stableFileName(key)}');
  }

  static Future<Directory> _defaultDirectoryProvider() async {
    final support = await getApplicationSupportDirectory();
    return Directory(
      '${support.path}${Platform.pathSeparator}public_json_cache_v1',
    );
  }
}

String _stableFileName(String key) {
  var hash = 0xcbf29ce484222325;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  return '${hash.toRadixString(16).padLeft(16, '0')}.json';
}
