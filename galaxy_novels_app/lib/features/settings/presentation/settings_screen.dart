import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/app_theme_controller.dart';
import '../../reader/presentation/reader_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'إعدادات التطبيق',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'مكان واحد لإعدادات التطبيق، وسنضيف له خيارات أكثر لاحقا.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _AppThemeSection(),
                    const SizedBox(height: 24),
                    _SettingsSection(
                      title: 'القراءة',
                      children: [
                        _SettingsTile(
                          icon: Icons.tune_rounded,
                          title: 'إعدادات القراءة',
                          subtitle: 'حجم الخط، تباعد الأسطر، ووضع القراءة',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ReaderSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppThemeSection extends StatelessWidget {
  const _AppThemeSection();

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeControllerScope.of(context);
    final theme = Theme.of(context);

    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: controller,
      builder: (context, selectedChoice, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مظهر التطبيق',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = constraints.maxWidth >= 560 ? 12.0 : 10.0;
                final columns = constraints.maxWidth >= 560 ? 2 : 1;
                final cardWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final choice in AppThemeChoice.values)
                      SizedBox(
                        width: cardWidth,
                        child: _ThemeChoiceCard(
                          choice: choice,
                          selectedChoice: selectedChoice,
                          onChanged: (next) => controller.update(next),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  const _ThemeChoiceCard({
    required this.choice,
    required this.selectedChoice,
    required this.onChanged,
  });

  final AppThemeChoice choice;
  final AppThemeChoice selectedChoice;
  final ValueChanged<AppThemeChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = choice == selectedChoice;
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final backgroundColor = selected
        ? theme.colorScheme.primary.withValues(alpha: 0.10)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);

    return Semantics(
      button: true,
      selected: selected,
      label: _themeChoiceTitle(choice),
      child: Material(
        color: backgroundColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          key: ValueKey('theme-choice-card-${choice.name}'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(choice),
          child: SizedBox(
            height: 156,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _themeChoiceTitle(choice),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ThemePalettePreview(choice: choice),
                  const SizedBox(height: 10),
                  Text(
                    _themeChoiceSubtitle(choice),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePalettePreview extends StatelessWidget {
  const _ThemePalettePreview({required this.choice});

  final AppThemeChoice choice;

  @override
  Widget build(BuildContext context) {
    final colors = _themeChoicePalette(choice);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        key: ValueKey('theme-choice-palette-${choice.name}'),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              for (final color in colors)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: color),
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Color> _themeChoicePalette(AppThemeChoice choice) {
  final tokens = _themeChoiceTokens(choice);
  if (tokens == null) {
    return [
      AppTheme.deepSpace.background,
      AppTheme.deepSpace.primary,
      AppTheme.desertAstronaut.background,
      AppTheme.starlightPaper.primary,
    ];
  }

  return [
    tokens.background,
    tokens.surface,
    tokens.surfaceSoft,
    tokens.primary,
  ];
}

AppThemeTokens? _themeChoiceTokens(AppThemeChoice choice) {
  return switch (choice) {
    AppThemeChoice.system => null,
    AppThemeChoice.deepSpace => AppTheme.deepSpace,
    AppThemeChoice.crimsonPagoda => AppTheme.crimsonPagoda,
    AppThemeChoice.desertAstronaut => AppTheme.desertAstronaut,
    AppThemeChoice.blueberryNebula => AppTheme.blueberryNebula,
    AppThemeChoice.galaxyNoir => AppTheme.galaxyNoir,
    AppThemeChoice.starlightPaper => AppTheme.starlightPaper,
  };
}

String _themeChoiceTitle(AppThemeChoice choice) {
  return switch (choice) {
    AppThemeChoice.system => 'حسب النظام',
    AppThemeChoice.deepSpace => 'الفضاء السحيق / Deep Space',
    AppThemeChoice.crimsonPagoda => 'الكسوف القرمزي / Crimson Eclipse',
    AppThemeChoice.desertAstronaut => 'رائد الصحراء / Desert Astronaut',
    AppThemeChoice.blueberryNebula => 'سديم التوت الأزرق / Blueberry Nebula',
    AppThemeChoice.galaxyNoir => 'Galaxy Noir',
    AppThemeChoice.starlightPaper => 'Starlight Paper',
  };
}

String _themeChoiceSubtitle(AppThemeChoice choice) {
  return switch (choice) {
    AppThemeChoice.system => 'يتبع إعدادات الجهاز تلقائيا',
    AppThemeChoice.deepSpace => 'ثيم داكن مطابق للوحة ألوان موقع مجرة الروايات',
    AppThemeChoice.crimsonPagoda => 'أحمر داكن بطابع درامي وهادئ',
    AppThemeChoice.desertAstronaut => 'ثيم فاتح بدرجات الرمل والبني الهادئ',
    AppThemeChoice.blueberryNebula => 'أزرق عميق مستوحى من لوحة التوت',
    AppThemeChoice.galaxyNoir => 'داكن كحلي مناسب للقراءة الليلية',
    AppThemeChoice.starlightPaper => 'فاتح هادئ للقراءة في النهار',
  };
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.42,
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 14,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_left_rounded),
      onTap: onTap,
    );
  }
}
