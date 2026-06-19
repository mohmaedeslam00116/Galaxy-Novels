import '../../../core/config/app_config.dart';

Uri buildPublicReaderUri({
  required AppConfig config,
  required String chapterUrl,
}) {
  final resolved = config.resolve(chapterUrl);
  final queryParameters = Map<String, String>.from(resolved.queryParameters);
  queryParameters['wr_app_reader'] = '1';
  return resolved.replace(queryParameters: queryParameters);
}
