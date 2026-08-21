import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../../app_review/application/app_review_prompt_controller.dart';
import '../../onboarding/application/app_onboarding_controller.dart';
import '../../onboarding/presentation/app_onboarding_screen.dart';
import '../../reader/application/reader_advanced_terminology_repository.dart';
import '../application/app_version_info.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({
    this.versionLoader = loadPackageVersionInfo,
    this.advancedTerminologyRepository,
    this.reviewPromptController,
    this.onboardingController,
    super.key,
  });

  final AppVersionLoader versionLoader;
  final ReaderAdvancedTerminologyRepository? advancedTerminologyRepository;
  final AppReviewPromptController? reviewPromptController;
  final AppOnboardingController? onboardingController;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _unavailableVersion = 'غير متاح';

  String? _resolvedVersion;
  DateTime? _lastVersionTap;
  int _versionTapCount = 0;
  bool _openingStore = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    widget.advancedTerminologyRepository?.load();
  }

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
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleVersionTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'الإصدار ${_resolvedVersion ?? _unavailableVersion}',
                          key: const ValueKey('about-app-version'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Divider(color: tokens.border),
                    ListTile(
                      key: const ValueKey('replay-onboarding-tour'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.explore_outlined),
                      title: const Text('إعادة مشاهدة الجولة'),
                      subtitle: const Text(
                        'تعرّف مجددًا على أهم مميزات التطبيق',
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: _replayOnboarding,
                    ),
                    Divider(color: tokens.border),
                    ListTile(
                      key: const ValueKey('rate-galaxy-novels'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.star_outline_rounded),
                      title: const Text('قيّم مجرة الروايات'),
                      subtitle: const Text('افتح صفحة التطبيق في Google Play'),
                      trailing: _openingStore
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new_rounded),
                      onTap: _openingStore ? null : _openStoreListing,
                    ),
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

  Future<void> _openStoreListing() async {
    if (_openingStore) return;
    setState(() => _openingStore = true);
    final opened =
        await widget.reviewPromptController?.openStoreListing() ?? false;
    if (!mounted) return;
    setState(() => _openingStore = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح صفحة التطبيق في Google Play')),
      );
    }
  }

  void _replayOnboarding() {
    final controller = widget.onboardingController;
    if (controller == null) return;
    Navigator.of(context).push(
      galaxyPageRoute<void>(
        context: context,
        settings: const RouteSettings(name: 'onboarding_replay'),
        builder: (routeContext) => AppOnboardingScreen(
          controller: controller,
          entryPoint: AppOnboardingEntryPoint.manual,
          onFinished: () => Navigator.of(routeContext).pop(),
          onExitRequested: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  void _openLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'مجرة الروايات',
      applicationVersion: _resolvedVersion ?? _unavailableVersion,
      applicationIcon: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.auto_stories_rounded, size: 44),
      ),
    );
  }

  Future<void> _loadVersion() async {
    var version = _unavailableVersion;
    try {
      final info = await widget.versionLoader();
      final label = info.displayLabel;
      if (label.isNotEmpty) {
        version = label;
      }
    } on Exception {
      version = _unavailableVersion;
    }
    if (mounted) {
      setState(() => _resolvedVersion = version);
    }
  }

  Future<void> _handleVersionTap() async {
    final repository = widget.advancedTerminologyRepository;
    if (repository == null || repository.value.accessUnlocked) return;
    final now = DateTime.now();
    if (_lastVersionTap == null ||
        now.difference(_lastVersionTap!) > const Duration(seconds: 2)) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount += 1;
    if (_versionTapCount < 7) return;
    _versionTapCount = 0;
    try {
      await repository.unlock();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفعيل أدوات المصطلحات المتقدمة')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تفعيل أدوات المصطلحات المتقدمة')),
      );
    }
  }
}
