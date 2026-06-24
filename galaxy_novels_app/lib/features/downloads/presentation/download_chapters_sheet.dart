import 'package:flutter/material.dart';

import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/downloads_repository.dart';

class DownloadChaptersSheet extends StatefulWidget {
  const DownloadChaptersSheet({
    required this.details,
    required this.chapters,
    required this.downloadsState,
    required this.onStart,
    super.key,
  });

  final NovelDetails details;
  final List<NovelChapter> chapters;
  final DownloadsState downloadsState;
  final ValueChanged<List<NovelChapter>> onStart;

  @override
  State<DownloadChaptersSheet> createState() => _DownloadChaptersSheetState();
}

class _DownloadChaptersSheetState extends State<DownloadChaptersSheet> {
  final Set<String> _selectedApis = {};

  List<NovelChapter> get _availableChapters {
    return widget.chapters
        .where((chapter) {
          final contentApi = chapter.effectiveContentApi;
          return contentApi.isNotEmpty &&
              !widget.downloadsState.contains(contentApi);
        })
        .toList(growable: false);
  }

  List<NovelChapter> get _selectedChapters {
    return widget.chapters
        .where((chapter) => _selectedApis.contains(chapter.effectiveContentApi))
        .toList(growable: false);
  }

  bool get _exceedsLimit {
    return _selectedApis.length > widget.downloadsState.remainingSlots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selectedCount = _selectedApis.length;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحميل الفصول',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.details.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.storage_outlined, color: colors.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${widget.downloadsState.downloadedCount} / '
                        '${widget.downloadsState.maxChapters} فصل محمل',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '$selectedCount محدد',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _exceedsLimit ? colors.error : colors.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _selectLatestTen,
                  child: const Text('آخر 10 فصول'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _selectAvailable,
                  child: const Text('غير المحمل'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _selectedApis.isEmpty ? null : _clearSelection,
                  child: const Text('إلغاء التحديد'),
                ),
              ],
            ),
          ),
          if (_exceedsLimit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'لا يمكنك تحميل هذا العدد الآن. المتبقي لديك '
                '${widget.downloadsState.remainingSlots} فصل.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: widget.chapters.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chapter = widget.chapters[index];
                final contentApi = chapter.effectiveContentApi;
                final isDownloaded = widget.downloadsState.contains(contentApi);
                final isEnabled = contentApi.isNotEmpty && !isDownloaded;
                final selected = _selectedApis.contains(contentApi);

                return CheckboxListTile(
                  key: ValueKey('download-chapter-${chapter.id}'),
                  value: isDownloaded || selected,
                  onChanged: isEnabled
                      ? (_) => _toggleChapter(contentApi)
                      : null,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    chapter.label.isNotEmpty ? chapter.label : 'فصل',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: chapter.displayTitle.isEmpty
                      ? null
                      : Text(
                          chapter.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  secondary: isDownloaded
                      ? Icon(Icons.download_done, color: colors.secondary)
                      : null,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: FilledButton.icon(
                onPressed: selectedCount == 0 || _exceedsLimit
                    ? null
                    : _startDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text('تحميل $selectedCount فصل'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleChapter(String contentApi) {
    setState(() {
      if (!_selectedApis.add(contentApi)) {
        _selectedApis.remove(contentApi);
      }
    });
  }

  void _selectLatestTen() {
    final selection = _availableChapters
        .take(10)
        .map((chapter) => chapter.effectiveContentApi);
    setState(() {
      _selectedApis
        ..clear()
        ..addAll(selection);
    });
  }

  void _selectAvailable() {
    final selection = _availableChapters
        .take(widget.downloadsState.remainingSlots)
        .map((chapter) => chapter.effectiveContentApi);
    setState(() {
      _selectedApis
        ..clear()
        ..addAll(selection);
    });
  }

  void _clearSelection() {
    setState(_selectedApis.clear);
  }

  void _startDownload() {
    widget.onStart(_selectedChapters);
    Navigator.of(context).pop();
  }
}
