import 'package:flutter/material.dart';

class ChapterDownloadButton extends StatefulWidget {
  const ChapterDownloadButton({
    required this.isDownloaded,
    required this.isEnabled,
    required this.onPressed,
    super.key,
  });

  final bool isDownloaded;
  final bool isEnabled;
  final Future<void> Function() onPressed;

  @override
  State<ChapterDownloadButton> createState() => _ChapterDownloadButtonState();
}

class _ChapterDownloadButtonState extends State<ChapterDownloadButton> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    if (_isDownloading) {
      return const SizedBox.square(
        dimension: 44,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isEnabled = widget.isEnabled && !widget.isDownloaded;
    return IconButton(
      tooltip: widget.isDownloaded
          ? 'محمل'
          : widget.isEnabled
          ? 'تحميل الفصل'
          : 'غير متاح للتحميل',
      onPressed: isEnabled ? _download : null,
      icon: Icon(
        widget.isDownloaded
            ? Icons.download_done_rounded
            : widget.isEnabled
            ? Icons.download_outlined
            : Icons.block_outlined,
      ),
    );
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}
