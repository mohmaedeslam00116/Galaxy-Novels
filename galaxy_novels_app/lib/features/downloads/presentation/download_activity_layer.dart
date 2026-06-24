import 'dart:async';

import 'package:flutter/material.dart';

import '../application/download_manager.dart';
import 'download_progress_overlay.dart';

class DownloadActivityLayer extends StatelessWidget {
  const DownloadActivityLayer({
    required this.manager,
    required this.child,
    super.key,
  });

  final DownloadManager manager;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: ValueListenableBuilder<DownloadManagerState>(
            valueListenable: manager.state,
            builder: (context, state, _) {
              final progress = state.progress;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: state.isOverlayVisible && progress != null
                    ? DownloadProgressOverlay(
                        key: const ValueKey('download-progress-overlay'),
                        progress: progress,
                        status: state.status,
                        errorMessage: state.errorMessage,
                        onDismiss: manager.dismissOverlay,
                        onPause: manager.pause,
                        onResume: manager.resume,
                        onCancel: () => unawaited(manager.cancel()),
                        onRetry: () => unawaited(
                          manager.retry().catchError((Object _) {}),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        ),
      ],
    );
  }
}
