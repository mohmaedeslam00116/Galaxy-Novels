const sessionExpiredMessage = 'انتهت الجلسة، سجل الدخول مرة أخرى للمتابعة.';

bool isSessionExpiredStatus(int? statusCode) {
  return statusCode == 401 || statusCode == 403;
}
