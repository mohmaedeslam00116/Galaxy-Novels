import 'package:flutter/material.dart';

import '../../../data/models/novel_details_data.dart';
import '../../../data/repositories/downloads_repository.dart';
import '../../rewards/application/reader_rewards_repository.dart';

class DownloadChaptersSheet extends StatefulWidget {
  const DownloadChaptersSheet({
    required this.details,
    required this.chapters,
    required this.downloadsState,
    required this.onStart,
    this.rewardsState,
    super.key,
  });

  final NovelDetails details;
  final List<NovelChapter> chapters;
  final DownloadsState downloadsState;
  final ReaderRewardsState? rewardsState;
  final ValueChanged<List<NovelChapter>> onStart;

  @override
  State<DownloadChaptersSheet> createState() => _DownloadChaptersSheetState();
}

class _DownloadChaptersSheetState extends State<DownloadChaptersSheet> {
  final Set<String> _selectedApis = {};
  final TextEditingController _rangeFromController = TextEditingController();
  final TextEditingController _rangeToController = TextEditingController();
  String? _rangeMessage;
  bool _rangeMessageIsError = false;

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

  bool get _exceedsPoints {
    final rewardsState = widget.rewardsState;
    return rewardsState != null && _selectedApis.length > rewardsState.points;
  }

  int get _safeDownloadCount {
    final rewardsState = widget.rewardsState;
    final limit = _min(
      _availableChapters.length,
      widget.downloadsState.remainingSlots,
    );
    return rewardsState == null ? limit : _min(limit, rewardsState.points);
  }

  @override
  void dispose() {
    _rangeFromController.dispose();
    _rangeToController.dispose();
    super.dispose();
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
                child: Column(
                  children: [
                    Row(
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$selectedCount محدد',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _exceedsLimit || _exceedsPoints
                                    ? colors.error
                                    : colors.secondary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (widget.rewardsState != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'التكلفة: $selectedCount نقطة',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    if (widget.rewardsState != null) ...[
                      const SizedBox(height: 10),
                      Divider(height: 1, color: colors.outlineVariant),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.stars_rounded,
                            color: colors.tertiary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'رصيدك: ${widget.rewardsState!.points} نقطة',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            'يمكنك تحميل $_safeDownloadCount فصل الآن',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  onPressed: _selectLatestFifty,
                  child: const Text('آخر 50 فصل'),
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
          const SizedBox(height: 10),
          _RangeSelector(
            fromController: _rangeFromController,
            toController: _rangeToController,
            message: _rangeMessage,
            messageIsError: _rangeMessageIsError,
            onApply: _selectRange,
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
          if (_exceedsPoints)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'رصيدك لا يكفي. تحتاج $selectedCount نقطة ولديك '
                '${widget.rewardsState!.points}.',
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
                onPressed: selectedCount == 0 || _exceedsLimit || _exceedsPoints
                    ? null
                    : _startDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  widget.rewardsState == null
                      ? 'تحميل $selectedCount فصل'
                      : 'تحميل $selectedCount فصل • $selectedCount نقطة',
                ),
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
    _selectLatest(10);
  }

  void _selectLatestFifty() {
    _selectLatest(50);
  }

  void _selectLatest(int count) {
    final available = _availableChapters.toList(growable: false)
      ..sort(
        (first, second) =>
            _chapterSortValue(first).compareTo(_chapterSortValue(second)),
      );
    final start = available.length > count ? available.length - count : 0;
    final selection = available
        .sublist(start)
        .map((chapter) => chapter.effectiveContentApi);
    setState(() {
      _selectedApis
        ..clear()
        ..addAll(selection);
    });
  }

  void _selectAvailable() {
    final rewardsState = widget.rewardsState;
    final maxSelection = rewardsState == null
        ? widget.downloadsState.remainingSlots
        : _min(widget.downloadsState.remainingSlots, rewardsState.points);
    final selection = _availableChapters
        .take(maxSelection)
        .map((chapter) => chapter.effectiveContentApi);
    setState(() {
      _selectedApis
        ..clear()
        ..addAll(selection);
    });
  }

  void _selectRange() {
    final from = _parseChapterNumber(_rangeFromController.text);
    final to = _parseChapterNumber(_rangeToController.text);
    if (from == null || to == null) {
      setState(() {
        _rangeMessage = 'اكتب رقم البداية والنهاية';
        _rangeMessageIsError = true;
      });
      return;
    }

    final start = _min(from, to);
    final end = _max(from, to);
    final chapters =
        _availableChapters
            .where((chapter) {
              final number = _visibleChapterNumber(chapter);
              return number != null && number >= start && number <= end;
            })
            .toList(growable: false)
          ..sort(
            (first, second) =>
                _chapterSortValue(first).compareTo(_chapterSortValue(second)),
          );

    if (chapters.isEmpty) {
      setState(() {
        _selectedApis.clear();
        _rangeMessage = 'لا توجد فصول متاحة من الفصل $start إلى الفصل $end';
        _rangeMessageIsError = true;
      });
      return;
    }

    setState(() {
      _selectedApis
        ..clear()
        ..addAll(chapters.map((chapter) => chapter.effectiveContentApi));
      _rangeMessage =
          'تم تحديد ${chapters.length} فصل من الفصل $start إلى الفصل $end';
      _rangeMessageIsError = false;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedApis.clear();
      _rangeMessage = null;
    });
  }

  void _startDownload() {
    widget.onStart(_selectedChapters);
    Navigator.of(context).pop();
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.fromController,
    required this.toController,
    required this.onApply,
    this.message,
    this.messageIsError = false,
  });

  final TextEditingController fromController;
  final TextEditingController toController;
  final VoidCallback onApply;
  final String? message;
  final bool messageIsError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered_rtl_rounded,
                    color: colors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تحميل بنطاق الفصول',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 390;
                  final fields = [
                    Expanded(
                      child: _RangeNumberField(
                        key: const ValueKey('download-range-from'),
                        controller: fromController,
                        label: 'من الفصل',
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _RangeNumberField(
                        key: const ValueKey('download-range-to'),
                        controller: toController,
                        label: 'إلى الفصل',
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onApply(),
                      ),
                    ),
                  ];
                  final button = FilledButton.tonalIcon(
                    key: const ValueKey('download-range-apply'),
                    onPressed: onApply,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('تحديد النطاق'),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: fields),
                        const SizedBox(height: 8),
                        button,
                      ],
                    );
                  }

                  return Row(
                    children: [...fields, const SizedBox(width: 8), button],
                  );
                },
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: messageIsError ? colors.error : colors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeNumberField extends StatelessWidget {
  const _RangeNumberField({
    required this.controller,
    required this.label,
    required this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

int _min(int first, int second) => first < second ? first : second;

int _max(int first, int second) => first > second ? first : second;

int _chapterSortValue(NovelChapter chapter) {
  if (chapter.position > 0) {
    return chapter.position;
  }
  return int.tryParse(chapter.number) ?? chapter.id;
}

int? _visibleChapterNumber(NovelChapter chapter) {
  return _parseChapterNumber(chapter.number) ??
      _parseChapterNumber(chapter.label) ??
      (chapter.position > 0 ? chapter.position : null) ??
      (chapter.id > 0 ? chapter.id : null);
}

int? _parseChapterNumber(String value) {
  final normalized = value
      .trim()
      .replaceAllMapped(
        RegExp('[٠-٩]'),
        (match) => '${match.group(0)!.codeUnitAt(0) - 0x0660}',
      )
      .replaceAllMapped(
        RegExp('[۰-۹]'),
        (match) => '${match.group(0)!.codeUnitAt(0) - 0x06F0}',
      );
  final match = RegExp(r'\d+').firstMatch(normalized);
  return match == null ? null : int.tryParse(match.group(0)!);
}
