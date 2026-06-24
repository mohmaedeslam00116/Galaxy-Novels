import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/network/private_api_client.dart';
import '../application/auth_session_store.dart';

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

  static const _key = 'galaxy_novels_private_session_v1';
  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(storageNamespace: 'galaxy_novels_auth'),
    iOptions: IOSOptions(
      accountName: 'galaxy_novels_auth',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final FlutterSecureStorage _storage;

  @override
  Future<PrivateSessionSnapshot?> read() async {
    final encoded = await _readEncoded();
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> || json['version'] != 1) {
        throw const FormatException('Unsupported session payload.');
      }
      final nonce = _requiredString(json['nonce']);
      final cookieHeader = _requiredString(json['cookie_header']);
      return PrivateSessionSnapshot(nonce: nonce, cookieHeader: cookieHeader);
    } on FormatException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(PrivateSessionSnapshot session) async {
    final encoded = jsonEncode({
      'version': 1,
      'nonce': session.nonce,
      'cookie_header': session.cookieHeader,
    });
    try {
      await _storage.write(key: _key, value: encoded);
    } on PlatformException {
      throw const AuthSessionStoreException();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on PlatformException {
      throw const AuthSessionStoreException();
    }
  }

  Future<String?> _readEncoded() async {
    try {
      return await _storage.read(key: _key);
    } on PlatformException {
      throw const AuthSessionStoreException();
    }
  }
}

String _requiredString(Object? storedValue) {
  final text = storedValue?.toString().trim() ?? '';
  if (text.isEmpty) {
    throw const FormatException('Missing session value.');
  }
  return text;
}
