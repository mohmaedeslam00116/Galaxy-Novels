import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/core/network/private_api_client.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/novel_engagement/application/novel_engagement_controller.dart';
import 'package:galaxy_novels_app/features/novel_engagement/domain/novel_user_state.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_novel_engagement_repository.dart';

void main() {
  test('guest state never calls the private repository', () async {
    final auth = FakeAuthRepository();
    final repository = FakeNovelEngagementRepository(state: _state(123));
    final controller = NovelEngagementController(
      repository: repository,
      authRepository: auth,
    );
    addTearDown(controller.dispose);

    await controller.loadNovel(123);

    expect(controller.value.status, NovelEngagementStatus.guest);
    expect(repository.loadedNovelIds, isEmpty);
  });

  test('authenticated load publishes the matching novel state', () async {
    final auth = FakeAuthRepository(
      initialState: AuthSessionState.authenticated(_user(7)),
    );
    final repository = FakeNovelEngagementRepository(
      state: _state(123, rating: 4),
    );
    final controller = NovelEngagementController(
      repository: repository,
      authRepository: auth,
    );
    addTearDown(controller.dispose);

    await controller.loadNovel(123);

    expect(controller.value.status, NovelEngagementStatus.ready);
    expect(controller.value.userId, 7);
    expect(controller.value.data?.myRating, 4);
    expect(repository.loadedNovelIds, [123]);
  });

  test('logout clears personal state immediately', () async {
    final auth = FakeAuthRepository(
      initialState: AuthSessionState.authenticated(_user(7)),
    );
    final controller = NovelEngagementController(
      repository: FakeNovelEngagementRepository(state: _state(123, rating: 4)),
      authRepository: auth,
    );
    addTearDown(controller.dispose);
    await controller.loadNovel(123);

    auth.value = const AuthSessionState.guest();
    await Future<void>.delayed(Duration.zero);

    expect(controller.value.status, NovelEngagementStatus.guest);
    expect(controller.value.data, isNull);
  });

  test('late response cannot overwrite a different account', () async {
    final first = Completer<NovelUserState>();
    final second = Completer<NovelUserState>();
    var call = 0;
    final auth = FakeAuthRepository(
      initialState: AuthSessionState.authenticated(_user(7)),
    );
    final repository = FakeNovelEngagementRepository(
      loadHandler: (_) => call++ == 0 ? first.future : second.future,
    );
    final controller = NovelEngagementController(
      repository: repository,
      authRepository: auth,
    );
    addTearDown(controller.dispose);
    final oldLoad = controller.loadNovel(123);

    auth.value = AuthSessionState.authenticated(_user(8));
    await Future<void>.delayed(Duration.zero);
    expect(repository.loadedNovelIds, [123, 123]);

    second.complete(_state(123, rating: 5));
    await Future<void>.delayed(Duration.zero);
    first.complete(_state(123, rating: 1));
    await oldLoad;

    expect(controller.value.userId, 8);
    expect(controller.value.data?.myRating, 5);
  });

  test('successful submit publishes only the server rating', () async {
    final auth = FakeAuthRepository(
      initialState: AuthSessionState.authenticated(_user(7)),
    );
    final repository = FakeNovelEngagementRepository(
      state: _state(123, rating: 2),
      submitHandler: (_, _) async => 5,
    );
    final controller = NovelEngagementController(
      repository: repository,
      authRepository: auth,
    );
    addTearDown(controller.dispose);
    await controller.loadNovel(123);

    final outcome = await controller.submitRating(4);

    expect(outcome.status, RatingSubmitStatus.saved);
    expect(repository.submittedRatings, [(123, 4)]);
    expect(controller.value.data?.myRating, 5);
  });

  test(
    'a second rating submit is rejected while the first is active',
    () async {
      final completion = Completer<int>();
      final auth = FakeAuthRepository(
        initialState: AuthSessionState.authenticated(_user(7)),
      );
      final repository = FakeNovelEngagementRepository(
        state: _state(123, rating: 2),
        submitHandler: (_, _) => completion.future,
      );
      final controller = NovelEngagementController(
        repository: repository,
        authRepository: auth,
      );
      addTearDown(controller.dispose);
      await controller.loadNovel(123);

      final first = controller.submitRating(4);
      final second = await controller.submitRating(5);

      expect(second.status, RatingSubmitStatus.busy);
      expect(repository.submittedRatings, [(123, 4)]);
      completion.complete(4);
      await first;
    },
  );

  test(
    'rate limit keeps the previous rating and exposes an Arabic message',
    () async {
      final auth = FakeAuthRepository(
        initialState: AuthSessionState.authenticated(_user(7)),
      );
      final repository = FakeNovelEngagementRepository(
        state: _state(123, rating: 2),
        submitHandler: (_, _) => Future.error(
          const PrivateApiException(statusCode: 429, message: 'rate limited'),
        ),
      );
      final controller = NovelEngagementController(
        repository: repository,
        authRepository: auth,
      );
      addTearDown(controller.dispose);
      await controller.loadNovel(123);

      final outcome = await controller.submitRating(4);

      expect(outcome.status, RatingSubmitStatus.failed);
      expect(outcome.errorMessage, 'محاولات كثيرة. حاول لاحقًا.');
      expect(controller.value.data?.myRating, 2);
      expect(controller.value.isSubmitting, isFalse);
    },
  );

  test('unauthorized submit asks auth repository to restore session', () async {
    final auth = _TrackingAuthRepository(
      AuthSessionState.authenticated(_user(7)),
    );
    final repository = FakeNovelEngagementRepository(
      state: _state(123),
      submitHandler: (_, _) => Future.error(
        const PrivateApiException(statusCode: 401, message: 'expired'),
      ),
    );
    final controller = NovelEngagementController(
      repository: repository,
      authRepository: auth,
    );
    addTearDown(controller.dispose);
    await controller.loadNovel(123);

    final outcome = await controller.submitRating(3);

    expect(outcome.status, RatingSubmitStatus.failed);
    expect(auth.restoreCalls, 1);
  });
}

AuthUser _user(int id) {
  return AuthUser(
    id: id,
    displayName: 'قارئ $id',
    avatar: null,
    vip: const AuthVip(active: false, tier: '', label: '', expiresAt: null),
    xp: const AuthXp(
      total: 0,
      today: 0,
      secondsTotal: 0,
      chaptersTotal: 0,
      rank: AuthRank(level: 1, display: ''),
    ),
  );
}

NovelUserState _state(int novelId, {int rating = 0}) {
  return NovelUserState(
    novelId: novelId,
    favorite: false,
    myRating: rating,
    lastRead: const NovelLastRead(
      chapterId: 0,
      chapterUrl: '',
      progress: 0,
      updatedAt: null,
    ),
    vip: const NovelVipAccess(active: false, canReadPrivate: false),
  );
}

class _TrackingAuthRepository extends FakeAuthRepository {
  _TrackingAuthRepository(AuthSessionState state) : super(initialState: state);

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls++;
    await super.restoreSession();
  }
}
