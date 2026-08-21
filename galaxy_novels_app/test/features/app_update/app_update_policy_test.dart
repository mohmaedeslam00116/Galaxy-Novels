import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/app_update/domain/app_update_policy.dart';

void main() {
  test('valid policy round-trips and blocks only builds below the minimum', () {
    final policy = AppUpdatePolicy(
      systemEnabled: true,
      optionalUpdateEnabled: true,
      minimumSupportedBuild: 4,
      optionalTitle: 'تحديث جديد متاح',
      optionalMessage: 'يتوفر إصدار أحدث من التطبيق.',
      requiredTitle: 'يلزم تحديث التطبيق',
      requiredMessage: 'هذا الإصدار لم يعد مدعومًا.',
    );

    final restored = AppUpdatePolicy.tryFromMap(policy.toJson());

    expect(restored, policy);
    expect(policy.requiresUpdate(3), isTrue);
    expect(policy.requiresUpdate(4), isFalse);
    expect(policy.requiresUpdate(5), isFalse);
    expect(policy.requiresUpdate(null), isFalse);
  });

  test('malformed policy is rejected instead of replacing trusted values', () {
    expect(
      AppUpdatePolicy.tryFromMap({
        ...AppUpdatePolicy.defaults.toJson(),
        AppUpdatePolicy.minimumSupportedBuildKey: -1,
      }),
      isNull,
    );
    expect(
      AppUpdatePolicy.tryFromMap({
        ...AppUpdatePolicy.defaults.toJson(),
        AppUpdatePolicy.requiredMessageKey: '   ',
      }),
      isNull,
    );
  });
}
