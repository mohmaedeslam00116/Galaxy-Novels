import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '0.1.0 (1)';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>() ?? AppTheme.galaxyNoir;

    return Scaffold(
      appBar: AppBar(title: const Text('حول التطبيق')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: tokens.surfaceRaised,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tokens.border),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 40,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'مجرة الروايات',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الإصدار $_version',
                      key: const ValueKey('about-app-version'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Divider(color: tokens.border),
                    ListTile(
                      key: const ValueKey('open-source-licenses'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.code_rounded),
                      title: const Text('تراخيص البرمجيات المفتوحة'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => _openLicenses(context),
                    ),
                    Divider(color: tokens.border),
                    const SizedBox(height: 24),
                    Text(
                      '© ${DateTime.now().year} مجرة الروايات',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textSecondary,
                      ),
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

  void _openLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'مجرة الروايات',
      applicationVersion: _version,
      applicationIcon: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.auto_stories_rounded, size: 44),
      ),
    );
  }
}
