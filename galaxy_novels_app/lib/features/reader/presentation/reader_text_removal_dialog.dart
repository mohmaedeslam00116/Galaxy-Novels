import 'package:flutter/material.dart';

import '../../../design_system/galaxy_design_system.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_term_replacement.dart';

Future<ReaderTextRemovalRule?> showReaderTextRemovalDialog({
  required BuildContext context,
  required String source,
  required int novelId,
}) {
  return showDialog<ReaderTextRemovalRule>(
    context: context,
    builder: (context) =>
        _ReaderTextRemovalDialog(source: source, novelId: novelId),
  );
}

class _ReaderTextRemovalDialog extends StatefulWidget {
  const _ReaderTextRemovalDialog({required this.source, required this.novelId});

  final String source;
  final int novelId;

  @override
  State<_ReaderTextRemovalDialog> createState() =>
      _ReaderTextRemovalDialogState();
}

class _ReaderTextRemovalDialogState extends State<_ReaderTextRemovalDialog> {
  late ReaderTermScope _scope = widget.novelId > 0
      ? ReaderTermScope.currentNovel
      : ReaderTermScope.allNovels;

  @override
  Widget build(BuildContext context) {
    return GalaxyDialog(
      title: 'إخفاء النص أثناء القراءة',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.source,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: GalaxyMetrics.space16),
          const Text('نطاق التطبيق'),
          const SizedBox(height: GalaxyMetrics.space8),
          Wrap(
            spacing: GalaxyMetrics.space8,
            runSpacing: GalaxyMetrics.space8,
            children: [
              if (widget.novelId > 0)
                ChoiceChip(
                  selected: _scope == ReaderTermScope.currentNovel,
                  onSelected: (_) =>
                      setState(() => _scope = ReaderTermScope.currentNovel),
                  label: const Text('هذه الرواية فقط'),
                ),
              ChoiceChip(
                selected: _scope == ReaderTermScope.allNovels,
                onSelected: (_) =>
                    setState(() => _scope = ReaderTermScope.allNovels),
                label: const Text('كل الروايات'),
              ),
            ],
          ),
          const SizedBox(height: GalaxyMetrics.space12),
          Text(
            'سيختفي كل تطابق من العرض فقط، ولن يتغير الفصل الأصلي أو المحمّل.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const ValueKey('reader-removal-save'),
          onPressed: () => Navigator.pop(
            context,
            ReaderTextRemovalRule(
              source: widget.source.trim(),
              scope: _scope,
              novelId: _scope == ReaderTermScope.currentNovel
                  ? widget.novelId
                  : 0,
            ),
          ),
          child: const Text('إخفاء النص'),
        ),
      ],
    );
  }
}
