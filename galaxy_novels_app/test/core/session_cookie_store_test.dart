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

  test('restores a persisted request cookie header for HTTPS only', () {
    final store = InMemorySessionCookieStore();
    final origin = Uri.parse('https://example.com/wp-json/session');

    store.restoreRequestHeader(origin, 'session=one; preference=two');

    expect(
      store.headerFor(Uri.parse('https://example.com/wp-json/me')),
      allOf(contains('session=one'), contains('preference=two')),
    );
    expect(store.headerFor(Uri.parse('http://example.com/wp-json/me')), isNull);
  });

  test('rejects persisted cookie headers containing line breaks', () {
    final store = InMemorySessionCookieStore();
    store.restoreRequestHeader(
      Uri.parse('https://example.com/session'),
      'session=one\r\nInjected: value',
    );

    expect(store.headerFor(Uri.parse('https://example.com/me')), isNull);
  });
}
