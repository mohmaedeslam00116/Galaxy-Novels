import '../../../core/network/private_api_client.dart';
import '../../../core/session/session_messages.dart';

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

String commentSubmitMessageFor(Object error) {
  if (error is PrivateApiException) {
    if (isSessionExpiredStatus(error.statusCode)) {
      return sessionExpiredMessage;
    }
    if (error.statusCode == 404) {
      return 'لم تعد هذه التعليقات متاحة.';
    }
    if (error.statusCode == 429) {
      return 'طلبات كثيرة. حاول بعد قليل.';
    }
  }
  if (error is FormatException) {
    return 'تعذر قراءة التعليق المحفوظ.';
  }
  return 'تعذر إرسال التعليق الآن.';
}

String commentInteractionMessageFor(Object error) {
  if (error is PrivateApiException) {
    if (isSessionExpiredStatus(error.statusCode)) {
      return sessionExpiredMessage;
    }
    if (error.statusCode == 404) {
      return 'لم يعد هذا التفاعل متاحًا.';
    }
    if (error.statusCode == 429) {
      return 'طلبات كثيرة. حاول بعد قليل.';
    }
  }
  if (error is FormatException) {
    return 'تعذر قراءة بيانات التفاعل.';
  }
  return 'تعذر تنفيذ التفاعل الآن.';
}
