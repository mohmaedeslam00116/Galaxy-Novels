import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_review/domain/app_review_policy.dart';

void main() {
  test('default policy matches the production eligibility contract', () {
    expect(AppReviewPolicy.defaults.enabled, isTrue);
    expect(AppReviewPolicy.defaults.minimumDays, 3);
    expect(AppReviewPolicy.defaults.minimumCompletedChapters, 10);
    expect(AppReviewPolicy.defaults.minimumSessions, 2);
    expect(AppReviewPolicy.defaults.cooldownDays, 120);
    expect(AppReviewPolicy.defaults.maximumAttempts, 3);
  });

  test('valid policy round-trips through remote config values', () {
    final policy = AppReviewPolicy.defaults.copyWith(
      minimumDays: 5,
      minimumCompletedChapters: 14,
    );

    expect(AppReviewPolicy.tryFromMap(policy.toJson()), policy);
  });

  test('invalid remote values are rejected as a whole', () {
    expect(
      AppReviewPolicy.tryFromMap({
        ...AppReviewPolicy.defaults.toJson(),
        AppReviewPolicy.cooldownDaysKey: 0,
      }),
      isNull,
    );
    expect(
      AppReviewPolicy.tryFromMap({
        ...AppReviewPolicy.defaults.toJson(),
        AppReviewPolicy.maximumAttemptsKey: 0,
      }),
      isNull,
    );
  });
}
