import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;

import '../../../data/models/reader_content_data.dart';
import 'reader_content_codec.dart';
import 'secure_download_key_store.dart';

Future<void> deleteDownloadTemporaryFile(File file) async {
  try {
    await file.delete();
  } on PathNotFoundException {
    // A late or duplicate native completion may have already removed it.
  }
}

class DownloadedChapterFileStore {
  DownloadedChapterFileStore({
    required Directory rootDirectory,
    required DownloadKeyStore keyStore,
    ReaderContentCodec codec = const ReaderContentCodec(),
    AesGcm? cipher,
  }) : _rootDirectory = rootDirectory,
       _keyStore = keyStore,
       _codec = codec,
       _cipher = cipher ?? AesGcm.with256bits();

  static const _vipHeader = 'GNVIP1';

  final Directory _rootDirectory;
  final DownloadKeyStore _keyStore;
  final ReaderContentCodec _codec;
  final AesGcm _cipher;

  Future<String> writePublic(String chapterKey, ReaderChapterContent content) {
    return _writeAtomically(chapterKey, utf8.encode(_codec.encode(content)));
  }

  Future<String> writeVip(
    String chapterKey,
    ReaderChapterContent content,
  ) async {
    final key = await _keyStore.readOrCreate();
    final secretBox = await _cipher.encrypt(
      utf8.encode(_codec.encode(content)),
      secretKey: key,
    );
    final payload = [
      _vipHeader,
      base64Encode(secretBox.nonce),
      base64Encode(secretBox.mac.bytes),
      base64Encode(secretBox.cipherText),
    ].join('\n');
    return _writeAtomically(chapterKey, utf8.encode(payload));
  }

  Future<ReaderChapterContent> readPublic(String storedPath) async {
    try {
      final encoded = await _validatedFile(storedPath).readAsString();
      return _codec.decode(encoded);
    } on DownloadFileException {
      rethrow;
    } on FormatException catch (error) {
      throw DownloadFileCorruptException(storedPath, error);
    }
  }

  Future<ReaderChapterContent> readVip(String storedPath) async {
    try {
      final payload = await _validatedFile(storedPath).readAsString();
      final lines = payload.split('\n');
      if (lines.length != 4 || lines.first != _vipHeader) {
        throw const FormatException('Invalid encrypted chapter envelope.');
      }
      final box = SecretBox(
        base64Decode(lines[3]),
        nonce: base64Decode(lines[1]),
        mac: Mac(base64Decode(lines[2])),
      );
      final clearBytes = await _cipher.decrypt(
        box,
        secretKey: await _keyStore.readOrCreate(),
      );
      return _codec.decode(utf8.decode(clearBytes));
    } on DownloadFileException {
      rethrow;
    } on FormatException catch (error) {
      throw DownloadFileCorruptException(storedPath, error);
    } on SecretBoxAuthenticationError catch (error) {
      throw DownloadFileCorruptException(storedPath, error);
    }
  }

  Future<void> delete(String storedPath) async {
    final file = _validatedFile(storedPath, requireExisting: false);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<DownloadFileReconciliation> reconcile(
    Iterable<String> expectedPaths,
  ) async {
    await _ensureRoot();
    final removed = <String>[];
    await for (final entity in _rootDirectory.list()) {
      if (entity is File && entity.path.endsWith('.part')) {
        removed.add(entity.path);
        await entity.delete();
      }
    }
    removed.sort();

    final missing = <String>[];
    for (final storedPath in expectedPaths) {
      final file = _validatedFile(storedPath, requireExisting: false);
      if (!await file.exists()) missing.add(file.path);
    }
    missing.sort();
    return DownloadFileReconciliation(
      missingPaths: List.unmodifiable(missing),
      removedPartPaths: List.unmodifiable(removed),
    );
  }

  Future<String> _writeAtomically(String chapterKey, List<int> bytes) async {
    await _ensureRoot();
    final finalFile = File(
      path.join(_rootDirectory.path, '${_safeName(chapterKey)}.gnchapter'),
    );
    final partFile = File('${finalFile.path}.part');
    final handle = await partFile.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    if (await finalFile.exists()) await finalFile.delete();
    await partFile.rename(finalFile.path);
    return finalFile.path;
  }

  Future<void> _ensureRoot() {
    return _rootDirectory.create(recursive: true);
  }

  File _validatedFile(String storedPath, {bool requireExisting = true}) {
    final root = path.normalize(path.absolute(_rootDirectory.path));
    final candidate = path.normalize(path.absolute(storedPath));
    if (candidate != root && !path.isWithin(root, candidate)) {
      throw DownloadFilePathException(storedPath);
    }
    final file = File(candidate);
    if (requireExisting && !file.existsSync()) {
      throw DownloadFileMissingException(storedPath);
    }
    return file;
  }

  static String _safeName(String chapterKey) {
    return base64Url.encode(utf8.encode(chapterKey)).replaceAll('=', '');
  }
}

String offlineChapterUri(String chapterKey) {
  return 'galaxy-download://chapter/${Uri.encodeComponent(chapterKey)}';
}

class DownloadFileReconciliation {
  const DownloadFileReconciliation({
    required this.missingPaths,
    required this.removedPartPaths,
  });

  final List<String> missingPaths;
  final List<String> removedPartPaths;
}

sealed class DownloadFileException implements Exception {
  const DownloadFileException(this.filePath);

  final String filePath;
}

class DownloadFileMissingException extends DownloadFileException {
  const DownloadFileMissingException(super.filePath);
}

class DownloadFilePathException extends DownloadFileException {
  const DownloadFilePathException(super.filePath);
}

class DownloadFileCorruptException extends DownloadFileException {
  const DownloadFileCorruptException(super.filePath, this.cause);

  final Object cause;
}
