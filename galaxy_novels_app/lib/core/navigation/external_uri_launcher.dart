import 'package:url_launcher/url_launcher.dart';

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

Future<bool> launchExternalUri(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
