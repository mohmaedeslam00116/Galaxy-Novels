import '../../../core/network/private_api_client.dart';

String commentsMessageFor(Object error) {
  if (error is PrivateApiException) {
    if (error.statusCode == 404) {
      return 'لم تعد هذه التعليقات متاحة.';
    }
    if (error.statusCode == 429) {
      return 'طلبات كثيرة. حاول بعد قليل.';
    }
  }
  if (error is FormatException) {
    return 'تعذر قراءة بيانات التعليقات.';
  }
  return 'تعذر تحميل التعليقات الآن.';
}
