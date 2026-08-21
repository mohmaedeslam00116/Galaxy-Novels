import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../application/reader_preferences_repository.dart';
import '../application/reader_advanced_terminology_repository.dart';
import '../application/reader_term_replacement_repository.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_term_replacement.dart';
import 'reader_advanced_terminology_screen.dart';
import 'reader_font_options.dart';
import 'reader_preferences.dart';
import 'reader_settings_sheet.dart';
import 'reader_term_replacement_dialog.dart';

class ReaderSettingsScreen extends StatelessWidget {
  const ReaderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AppDependencies.of(context).readerPreferencesRepository;

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات القراءة')),
      body: ValueListenableBuilder<ReaderPreferences>(
        valueListenable: repository,
        builder: (context, preferences, child) {
          final termRepository = AppDependencies.of(
            context,
          ).readerTermReplacementRepository;
          if (termRepository == null) {
            return _settingsBody(context, repository, preferences, const []);
          }
          return ValueListenableBuilder<List<ReaderTermReplacement>>(
            valueListenable: termRepository,
            builder: (context, replacements, child) {
              return _settingsBody(
                context,
                repository,
                preferences,
                replacements,
                termRepository: termRepository,
              );
            },
          );
        },
      ),
    );
  }

  Widget _settingsBody(
    BuildContext context,
    ReaderPreferencesRepository preferencesRepository,
    ReaderPreferences preferences,
    List<ReaderTermReplacement> termReplacements, {
    ReaderTermReplacementRepository? termRepository,
  }) {
    final advancedRepository = AppDependencies.of(
      context,
    ).readerAdvancedTerminologyRepository;
    if (advancedRepository == null) {
      return _settingsBodyWithAdvanced(
        context,
        preferencesRepository,
        preferences,
        termReplacements,
        termRepository: termRepository,
        advancedState: ReaderAdvancedTerminologyState.defaults,
      );
    }
    return ValueListenableBuilder<ReaderAdvancedTerminologyState>(
      valueListenable: advancedRepository,
      builder: (context, state, child) {
        return _settingsBodyWithAdvanced(
          context,
          preferencesRepository,
          preferences,
          termReplacements,
          termRepository: termRepository,
          advancedRepository: advancedRepository,
          advancedState: state,
        );
      },
    );
  }

  Widget _settingsBodyWithAdvanced(
    BuildContext context,
    ReaderPreferencesRepository preferencesRepository,
    ReaderPreferences preferences,
    List<ReaderTermReplacement> termReplacements, {
    ReaderTermReplacementRepository? termRepository,
    ReaderAdvancedTerminologyRepository? advancedRepository,
    required ReaderAdvancedTerminologyState advancedState,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReaderPreview(preferences: preferences),
                const SizedBox(height: 28),
                ReaderSettingsControls(
                  preferences: preferences,
                  termReplacements: termReplacements,
                  advancedState: advancedState,
                  onOpenAdvanced:
                      advancedState.accessUnlocked && advancedRepository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(
                              name: AppScreenNames.advancedTerminology,
                            ),
                            builder: (_) => ReaderAdvancedTerminologyScreen(
                              repository: advancedRepository,
                            ),
                          ),
                        )
                      : null,
                  onEditTerm: termRepository == null
                      ? null
                      : (replacement) {
                          unawaited(
                            _editTerm(context, termRepository, replacement),
                          );
                        },
                  onDeleteTerm: termRepository == null
                      ? null
                      : (replacement) {
                          unawaited(
                            _deleteTerm(context, termRepository, replacement),
                          );
                        },
                  showHeading: false,
                  onChanged: (next) {
                    unawaited(_save(context, preferencesRepository, next));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editTerm(
    BuildContext context,
    ReaderTermReplacementRepository repository,
    ReaderTermReplacement existing,
  ) async {
    final replacement = await showReaderTermReplacementDialog(
      context: context,
      source: existing.source,
      novelId: existing.novelId,
      existing: existing,
    );
    if (replacement != null) {
      try {
        await repository.save(replacement, replacing: existing);
      } catch (_) {
        if (!context.mounted) return;
        _showTermStorageError(context, 'تعذر حفظ المصطلح');
      }
    }
  }

  Future<void> _deleteTerm(
    BuildContext context,
    ReaderTermReplacementRepository repository,
    ReaderTermReplacement replacement,
  ) async {
    try {
      await repository.remove(replacement);
    } catch (_) {
      if (!context.mounted) return;
      _showTermStorageError(context, 'تعذر حذف المصطلح');
    }
  }

  void _showTermStorageError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(
    BuildContext context,
    ReaderPreferencesRepository repository,
    ReaderPreferences preferences,
  ) async {
    try {
      await repository.update(preferences);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر حفظ إعدادات القراءة')));
    }
  }
}

class _ReaderPreview extends StatelessWidget {
  const _ReaderPreview({required this.preferences});

  final ReaderPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final scheme = preferences.colorSchemeFor(context);
    final theme = Theme.of(context);

    return DecoratedBox(
      key: const ValueKey('reader-settings-preview'),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معاينة',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'كان ضوء النجوم هادئًا، لكن الطريق أمامه كان يخبئ فصلًا جديدًا من الحكاية.',
              key: const ValueKey('reader-settings-preview-text'),
              style: readerFontTextStyle(
                (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
                  color: scheme.onSurface,
                  fontSize:
                      (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                      preferences.fontScale,
                  height: preferences.lineHeight,
                ),
                fontFamily: preferences.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
