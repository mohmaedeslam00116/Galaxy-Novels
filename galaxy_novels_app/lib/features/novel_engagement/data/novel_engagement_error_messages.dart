import '../../../core/network/private_api_client.dart';

String novelEngagementMessageFor(PrivateApiException error) {
  if (error.statusCode == 401 || error.statusCode == 403) {
    return 'انتهت الجلسة. سجّل الدخول وحاول مجددًا.';
  }
  if (error.statusCode == 429) {
    return 'محاولات كثيرة. حاول لاحقًا.';
  }
  if ((error.statusCode ?? 0) >= 500) {
    return 'الخدمة غير متاحة الآن. حاول مجددًا.';
  }
  return switch (error.code) {
    'network_unavailable' => 'تعذر الاتصال الآن. حاول مجددًا.',
    'timeout' => 'استغرق الاتصال وقتًا طويلًا. حاول مجددًا.',
    'secure_connection_failed' => 'تعذر إنشاء اتصال آمن بالموقع.',
    _ => 'تعذر تحديث حالتك مع الرواية. حاول مجددًا.',
  };
}
