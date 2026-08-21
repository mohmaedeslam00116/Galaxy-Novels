import 'package:in_app_review/in_app_review.dart';

import '../application/play_app_review_gateway.dart';

class InAppReviewGateway implements PlayAppReviewGateway {
  InAppReviewGateway({InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final InAppReview _review;

  @override
  Future<bool> isAvailable() => _review.isAvailable();

  @override
  Future<void> requestReview() => _review.requestReview();

  @override
  Future<void> openStoreListing() => _review.openStoreListing();
}
