import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/data/repositories/reading_history_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/home/application/home_recommendation_exclusion_repository.dart';
import 'package:galaxy_novels_app/features/home/data/stored_home_recommendation_exclusion_repository.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  test('keeps guest and authenticated exclusions separate', () async {
    final auth = FakeAuthRepository();
    final store = _MemoryExclusionStore();
    final repository = StoredHomeRecommendationExclusionRepository(
      store: store,
      authRepository: auth,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);

    await repository.hide(11);
    expect(await repository.load(), {11});

    auth.value = const AuthSessionState.authenticated(_user);
    expect(await repository.load(), isEmpty);
    await repository.hide(22);
    expect(await repository.load(), {22});

    auth.value = const AuthSessionState.guest();
    expect(await repository.load(), {11});
  });

  test('serializes concurrent hides and supports restore and clear', () async {
    final auth = FakeAuthRepository();
    final repository = StoredHomeRecommendationExclusionRepository(
      store: _MemoryExclusionStore(),
      authRepository: auth,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);

    await Future.wait([repository.hide(1), repository.hide(2)]);
    expect(await repository.load(), {1, 2});

    await repository.restore(1);
    expect(await repository.load(), {2});

    await repository.clear();
    expect(await repository.load(), isEmpty);
  });

  test('treats malformed stored data as an empty exclusion set', () async {
    final auth = FakeAuthRepository();
    final store = _MemoryExclusionStore()
      ..values[ReadingHistoryScope.guest] = 'not-json';
    final repository = StoredHomeRecommendationExclusionRepository(
      store: store,
      authRepository: auth,
    );
    addTearDown(repository.dispose);
    addTearDown(auth.dispose);

    expect(await repository.load(), isEmpty);
  });
}

class _MemoryExclusionStore implements HomeRecommendationExclusionStore {
  final values = <ReadingHistoryScope, String>{};

  @override
  Future<String?> read(ReadingHistoryScope scope) async => values[scope];

  @override
  Future<void> write(ReadingHistoryScope scope, String value) async {
    values[scope] = value;
  }
}

const _user = AuthUser(
  id: 7,
  displayName: 'قارئ',
  avatar: null,
  vip: AuthVip(active: false, tier: '', label: '', expiresAt: null),
  xp: AuthXp(
    total: 0,
    today: 0,
    secondsTotal: 0,
    chaptersTotal: 0,
    rank: AuthRank(level: 0, display: ''),
  ),
);
