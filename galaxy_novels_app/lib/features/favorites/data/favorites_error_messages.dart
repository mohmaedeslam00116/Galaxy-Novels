import '../../../core/network/private_api_types.dart';
import '../../../core/session/session_messages.dart';

String favoritesSyncMessage(PrivateApiException error) {
  if (isSessionExpiredStatus(error.statusCode) ||
      error.code == 'wor_reader_app_login_required') {
    return sessionExpiredMessage;
  }
  return switch (error.code) {
    'network_unavailable' =>
      'أنت دون اتصال. حُفظت التغييرات وستتم مزامنتها لاحقًا.',
    'timeout' => 'تعذر تحديث المفضلة الآن. سنحاول مجددًا لاحقًا.',
    _ => 'تعذر مزامنة المفضلة الآن. بقيت تغييراتك محفوظة على الجهاز.',
  };
}
