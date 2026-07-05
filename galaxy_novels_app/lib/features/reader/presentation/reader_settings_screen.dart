import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../application/reader_preferences_repository.dart';
import 'reader_font_options.dart';
import 'reader_preferences.dart';
import 'reader_settings_sheet.dart';

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
                        showHeading: false,
                        onChanged: (next) {
                          unawaited(_save(context, repository, next));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurface,
                fontFamily: preferences.fontFamily.fontFamily,
                fontSize:
                    (theme.textTheme.bodyLarge?.fontSize ?? 16) *
                    preferences.fontScale,
                height: preferences.lineHeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
