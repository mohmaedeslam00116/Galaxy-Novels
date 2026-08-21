import 'dart:io';

import 'package:path/path.dart' as paths;
import 'package:path_provider/path_provider.dart';

import '../application/reader_advanced_terminology_repository.dart';

typedef ReaderTerminologyDirectoryProvider = Future<Directory> Function();

class FileReaderAdvancedTerminologyStateStore
    implements ReaderAdvancedTerminologyStateStore {
  FileReaderAdvancedTerminologyStateStore({
    ReaderTerminologyDirectoryProvider? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const fileName = 'reader_advanced_terminology.v1.json';

  final ReaderTerminologyDirectoryProvider _directoryProvider;

  @override
  Future<String?> read() async {
    final directory = await _directoryProvider();
    final file = File(paths.join(directory.path, fileName));
    if (await file.exists()) return file.readAsString();
    final backup = File('${file.path}.backup');
    if (!await backup.exists()) return null;
    return backup.readAsString();
  }

  @override
  Future<void> write(String value) async {
    final directory = await _directoryProvider();
    await directory.create(recursive: true);
    final file = File(paths.join(directory.path, fileName));
    final temporary = File('${file.path}.temporary');
    final backup = File('${file.path}.backup');
    await temporary.writeAsString(value, flush: true);

    var movedExisting = false;
    try {
      if (await backup.exists()) await backup.delete();
      if (await file.exists()) {
        await file.rename(backup.path);
        movedExisting = true;
      }
      await temporary.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      if (movedExisting && !await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    final directory = await _directoryProvider();
    final file = File(paths.join(directory.path, fileName));
    for (final target in [
      file,
      File('${file.path}.temporary'),
      File('${file.path}.backup'),
    ]) {
      if (await target.exists()) await target.delete();
    }
  }
}
