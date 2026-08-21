abstract interface class PlayAppReviewGateway {
  Future<bool> isAvailable();

  Future<void> requestReview();

  Future<void> openStoreListing();
}

class NoopPlayAppReviewGateway implements PlayAppReviewGateway {
  const NoopPlayAppReviewGateway();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> requestReview() async {}

  @override
  Future<void> openStoreListing() async {
    throw UnsupportedError('Google Play review is disabled in this build.');
  }
}
