import '../domain/download_models.dart';

enum DownloadTransferKind { chapter, cover }

class DownloadTransferRequest {
  const DownloadTransferRequest({
    required this.transferId,
    required this.kind,
    required this.url,
    required this.headers,
    required this.fileName,
    required this.requiresWifi,
  });

  final String transferId;
  final DownloadTransferKind kind;
  final Uri url;
  final Map<String, String> headers;
  final String fileName;
  final bool requiresWifi;
}

sealed class DownloadTransferUpdate {
  const DownloadTransferUpdate(this.transferId);

  final String transferId;
}

final class DownloadTransferProgress extends DownloadTransferUpdate {
  const DownloadTransferProgress(super.transferId, this.value);

  final double value;
}

final class DownloadTransferFinished extends DownloadTransferUpdate {
  const DownloadTransferFinished(
    super.transferId, {
    required this.localPath,
    required this.statusCode,
    required this.mimeType,
  });

  final String localPath;
  final int statusCode;
  final String? mimeType;
}

final class DownloadTransferPaused extends DownloadTransferUpdate {
  const DownloadTransferPaused(super.transferId);
}

final class DownloadTransferFailed extends DownloadTransferUpdate {
  const DownloadTransferFailed(super.transferId, this.failure);

  final DownloadFailure failure;
}

abstract interface class DownloadTransfer {
  Stream<DownloadTransferUpdate> get updates;
  Future<void> initialize();
  Future<bool> enqueue(DownloadTransferRequest request);
  Future<bool> pause(String transferId);
  Future<bool> resume(String transferId);
  Future<bool> cancel(String transferId);
  void dispose();
}
