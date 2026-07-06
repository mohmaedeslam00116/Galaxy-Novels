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

String registerMessageFor(PrivateApiException error) {
  final code = error.code?.toLowerCase() ?? '';
  if (code.contains('turnstile') || code.contains('captcha')) {
    return 'يتطلب إنشاء الحساب تحقق حماية غير متاح داخل التطبيق حاليا.';
  }
  if (error.statusCode == 404 && code == 'rest_no_route') {
    return 'إنشاء الحساب غير مفعّل في نسخة الموقع الحالية.';
  }
  if (error.statusCode == 409) {
    return 'اسم المستخدم أو البريد الإلكتروني مستخدم بالفعل.';
  }
  if (error.statusCode == 429) {
    return 'محاولات كثيرة. انتظر قليلًا ثم حاول مجددًا.';
  }
  return switch (error.code) {
    'network_unavailable' => 'تعذر الاتصال بالموقع. تحقق من الشبكة.',
    'timeout' => 'استغرق إنشاء الحساب وقتًا أطول من المتوقع.',
    _ => 'تعذر إنشاء الحساب الآن. حاول مجددًا.',
  };
}

String logoutMessageFor(PrivateApiException error) {
  return switch (error.code) {
    'network_unavailable' => 'تعذر تسجيل الخروج بسبب انقطاع الاتصال.',
    'timeout' => 'استغرق تسجيل الخروج وقتًا أطول من المتوقع.',
    _ => 'تعذر تسجيل الخروج الآن. حاول مجددًا.',
  };
}
