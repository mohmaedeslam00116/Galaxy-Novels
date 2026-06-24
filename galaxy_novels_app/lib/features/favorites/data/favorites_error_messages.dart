import '../../../core/network/private_api_types.dart';

String favoritesSyncMessage(PrivateApiException error) {
  return switch (error.code) {
    'network_unavailable' =>
      'أنت دون اتصال. حُفظت التغييرات وستتم مزامنتها لاحقًا.',
    'timeout' => 'تعذر تحديث المفضلة الآن. سنحاول مجددًا لاحقًا.',
    'wor_reader_app_login_required' =>
      'انتهت جلسة الحساب. سجّل الدخول مرة أخرى.',
    _ => 'تعذر مزامنة المفضلة الآن. بقيت تغييراتك محفوظة على الجهاز.',
  };
}
