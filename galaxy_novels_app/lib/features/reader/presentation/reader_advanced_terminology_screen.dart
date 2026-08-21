import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/platform/app_json_document_picker.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../application/reader_advanced_terminology_repository.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_term_replacement.dart';

class ReaderAdvancedTerminologyScreen extends StatefulWidget {
  const ReaderAdvancedTerminologyScreen({
    required this.repository,
    this.documentPicker = const MethodChannelAppJsonDocumentPicker(),
    super.key,
  });

  final ReaderAdvancedTerminologyRepository repository;
  final AppJsonDocumentPicker documentPicker;

  @override
  State<ReaderAdvancedTerminologyScreen> createState() =>
      _ReaderAdvancedTerminologyScreenState();
}

class _ReaderAdvancedTerminologyScreenState
    extends State<ReaderAdvancedTerminologyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_handleTabChanged);
    unawaited(widget.repository.load());
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أدوات المصطلحات المتقدمة')),
      body: ValueListenableBuilder<ReaderAdvancedTerminologyState>(
        valueListenable: widget.repository,
        builder: (context, state, child) {
          if (!state.accessUnlocked) return const _HiddenToolsState();
          return _buildContent(state);
        },
      ),
    );
  }

  Widget _buildContent(ReaderAdvancedTerminologyState state) {
    final pack = state.pack;
    final metrics = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          metrics.horizontalPadding,
          GalaxyMetrics.space12,
          metrics.horizontalPadding,
          GalaxyMetrics.space32,
        ),
        children: [
          _PackSummary(
            state: state,
            importing: _importing,
            onImport: _importPack,
            onEnabledChanged: pack == null
                ? null
                : (enabled) => _run(
                    () => widget.repository.setPackEnabled(enabled),
                    failureMessage: 'تعذر تغيير حالة الحزمة',
                  ),
          ),
          const SizedBox(height: GalaxyMetrics.space16),
          if (pack == null)
            const _NoPackGuide()
          else ...[
            GalaxySettingsGroup(
              title: 'أجزاء الحزمة',
              children: [
                GalaxySettingsSwitchTile(
                  icon: Icons.find_replace_rounded,
                  title: 'استبدال المصطلحات',
                  subtitle: '${pack.replacements.length} قاعدة',
                  value: state.features.replacements,
                  onChanged: (value) => _setFeatures(
                    state.features.copyWith(replacements: value),
                  ),
                ),
                GalaxySettingsSwitchTile(
                  icon: Icons.visibility_off_outlined,
                  title: 'إخفاء جمل الحماية',
                  subtitle: '${pack.guardSentences.length} جملة',
                  value: state.features.guardRemoval,
                  onChanged: (value) => _setFeatures(
                    state.features.copyWith(guardRemoval: value),
                  ),
                ),
                GalaxySettingsSwitchTile(
                  icon: Icons.vertical_align_bottom_rounded,
                  title: 'إخفاء نص نهاية الفصل',
                  subtitle: pack.footerText.isEmpty
                      ? 'لا يحتوي الملف على نص نهاية'
                      : 'كتلة مستقلة',
                  value:
                      state.features.footerRemoval &&
                      pack.footerText.isNotEmpty,
                  enabled: pack.footerText.isNotEmpty,
                  onChanged: (value) => _setFeatures(
                    state.features.copyWith(footerRemoval: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GalaxyMetrics.space24),
            Text(
              'إدارة قواعد الحزمة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: GalaxyMetrics.space12),
            GalaxyTabStrip(
              controller: _tabController,
              tabs: const [
                GalaxyTabSpec(
                  label: 'الاستبدالات',
                  icon: Icons.find_replace_rounded,
                ),
                GalaxyTabSpec(
                  label: 'النصوص المخفية',
                  icon: Icons.visibility_off_outlined,
                ),
                GalaxyTabSpec(
                  label: 'الاستثناءات',
                  icon: Icons.shield_outlined,
                ),
              ],
            ),
            const SizedBox(height: GalaxyMetrics.space12),
            GalaxySearchField(
              controller: _searchController,
              hintText: 'ابحث داخل القواعد',
              onChanged: (value) => setState(() => _query = value.trim()),
              onClear: _query.isEmpty
                  ? null
                  : () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
            ),
            const SizedBox(height: GalaxyMetrics.space12),
            ..._rulesForTab(state),
          ],
          const SizedBox(height: GalaxyMetrics.space24),
          OutlinedButton.icon(
            key: const ValueKey('advanced-terms-hide-tools'),
            onPressed: _confirmHideTools,
            icon: const Icon(Icons.lock_outline_rounded),
            label: const Text('إخفاء الأدوات المتقدمة'),
          ),
          if (pack != null) ...[
            const SizedBox(height: GalaxyMetrics.space8),
            TextButton.icon(
              onPressed: _confirmClearPack,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'حذف الحزمة المستوردة',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _rulesForTab(ReaderAdvancedTerminologyState state) {
    return switch (_tabController.index) {
      0 => _replacementTiles(state),
      1 => _removalTiles(state),
      _ => _exceptionTiles(state),
    };
  }

  List<Widget> _replacementTiles(ReaderAdvancedTerminologyState state) {
    final rules = state.pack!.replacements.where((rule) {
      final replacement =
          state.replacementOverrides[rule.source] ?? rule.replacement;
      return _matchesQuery(rule.source, replacement);
    }).toList();
    if (rules.isEmpty) return const [_NoMatchingRules()];
    return [
      for (final rule in rules)
        _AdvancedRuleTile(
          key: ValueKey('advanced-replacement-${rule.source}'),
          title: rule.source,
          subtitle:
              '← ${state.replacementOverrides[rule.source] ?? rule.replacement}',
          enabled: !state.disabledReplacementSources.contains(rule.source),
          customized: state.replacementOverrides.containsKey(rule.source),
          onEnabledChanged: (enabled) => _setRuleEnabled(
            ReaderAdvancedRuleKind.replacement,
            rule.source,
            enabled,
          ),
          onEdit: () => _editImportedRule(
            kind: ReaderAdvancedRuleKind.replacement,
            source: rule.source,
            current:
                state.replacementOverrides[rule.source] ?? rule.replacement,
          ),
          onRestore: () =>
              _restoreRule(ReaderAdvancedRuleKind.replacement, rule.source),
        ),
    ];
  }

  List<Widget> _removalTiles(ReaderAdvancedTerminologyState state) {
    final widgets = <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _addPersonalRemoval,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة نص مخفي'),
        ),
      ),
    ];
    for (final source in state.pack!.guardSentences) {
      final current = state.guardOverrides[source] ?? source;
      if (!_matchesQuery(source, current)) continue;
      widgets.add(
        _AdvancedRuleTile(
          key: ValueKey('advanced-removal-$source'),
          title: current,
          subtitle: 'جملة من الحزمة',
          enabled: !state.disabledGuardSentences.contains(source),
          customized: state.guardOverrides.containsKey(source),
          onEnabledChanged: (enabled) =>
              _setRuleEnabled(ReaderAdvancedRuleKind.removal, source, enabled),
          onEdit: () => _editImportedRule(
            kind: ReaderAdvancedRuleKind.removal,
            source: source,
            current: current,
          ),
          onRestore: () => _restoreRule(ReaderAdvancedRuleKind.removal, source),
        ),
      );
    }
    for (final rule in state.personalRemovals) {
      if (!_matchesQuery(rule.source, '')) continue;
      widgets.add(
        _PersonalRuleTile(
          title: rule.source,
          subtitle: rule.scope == ReaderTermScope.allNovels
              ? 'كل الروايات'
              : 'الرواية رقم ${rule.novelId}',
          onDelete: () => _run(
            () => widget.repository.removePersonalRemoval(rule),
            failureMessage: 'تعذر حذف قاعدة الإخفاء',
          ),
        ),
      );
    }
    if (widgets.length == 1) widgets.add(const _NoMatchingRules());
    return widgets;
  }

  List<Widget> _exceptionTiles(ReaderAdvancedTerminologyState state) {
    final widgets = <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          onPressed: _addPersonalException,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة استثناء محمي'),
        ),
      ),
    ];
    for (final source in state.pack!.exceptions) {
      final current = state.exceptionOverrides[source] ?? source;
      if (!_matchesQuery(source, current)) continue;
      widgets.add(
        _AdvancedRuleTile(
          key: ValueKey('advanced-exception-$source'),
          title: current,
          subtitle: 'يبقى كما هو داخل النص',
          enabled: !state.disabledExceptions.contains(source),
          customized: state.exceptionOverrides.containsKey(source),
          onEnabledChanged: (enabled) => _setRuleEnabled(
            ReaderAdvancedRuleKind.exception,
            source,
            enabled,
          ),
          onEdit: () => _editImportedRule(
            kind: ReaderAdvancedRuleKind.exception,
            source: source,
            current: current,
          ),
          onRestore: () =>
              _restoreRule(ReaderAdvancedRuleKind.exception, source),
        ),
      );
    }
    for (final source in state.personalExceptions) {
      if (!_matchesQuery(source, '')) continue;
      widgets.add(
        _PersonalRuleTile(
          title: source,
          subtitle: 'استثناء شخصي',
          onDelete: () => _run(
            () => widget.repository.removePersonalException(source),
            failureMessage: 'تعذر حذف الاستثناء',
          ),
        ),
      );
    }
    if (widgets.length == 1) widgets.add(const _NoMatchingRules());
    return widgets;
  }

  bool _matchesQuery(String first, String second) {
    if (_query.isEmpty) return true;
    return first.contains(_query) || second.contains(_query);
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && mounted) setState(() {});
  }

  Future<void> _importPack() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final bytes = await widget.documentPicker.pickJson();
      if (bytes == null || !mounted) return;
      final preview = parseReaderTerminologyPack(bytes);
      final features = await _showImportPreview(preview);
      if (features == null || !mounted) return;
      await widget.repository.replacePack(preview, features: features);
      if (!mounted) return;
      _showMessage('تم استيراد الحزمة وتطبيقها');
    } on ReaderTerminologyImportException catch (error) {
      if (mounted) _showMessage(error.message);
    } on AppJsonDocumentPickerException catch (error) {
      if (!mounted) return;
      _showMessage(
        error.code == 'file_too_large'
            ? 'حجم الملف يتجاوز 1 ميغابايت'
            : 'تعذر فتح ملف المصطلحات',
      );
    } catch (_) {
      if (mounted) _showMessage('تعذر استيراد ملف المصطلحات');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<ReaderPackFeatureSelection?> _showImportPreview(
    ReaderTerminologyImportPreview preview,
  ) {
    var features = preview.initialFeatures;
    return showModalBottomSheet<ReaderPackFeatureSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final pack = preview.pack;
          return GalaxyBottomSheet(
            title: 'معاينة الحزمة',
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_replacementCountLabel(pack.replacements.length)}، '
                      '${_guardCountLabel(pack.guardSentences.length)}، '
                      '${pack.exceptions.length} استثناء',
                    ),
                    if (pack.themeVersion.isNotEmpty) ...[
                      const SizedBox(height: GalaxyMetrics.space8),
                      Text('إصدار المصدر: ${pack.themeVersion}'),
                    ],
                    if (pack.siteUrl.isNotEmpty)
                      Text('المصدر: ${pack.siteUrl}'),
                    if (pack.guardEvery > 0 || pack.footerEvery > 0)
                      Text(
                        'تكرار المصدر: الحماية ${_sourceFrequencyLabel(pack.guardEvery)}، '
                        'والنهاية ${_sourceFrequencyLabel(pack.footerEvery)} '
                        '(للمعلومات فقط)',
                      ),
                    if (preview.duplicateReplacementCount > 0) ...[
                      const SizedBox(height: GalaxyMetrics.space8),
                      Text(
                        'تم دمج ${preview.duplicateReplacementCount} تكرار متطابق.',
                      ),
                    ],
                    const SizedBox(height: GalaxyMetrics.space16),
                    SwitchListTile(
                      value: features.replacements,
                      onChanged: (value) => setSheetState(
                        () => features = features.copyWith(replacements: value),
                      ),
                      title: const Text('استبدال المصطلحات'),
                    ),
                    SwitchListTile(
                      value: features.guardRemoval,
                      onChanged: (value) => setSheetState(
                        () => features = features.copyWith(guardRemoval: value),
                      ),
                      title: const Text('إخفاء جمل الحماية'),
                    ),
                    SwitchListTile(
                      value: features.footerRemoval,
                      onChanged: pack.footerText.isEmpty
                          ? null
                          : (value) => setSheetState(
                              () => features = features.copyWith(
                                footerRemoval: value,
                              ),
                            ),
                      title: const Text('إخفاء نص نهاية الفصل'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                key: const ValueKey('advanced-terms-confirm-import'),
                onPressed: () => Navigator.pop(context, features),
                child: Text(
                  widget.repository.value.pack == null
                      ? 'استيراد الحزمة'
                      : 'استبدال الحزمة',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editImportedRule({
    required ReaderAdvancedRuleKind kind,
    required String source,
    required String current,
  }) async {
    final value = await _showTextDialog(
      title: switch (kind) {
        ReaderAdvancedRuleKind.replacement => 'تعديل المصطلح البديل',
        ReaderAdvancedRuleKind.removal => 'تعديل النص المخفي',
        ReaderAdvancedRuleKind.exception => 'تعديل الاستثناء',
      },
      initialValue: current,
    );
    if (value == null) return;
    await _run(
      () => switch (kind) {
        ReaderAdvancedRuleKind.replacement =>
          widget.repository.setReplacementOverride(source, value),
        ReaderAdvancedRuleKind.removal => widget.repository.setRemovalOverride(
          source,
          value,
        ),
        ReaderAdvancedRuleKind.exception =>
          widget.repository.setExceptionOverride(source, value),
      },
      failureMessage: 'تعذر تعديل القاعدة',
    );
  }

  Future<void> _addPersonalRemoval() async {
    final source = await _showTextDialog(title: 'إضافة نص مخفي');
    if (source == null || !mounted) return;
    final scope = await _showScopeDialog();
    if (scope == null) return;
    await _run(
      () => widget.repository.savePersonalRemoval(
        ReaderTextRemovalRule(source: source, scope: scope, novelId: 0),
      ),
      failureMessage: 'تعذر حفظ النص المخفي',
    );
  }

  Future<void> _addPersonalException() async {
    final source = await _showTextDialog(title: 'إضافة استثناء محمي');
    if (source == null) return;
    await _run(
      () => widget.repository.savePersonalException(source),
      failureMessage: 'تعذر حفظ الاستثناء',
    );
  }

  Future<ReaderTermScope?> _showScopeDialog() {
    return showDialog<ReaderTermScope>(
      context: context,
      builder: (context) => GalaxyDialog(
        title: 'نطاق قاعدة الإخفاء',
        content: const Text(
          'القواعد المضافة من هذه الصفحة تطبق على كل الروايات. يمكن إنشاء قاعدة لرواية واحدة من داخل القارئ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ReaderTermScope.allNovels),
            child: const Text('كل الروايات'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showTextDialog({
    required String title,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => GalaxyDialog(
        title: title,
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'النص'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _confirmHideTools() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GalaxyDialog(
        title: 'إخفاء الأدوات المتقدمة؟',
        content: const Text(
          'ستتوقف الحزمة وقواعد الإزالة المتقدمة، وستبقى البيانات محفوظة لإعادة تفعيلها لاحقًا.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إخفاء وتعطيل'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        widget.repository.hideTools,
        failureMessage: 'تعذر إخفاء الأدوات',
      );
    }
  }

  Future<void> _confirmClearPack() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GalaxyDialog(
        title: 'حذف الحزمة؟',
        content: const Text(
          'سيتم حذف الحزمة المستوردة فقط، ولن تتأثر مصطلحاتك وقواعدك الشخصية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف الحزمة'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(
        widget.repository.clearPack,
        failureMessage: 'تعذر حذف الحزمة',
      );
    }
  }

  Future<void> _setFeatures(ReaderPackFeatureSelection features) {
    return _run(
      () => widget.repository.setFeatures(features),
      failureMessage: 'تعذر حفظ إعدادات الحزمة',
    );
  }

  Future<void> _setRuleEnabled(
    ReaderAdvancedRuleKind kind,
    String source,
    bool enabled,
  ) {
    return _run(
      () => widget.repository.setRuleEnabled(kind, source, enabled),
      failureMessage: 'تعذر تغيير حالة القاعدة',
    );
  }

  Future<void> _restoreRule(ReaderAdvancedRuleKind kind, String source) {
    return _run(
      () => widget.repository.restoreRule(kind, source),
      failureMessage: 'تعذر استعادة القاعدة',
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String failureMessage,
  }) async {
    try {
      await action();
    } catch (_) {
      if (mounted) _showMessage(failureMessage);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PackSummary extends StatelessWidget {
  const _PackSummary({
    required this.state,
    required this.importing,
    required this.onImport,
    required this.onEnabledChanged,
  });

  final ReaderAdvancedTerminologyState state;
  final bool importing;
  final VoidCallback onImport;
  final ValueChanged<bool>? onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final pack = state.pack;
    return GalaxySurface(
      variant: GalaxySurfaceVariant.tonal,
      padding: const EdgeInsets.all(GalaxyMetrics.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_folder_outlined),
              const SizedBox(width: GalaxyMetrics.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack == null ? 'لا توجد حزمة مستوردة' : 'حزمة المصطلحات',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (pack != null)
                      Text(
                        '${pack.replacements.length} استبدال • '
                        '${pack.guardSentences.length} نص مخفي • '
                        '${pack.exceptions.length} استثناء',
                      ),
                  ],
                ),
              ),
              if (pack != null)
                Switch(value: state.packEnabled, onChanged: onEnabledChanged),
            ],
          ),
          const SizedBox(height: GalaxyMetrics.space12),
          FilledButton.icon(
            key: const ValueKey('advanced-terms-import'),
            onPressed: importing ? null : onImport,
            icon: importing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open_outlined),
            label: Text(pack == null ? 'استيراد ملف JSON' : 'استبدال الحزمة'),
          ),
        ],
      ),
    );
  }
}

class _NoPackGuide extends StatelessWidget {
  const _NoPackGuide();

  @override
  Widget build(BuildContext context) {
    return GalaxySurface(
      variant: GalaxySurfaceVariant.base,
      padding: const EdgeInsets.all(GalaxyMetrics.space16),
      child: const Text(
        'اختر ملف المصطلحات المعتمد. سيعرض التطبيق ملخص القواعد قبل حفظها، ولن يغيّر الفصول الأصلية أو المحمّلة.',
      ),
    );
  }
}

class _AdvancedRuleTile extends StatelessWidget {
  const _AdvancedRuleTile({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.customized,
    required this.onEnabledChanged,
    required this.onEdit,
    required this.onRestore,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final bool customized;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GalaxyMetrics.space8),
      child: GalaxySurface(
        variant: GalaxySurfaceVariant.base,
        padding: EdgeInsets.zero,
        child: ListTile(
          title: Text(title, maxLines: 3, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle),
          leading: Switch(value: enabled, onChanged: onEnabledChanged),
          trailing: PopupMenuButton<_RuleMenuAction>(
            tooltip: 'إدارة القاعدة',
            onSelected: (action) {
              if (action == _RuleMenuAction.edit) {
                onEdit();
              } else {
                onRestore();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _RuleMenuAction.edit,
                child: Text('تعديل'),
              ),
              PopupMenuItem(
                value: _RuleMenuAction.restore,
                enabled: customized,
                child: const Text('استعادة الأصل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RuleMenuAction { edit, restore }

class _PersonalRuleTile extends StatelessWidget {
  const _PersonalRuleTile({
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: GalaxyMetrics.space8),
      child: GalaxySurface(
        variant: GalaxySurfaceVariant.base,
        padding: EdgeInsets.zero,
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: IconButton(
            tooltip: 'حذف القاعدة',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ),
      ),
    );
  }
}

class _NoMatchingRules extends StatelessWidget {
  const _NoMatchingRules();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: GalaxyMetrics.space24),
      child: Center(child: Text('لا توجد قواعد مطابقة')),
    );
  }
}

class _HiddenToolsState extends StatelessWidget {
  const _HiddenToolsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(GalaxyMetrics.space24),
        child: Text('أدوات المصطلحات المتقدمة غير مفعّلة'),
      ),
    );
  }
}

String _replacementCountLabel(int count) {
  if (count == 1) return 'قاعدة استبدال واحدة';
  if (count == 2) return 'قاعدتا استبدال';
  return '$count قاعدة استبدال';
}

String _guardCountLabel(int count) {
  if (count == 1) return 'جملة حماية واحدة';
  if (count == 2) return 'جملتا حماية';
  return '$count جملة حماية';
}

String _sourceFrequencyLabel(int count) {
  if (count == 1) return 'كل فصل';
  if (count == 2) return 'كل فصلين';
  return count > 0 ? 'كل $count فصول' : 'غير محدد';
}
