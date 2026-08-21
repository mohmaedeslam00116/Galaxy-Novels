import 'package:flutter/material.dart';

import '../domain/readable_chapter.dart';

Future<List<ReadableChapter>?> showChapterRangeDownloadSheet({
  required BuildContext context,
  required List<ReadableChapter> chapters,
}) {
  return showModalBottomSheet<List<ReadableChapter>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ChapterRangeDownloadSheet(chapters: chapters),
  );
}

class _ChapterRangeDownloadSheet extends StatefulWidget {
  const _ChapterRangeDownloadSheet({required this.chapters});

  final List<ReadableChapter> chapters;

  @override
  State<_ChapterRangeDownloadSheet> createState() =>
      _ChapterRangeDownloadSheetState();
}

class _ChapterRangeDownloadSheetState
    extends State<_ChapterRangeDownloadSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    final first = widget.chapters.isEmpty
        ? 1
        : widget.chapters.first.sortPosition;
    final last = widget.chapters.isEmpty
        ? first
        : widget.chapters.last.sortPosition;
    _startController = TextEditingController(text: '$first');
    _endController = TextEditingController(text: '$last');
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تنزيل نطاق فصول',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'حدّد أول وآخر فصل، وسيُضاف كل ما بينهما إلى التنزيلات تلقائيًا.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('chapter-range-start'),
                    controller: _startController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'من الفصل',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePositiveNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('chapter-range-end'),
                    controller: _endController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'إلى الفصل',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validatePositiveNumber,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            if (_rangeError != null) ...[
              const SizedBox(height: 10),
              Text(
                _rangeError!,
                key: const ValueKey('chapter-range-error'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('chapter-range-submit'),
              onPressed: _submit,
              icon: const Icon(Icons.download_for_offline_rounded),
              label: const Text('تنزيل النطاق'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validatePositiveNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number == null || number <= 0 ? 'أدخل رقمًا صحيحًا' : null;
  }

  void _submit() {
    setState(() => _rangeError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final start = int.parse(_startController.text.trim());
    final end = int.parse(_endController.text.trim());
    if (end < start) {
      setState(() => _rangeError = 'يجب أن يكون الفصل الأخير بعد الأول.');
      return;
    }

    final selected = readableChaptersInPositionRange(
      widget.chapters,
      start: start,
      end: end,
    );
    if (selected.isEmpty) {
      setState(() => _rangeError = 'لا توجد فصول متاحة داخل هذا النطاق.');
      return;
    }
    Navigator.of(context).pop(selected);
  }
}
