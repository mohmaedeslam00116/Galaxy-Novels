import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class DownloadKeyStore {
  Future<SecretKey> readOrCreate();
}

class SecureDownloadKeyStore implements DownloadKeyStore {
  SecureDownloadKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  static const _keyName = 'galaxy_novels_download_key_v1';
  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'galaxy_novels_downloads'),
    iOptions: IOSOptions(
      accountName: 'galaxy_novels_downloads',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;
  Future<SecretKey>? _cached;

  @override
  Future<SecretKey> readOrCreate() {
    return _cached ??= _loadOrCreate();
  }

  Future<SecretKey> _loadOrCreate() async {
    try {
      final encoded = await _storage.read(key: _keyName);
      if (encoded != null && encoded.isNotEmpty) {
        final bytes = base64Decode(encoded);
        if (bytes.length != 32) {
          throw const DownloadKeyStoreException();
        }
        return SecretKey(bytes);
      }

      final generated = await AesGcm.with256bits().newSecretKey();
      final bytes = await generated.extractBytes();
      await _storage.write(key: _keyName, value: base64Encode(bytes));
      return SecretKey(bytes);
    } on PlatformException {
      throw const DownloadKeyStoreException();
    } on FormatException {
      throw const DownloadKeyStoreException();
    }
  }
}

class DownloadKeyStoreException implements Exception {
  const DownloadKeyStoreException();
}
