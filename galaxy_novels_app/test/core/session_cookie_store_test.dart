import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/network/session_cookie_store.dart';

void main() {
  test('sends secure cookies only to matching HTTPS paths', () {
    final store = InMemorySessionCookieStore();
    store.absorb(Uri.parse('https://example.com/wp-json/session'), const [
      'session=token; Path=/wp-json; Secure; HttpOnly',
    ]);

    expect(
      store.headerFor(Uri.parse('https://example.com/wp-json/me')),
      'session=token',
    );
    expect(store.headerFor(Uri.parse('http://example.com/wp-json/me')), isNull);
    expect(
      store.headerFor(Uri.parse('https://example.com/wp-json-copy/me')),
      isNull,
    );
  });

  test('removes cookies when the server expires them', () {
    final store = InMemorySessionCookieStore();
    final origin = Uri.parse('https://example.com/session');
    store.absorb(origin, const ['session=token; Path=/; Secure']);
    store.absorb(origin, const ['session=deleted; Path=/; Max-Age=0; Secure']);

    expect(store.headerFor(Uri.parse('https://example.com/me')), isNull);
  });

  test('ignores malformed cookie headers', () {
    final store = InMemorySessionCookieStore();
    store.absorb(Uri.parse('https://example.com/session'), const [
      '=missing-name',
    ]);

    expect(store.headerFor(Uri.parse('https://example.com/me')), isNull);
  });
}
