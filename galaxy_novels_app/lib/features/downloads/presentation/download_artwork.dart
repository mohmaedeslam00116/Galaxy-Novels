import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/config/app_config.dart';
import '../domain/download_models.dart';

ImageProvider<Object>? downloadedNovelArtwork(
  BuildContext context,
  DownloadedNovel novel,
) {
  final localPath = novel.coverPath.trim();
  if (localPath.isNotEmpty) {
    final file = File(localPath);
    if (file.existsSync()) return FileImage(file);
  }

  final coverUrl = novel.coverUrl.trim();
  if (coverUrl.isEmpty) return null;
  try {
    final dependencies = AppDependencies.maybeOf(context);
    final uri = dependencies == null
        ? Uri.tryParse(coverUrl)
        : dependencies.config.resolve(coverUrl);
    if (uri == null || !uri.hasScheme) return null;
    return NetworkImage(uri.toString());
  } on AppConfigException {
    return null;
  } on FormatException {
    return null;
  }
}
