import 'dart:io';

abstract interface class SessionCookieStore {
  String? headerFor(Uri uri);

  void absorb(Uri origin, Iterable<String> setCookieHeaders);

  void clear();
}

class InMemorySessionCookieStore implements SessionCookieStore {
  final Map<_CookieKey, _StoredCookie> _cookies = {};

  @override
  String? headerFor(Uri uri) {
    _removeExpired();
    final values = _cookies.values
        .where((stored) => stored.matches(uri))
        .map((stored) => '${stored.cookie.name}=${stored.cookie.value}')
        .toList(growable: false);

    return values.isEmpty ? null : values.join('; ');
  }

  @override
  void absorb(Uri origin, Iterable<String> setCookieHeaders) {
    for (final header in setCookieHeaders) {
      final cookie = _tryParseCookie(header);
      if (cookie == null || cookie.name.isEmpty) {
        continue;
      }

      final domain = _normalizedDomain(cookie.domain, origin.host);
      final path = cookie.path?.isNotEmpty == true
          ? cookie.path!
          : _defaultPath(origin.path);
      final key = _CookieKey(cookie.name, domain, path);

      if (_isExpired(cookie)) {
        _cookies.remove(key);
        continue;
      }

      _cookies[key] = _StoredCookie(
        cookie: cookie,
        domain: domain,
        path: path,
        expiresAt: _expirationFor(cookie),
      );
    }
  }

  @override
  void clear() => _cookies.clear();

  void _removeExpired() {
    _cookies.removeWhere((_, stored) => stored.isExpired);
  }
}

Cookie? _tryParseCookie(String value) {
  try {
    return Cookie.fromSetCookieValue(value);
  } on FormatException {
    return null;
  } on HttpException {
    return null;
  }
}

bool _isExpired(Cookie cookie) {
  if (cookie.maxAge != null && cookie.maxAge! <= 0) {
    return true;
  }

  final expires = cookie.expires;
  return expires != null && !expires.isAfter(DateTime.now().toUtc());
}

DateTime? _expirationFor(Cookie cookie) {
  final maxAge = cookie.maxAge;
  if (maxAge != null) {
    return DateTime.now().toUtc().add(Duration(seconds: maxAge));
  }
  return cookie.expires?.toUtc();
}

String _normalizedDomain(String? domain, String fallback) {
  final value = domain?.trim().toLowerCase() ?? '';
  return value.startsWith('.')
      ? value.substring(1)
      : (value.isEmpty ? fallback : value);
}

String _defaultPath(String requestPath) {
  if (!requestPath.startsWith('/') || requestPath == '/') {
    return '/';
  }

  final lastSlash = requestPath.lastIndexOf('/');
  return lastSlash <= 0 ? '/' : requestPath.substring(0, lastSlash);
}

class _StoredCookie {
  const _StoredCookie({
    required this.cookie,
    required this.domain,
    required this.path,
    required this.expiresAt,
  });

  final Cookie cookie;
  final String domain;
  final String path;
  final DateTime? expiresAt;

  bool get isExpired {
    final expiration = expiresAt;
    return expiration != null && !expiration.isAfter(DateTime.now().toUtc());
  }

  bool matches(Uri uri) {
    final host = uri.host.toLowerCase();
    final domainMatches = host == domain || host.endsWith('.$domain');
    final pathMatches =
        uri.path == path ||
        uri.path.startsWith(path.endsWith('/') ? path : '$path/');
    final secureMatches = !cookie.secure || uri.scheme == 'https';
    return !isExpired && domainMatches && pathMatches && secureMatches;
  }
}

class _CookieKey {
  const _CookieKey(this.name, this.domain, this.path);

  final String name;
  final String domain;
  final String path;

  @override
  bool operator ==(Object other) {
    return other is _CookieKey &&
        name == other.name &&
        domain == other.domain &&
        path == other.path;
  }

  @override
  int get hashCode => Object.hash(name, domain, path);
}
