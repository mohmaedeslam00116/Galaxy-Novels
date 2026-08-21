import 'package:flutter/material.dart';

import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_term_replacement.dart';
import 'reader_term_highlight.dart';

class ReaderTermsSettingsPanel extends StatelessWidget {
  const ReaderTermsSettingsPanel({
    required this.replacements,
    required this.novelId,
    required this.highlightEnabled,
    required this.onHighlightChanged,
    required this.onEdit,
    required this.onDelete,
    this.advancedState = ReaderAdvancedTerminologyState.defaults,
    this.onOpenAdvanced,
    super.key,
  });

  final List<ReaderTermReplacement> replacements;
  final int novelId;
  final bool highlightEnabled;
  final ValueChanged<bool> onHighlightChanged;
  final ValueChanged<ReaderTermReplacement>? onEdit;
  final ValueChanged<ReaderTermReplacement>? onDelete;
  final ReaderAdvancedTerminologyState advancedState;
  final VoidCallback? onOpenAdvanced;

  @override
  Widget build(BuildContext context) {
    final visibleReplacements = novelId > 0
        ? replacements.where((rule) => rule.appliesToNovel(novelId)).toList()
        : replacements;
    return Column(
      key: const ValueKey('reader-terms-settings-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TermHighlightSetting(
          enabled: highlightEnabled,
          onChanged: onHighlightChanged,
        ),
        const SizedBox(height: 12),
        _TermsGuide(hasCurrentNovel: novelId > 0),
        const SizedBox(height: 14),
        if (advancedState.accessUnlocked && onOpenAdvanced != null) ...[
          _AdvancedTerminologyEntry(
            state: advancedState,
            onTap: onOpenAdvanced!,
          ),
          const SizedBox(height: 14),
        ],
        if (visibleReplacements.isEmpty)
          const _EmptyTermsState()
        else
          for (final replacement in visibleReplacements) ...[
            _TermReplacementTile(
              replacement: replacement,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _AdvancedTerminologyEntry extends StatelessWidget {
  const _AdvancedTerminologyEntry({required this.state, required this.onTap});

  final ReaderAdvancedTerminologyState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = state.pack;
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        key: const ValueKey('reader-advanced-terms-entry'),
        onTap: onTap,
        leading: const Icon(Icons.rule_folder_outlined),
        title: const Text('أدوات المصطلحات المتقدمة'),
        subtitle: Text(
          pack == null
              ? 'لا توجد حزمة مستوردة'
              : state.packEnabled
              ? '${pack.replacements.length} استبدال و${pack.guardSentences.length} نص مخفي'
              : 'الحزمة محفوظة ومتوقفة',
        ),
        trailing: const Icon(Icons.chevron_left_rounded),
      ),
    );
  }
}

class _TermHighlightSetting extends StatelessWidget {
  const _TermHighlightSetting({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewColor = readerTermHighlightColor(theme.brightness);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        key: const ValueKey('reader-term-highlight-toggle'),
        value: enabled,
        onChanged: onChanged,
        title: const Text('تمييز المصطلحات الجديدة'),
        subtitle: const Text('إظهار الكلمات المستبدلة بتظليل سماوي مريح'),
        secondary: DecoratedBox(
          decoration: BoxDecoration(
            color: previewColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text('نص'),
          ),
        ),
      ),
    );
  }
}

class _TermsGuide extends StatelessWidget {
  const _TermsGuide({required this.hasCurrentNovel});

  final bool hasCurrentNovel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.touch_app_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasCurrentNovel
                    ? 'اضغط مطولًا على أي كلمة داخل الفصل لإضافة مصطلح جديد.'
                    : 'أضف المصطلحات بالضغط المطول على الكلمات أثناء قراءة أي فصل.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTermsState extends StatelessWidget {
  const _EmptyTermsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.find_replace_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          const Text('لا توجد مصطلحات محفوظة بعد'),
        ],
      ),
    );
  }
}

class _TermReplacementTile extends StatelessWidget {
  const _TermReplacementTile({
    required this.replacement,
    required this.onEdit,
    required this.onDelete,
  });

  final ReaderTermReplacement replacement;
  final ValueChanged<ReaderTermReplacement>? onEdit;
  final ValueChanged<ReaderTermReplacement>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        key: ValueKey(
          'reader-term-${replacement.scope.name}-${replacement.novelId}-${replacement.source}',
        ),
        title: Text('${replacement.source} ← ${replacement.replacement}'),
        subtitle: Text(
          replacement.scope == ReaderTermScope.allNovels
              ? 'كل الروايات'
              : 'هذه الرواية فقط',
        ),
        trailing: PopupMenuButton<_TermAction>(
          tooltip: 'إدارة المصطلح',
          onSelected: (action) {
            switch (action) {
              case _TermAction.edit:
                onEdit?.call(replacement);
                break;
              case _TermAction.delete:
                onDelete?.call(replacement);
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: _TermAction.edit, child: Text('تعديل')),
            PopupMenuItem(value: _TermAction.delete, child: Text('حذف')),
          ],
        ),
      ),
    );
  }
}

enum _TermAction { edit, delete }
