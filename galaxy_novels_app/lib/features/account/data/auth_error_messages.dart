import '../../../core/network/private_api_client.dart';

String restoreMessageFor(PrivateApiException error) {
  return switch (error.code) {
    'network_unavailable' =>
      'لا يوجد اتصال بالموقع الآن. تحقق من الشبكة وحاول مجددًا.',
    'timeout' => 'استغرق الاتصال وقتًا أطول من المتوقع. حاول مجددًا.',
    _ => 'تعذر التحقق من الجلسة الآن. حاول مجددًا.',
  };
}

String loginMessageFor(PrivateApiException error) {
  if (error.statusCode == 401) {
    return 'اسم المستخدم أو كلمة المرور غير صحيحة.';
  }
  if (error.statusCode == 429) {
    return 'محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.';
  }
  return switch (error.code) {
    'network_unavailable' => 'تعذر الاتصال بالموقع. تحقق من الشبكة.',
    'timeout' => 'استغرق تسجيل الدخول وقتًا أطول من المتوقع.',
    _ => 'تعذر تسجيل الدخول الآن. حاول مجددًا.',
  };
}

String logoutMessageFor(PrivateApiException error) {
  return switch (error.code) {
    'network_unavailable' => 'تعذر تسجيل الخروج بسبب انقطاع الاتصال.',
    'timeout' => 'استغرق تسجيل الخروج وقتًا أطول من المتوقع.',
    _ => 'تعذر تسجيل الخروج الآن. حاول مجددًا.',
  };
}
