import '../../account/domain/auth_session.dart';

/// Central policy for ordinary ads such as banners and native placements.
/// Rewarded download ads intentionally do not use this policy.
class StandardAdVisibilityPolicy {
  const StandardAdVisibilityPolicy._();

  static bool canShow(AuthSessionState session) {
    return switch (session.status) {
      AuthSessionStatus.guest => true,
      AuthSessionStatus.authenticated ||
      AuthSessionStatus.signingOut => session.user?.vip.active != true,
      AuthSessionStatus.idle ||
      AuthSessionStatus.restoring ||
      AuthSessionStatus.authenticating ||
      AuthSessionStatus.failure => false,
    };
  }
}
