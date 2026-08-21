import 'package:flutter/material.dart';

import '../domain/reader_term_replacement.dart';

Future<ReaderTermReplacement?> showReaderTermReplacementDialog({
  required BuildContext context,
  required String source,
  required int novelId,
  ReaderTermReplacement? existing,
}) {
  return showDialog<ReaderTermReplacement>(
    context: context,
    builder: (context) => _ReaderTermReplacementDialog(
      source: source,
      novelId: novelId,
      existing: existing,
    ),
  );
}

class _ReaderTermReplacementDialog extends StatefulWidget {
  const _ReaderTermReplacementDialog({
    required this.source,
    required this.novelId,
    this.existing,
  });

  final String source;
  final int novelId;
  final ReaderTermReplacement? existing;

  @override
  State<_ReaderTermReplacementDialog> createState() =>
      _ReaderTermReplacementDialogState();
}

class _ReaderTermReplacementDialogState
    extends State<_ReaderTermReplacementDialog> {
  late final TextEditingController _replacementController;
  late ReaderTermScope _scope;

  @override
  void initState() {
    super.initState();
    _replacementController = TextEditingController(
      text: widget.existing?.replacement ?? '',
    );
    _scope =
        widget.existing?.scope ??
        (widget.novelId > 0
            ? ReaderTermScope.currentNovel
            : ReaderTermScope.allNovels);
  }

  @override
  void dispose() {
    _replacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const ValueKey('reader-term-replacement-dialog'),
      title: const Text('تغيير المصطلح'),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('المصطلح الأصلي', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                widget.source,
                key: const ValueKey('reader-term-source'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('reader-term-replacement-input'),
            controller: _replacementController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'المصطلح الجديد',
              hintText: 'اكتب الكلمة البديلة',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          Text('نطاق التطبيق', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.novelId > 0)
                ChoiceChip(
                  key: const ValueKey('reader-term-scope-current'),
                  selected: _scope == ReaderTermScope.currentNovel,
                  label: const Text('هذه الرواية فقط'),
                  avatar: const Icon(Icons.menu_book_rounded, size: 18),
                  onSelected: (_) {
                    setState(() => _scope = ReaderTermScope.currentNovel);
                  },
                ),
              ChoiceChip(
                key: const ValueKey('reader-term-scope-all'),
                selected: _scope == ReaderTermScope.allNovels,
                label: const Text('كل الروايات'),
                avatar: const Icon(Icons.public_rounded, size: 18),
                onSelected: (_) {
                  setState(() => _scope = ReaderTermScope.allNovels);
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const ValueKey('reader-term-save'),
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _save() {
    final replacement = _replacementController.text.trim();
    if (replacement.isEmpty || replacement == widget.source) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب مصطلحًا جديدًا مختلفًا')),
      );
      return;
    }
    Navigator.pop(
      context,
      ReaderTermReplacement(
        source: widget.source,
        replacement: replacement,
        scope: _scope,
        novelId: _scope == ReaderTermScope.currentNovel ? widget.novelId : 0,
      ),
    );
  }
}
