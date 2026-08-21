import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../app/app_theme.dart';
import '../../../app/app_theme_controller.dart';
import '../../../core/analytics/app_screen_names.dart';
import '../../../core/navigation/external_uri_launcher.dart';
import '../../../core/network/app_cache_maintenance.dart';
import '../../../core/platform/app_system_settings.dart';
import '../../../design_system/galaxy_design_system.dart';
import '../../about/application/app_version_info.dart';
import '../../about/presentation/about_screen.dart';
import '../../account/application/auth_repository.dart';
import '../../account/domain/auth_session.dart';
import '../../account/presentation/account_screen.dart';
import '../../ads/application/ad_privacy_options_repository.dart';
import '../../catalog/application/library_customization_repository.dart';
import '../../catalog/presentation/library_customization_screen.dart';
import '../../downloads/application/download_repository.dart';
import '../../downloads/domain/download_models.dart';
import '../../downloads/presentation/downloads_screen.dart';
import '../../home/application/home_customization_repository.dart';
import '../../home/application/home_recommendation_exclusion_repository.dart';
import '../../home/presentation/home_customization_screen.dart';
import '../../privacy/presentation/privacy_policy_screen.dart';
import '../../reader/presentation/reader_settings_screen.dart';
import 'data_management_screen.dart';
import 'settings_formatters.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    this.systemSettings = const AppSystemSettings(),
    this.uriLauncher = launchExternalUri,
    this.versionLoader = loadPackageVersionInfo,
    this.authRepository,
    this.downloadRepository,
    this.cacheMaintenance,
    this.adPrivacyOptionsRepository,
    this.homeRecommendationExclusionRepository,
    super.key,
  });

  final AppSystemSettings systemSettings;
  final ExternalUriLauncher uriLauncher;
  final AppVersionLoader versionLoader;
  final AuthRepository? authRepository;
  final DownloadRepository? downloadRepository;
  final AppCacheMaintenance? cacheMaintenance;
  final AdPrivacyOptionsRepository? adPrivacyOptionsRepository;
  final HomeRecommendationExclusionRepository?
  homeRecommendationExclusionRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _discordUri = Uri.parse('https://discord.gg/fD7U7zbCgM');

  AdPrivacyOptionsRepository? _privacyRepository;
  AdPrivacyOptionsStatus? _privacyStatus;
  String? _versionLabel;
  bool _savingWifi = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVersion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dependencies = AppDependencies.maybeOf(context);
    final repository =
        widget.adPrivacyOptionsRepository ??
        dependencies?.adPrivacyOptionsRepository ??
        const NoopAdPrivacyOptionsRepository();
    if (identical(repository, _privacyRepository)) return;
    _privacyRepository = repository;
    unawaited(_loadPrivacyStatus(repository));
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppDependencies.maybeOf(context);
    final authRepository =
        widget.authRepository ?? dependencies?.authRepository;
    final downloads =
        widget.downloadRepository ??
        dependencies?.downloadRepository ??
        const NoopDownloadRepository();
    final cache =
        widget.cacheMaintenance ??
        dependencies?.cacheMaintenance ??
        const NoopAppCacheMaintenance();
    final exclusions =
        widget.homeRecommendationExclusionRepository ??
        dependencies?.homeRecommendationExclusionRepository;
    final metrics = GalaxyAdaptiveMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      key: const ValueKey('settings-hub-screen'),
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            metrics.horizontalPadding,
            GalaxyMetrics.space16,
            metrics.horizontalPadding,
            GalaxyMetrics.space32,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccountSummary(
                      repository: authRepository,
                      onOpen: dependencies == null
                          ? null
                          : () => _push(const AccountScreen()),
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    const _AppThemeSection(),
                    SizedBox(height: metrics.sectionSpacing),
                    GalaxySettingsGroup(
                      title: 'التخصيص والقراءة',
                      children: [
                        GalaxySettingsTile(
                          key: const ValueKey('settings-home-customization'),
                          icon: Icons.dashboard_customize_outlined,
                          title: 'تخصيص الرئيسية',
                          subtitle: 'ترتيب الأقسام وشكل عرض الروايات',
                          onTap: _openHomeCustomization,
                        ),
                        GalaxySettingsTile(
                          key: const ValueKey('settings-library-customization'),
                          icon: Icons.local_library_outlined,
                          title: 'تخصيص المكتبة',
                          subtitle: 'الشبكة والقائمة وكثافة البطاقات',
                          onTap: _openLibraryCustomization,
                        ),
                        GalaxySettingsTile(
                          key: const ValueKey('settings-reader-customization'),
                          icon: Icons.tune_rounded,
                          title: 'إعدادات القراءة',
                          subtitle: 'الخط والتمرير والمصطلحات وألوان الفصل',
                          onTap: () => _push(const ReaderSettingsScreen()),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    ValueListenableBuilder<DownloadsDashboard>(
                      valueListenable: downloads,
                      builder: (context, dashboard, child) {
                        return GalaxySettingsGroup(
                          title: 'البيانات والتنزيلات',
                          children: [
                            GalaxySettingsTile(
                              key: const ValueKey('settings-downloads'),
                              icon: Icons.download_done_rounded,
                              title: 'التنزيلات',
                              subtitle: _downloadsSummary(dashboard),
                              onTap: dependencies == null
                                  ? null
                                  : () => _openDownloads(dependencies),
                            ),
                            GalaxySettingsSwitchTile(
                              key: const ValueKey('settings-wifi-only'),
                              icon: Icons.wifi_rounded,
                              title: 'التنزيل عبر Wi-Fi فقط',
                              subtitle: _savingWifi
                                  ? 'جارٍ حفظ التفضيل…'
                                  : 'يمنع بدء تنزيلات جديدة عبر بيانات الهاتف',
                              value: dashboard.wifiOnly,
                              enabled:
                                  !_savingWifi && !dashboard.isInitializing,
                              onChanged: (enabled) =>
                                  _setWifiOnly(downloads, enabled),
                            ),
                            GalaxySettingsTile(
                              key: const ValueKey('settings-data-management'),
                              icon: Icons.storage_outlined,
                              title: 'إدارة البيانات',
                              subtitle:
                                  'الملفات المؤقتة والتنزيلات والتوصيات المخفية',
                              onTap: () => _push(
                                DataManagementScreen(
                                  cacheMaintenance: cache,
                                  downloadRepository: downloads,
                                  exclusionRepository: exclusions,
                                  onOpenDownloads: dependencies == null
                                      ? null
                                      : () => _openDownloads(dependencies),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    GalaxySettingsGroup(
                      title: 'الخصوصية والإشعارات',
                      children: [
                        GalaxySettingsTile(
                          key: const ValueKey('settings-notifications'),
                          icon: Icons.notifications_outlined,
                          title: 'إشعارات التنزيل',
                          subtitle: 'إدارة الإذن والتنبيهات من إعدادات Android',
                          onTap: _openNotificationSettings,
                        ),
                        GalaxySettingsTile(
                          key: const ValueKey('settings-ad-privacy'),
                          icon: Icons.ads_click_outlined,
                          title: 'خيارات خصوصية الإعلانات',
                          subtitle: _privacyStatusLabel(_privacyStatus),
                          onTap: _handleAdPrivacy,
                        ),
                        GalaxySettingsTile(
                          key: const ValueKey('settings-privacy-policy'),
                          icon: Icons.privacy_tip_outlined,
                          title: 'سياسة الخصوصية',
                          subtitle: 'البيانات والإعلانات وحقوقك',
                          onTap: () => _push(
                            PrivacyPolicyScreen(
                              uriLauncher: widget.uriLauncher,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.sectionSpacing),
                    GalaxySettingsGroup(
                      title: 'الدعم ومعلومات التطبيق',
                      children: [
                        GalaxySettingsTile(
                          key: const ValueKey('settings-discord'),
                          icon: Icons.forum_outlined,
                          title: 'مجتمع Discord',
                          subtitle: 'المساعدة ومشاركة الاقتراحات',
                          onTap: _openDiscord,
                        ),
                        GalaxySettingsTile(
                          key: const ValueKey('settings-about'),
                          icon: Icons.info_outline_rounded,
                          title: 'حول التطبيق',
                          subtitle: _versionLabel == null
                              ? 'مجرة الروايات'
                              : 'الإصدار $_versionLabel',
                          onTap: () => _push(
                            AboutScreen(
                              versionLoader: widget.versionLoader,
                              advancedTerminologyRepository: AppDependencies.of(
                                context,
                              ).readerAdvancedTerminologyRepository,
                              reviewPromptController: AppDependencies.of(
                                context,
                              ).appReviewPromptController,
                              onboardingController: AppDependencies.of(
                                context,
                              ).appOnboardingController,
                            ),
                          ),
                        ),
                        GalaxySettingsTile(
                          key: const ValueKey('settings-licenses'),
                          icon: Icons.code_rounded,
                          title: 'تراخيص البرمجيات',
                          subtitle: 'المكتبات المفتوحة المصدر المستخدمة',
                          onTap: _openLicenses,
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

  Future<void> _loadVersion() async {
    try {
      final info = await widget.versionLoader();
      if (mounted) setState(() => _versionLabel = info.displayLabel);
    } on Exception {
      // The settings hub remains useful when platform package info is absent.
    }
  }

  Future<void> _loadPrivacyStatus(AdPrivacyOptionsRepository repository) async {
    if (mounted) setState(() => _privacyStatus = null);
    AdPrivacyOptionsStatus status;
    try {
      status = await repository.loadStatus();
    } on Exception {
      status = AdPrivacyOptionsStatus.unavailable;
    }
    if (mounted && identical(repository, _privacyRepository)) {
      setState(() => _privacyStatus = status);
    }
  }

  Future<void> _handleAdPrivacy() async {
    final repository = _privacyRepository;
    if (repository == null) return;
    final status = _privacyStatus;
    if (status == null) return;
    if (status == AdPrivacyOptionsStatus.notRequired) {
      _message('لا يحتاج حسابك أو منطقتك إلى إجراء إضافي الآن.');
      return;
    }
    if (status == AdPrivacyOptionsStatus.unavailable) {
      await _loadPrivacyStatus(repository);
      if (mounted && _privacyStatus == AdPrivacyOptionsStatus.unavailable) {
        _message('تعذر التحقق من خيارات الخصوصية. حاول لاحقًا.');
      }
      return;
    }
    AdPrivacyOptionsOutcome outcome;
    try {
      outcome = await repository.show();
    } on Exception {
      outcome = AdPrivacyOptionsOutcome.unavailable;
    }
    if (!mounted) return;
    if (outcome == AdPrivacyOptionsOutcome.unavailable) {
      _message('تعذر فتح خيارات خصوصية الإعلانات الآن.');
      return;
    }
    await _loadPrivacyStatus(repository);
  }

  Future<void> _setWifiOnly(DownloadRepository repository, bool enabled) async {
    if (_savingWifi) return;
    setState(() => _savingWifi = true);
    try {
      await repository.setWifiOnly(enabled);
    } on Exception {
      if (mounted) {
        _message('تعذر حفظ تفضيل شبكة التنزيل. بقيت القيمة السابقة.');
      }
    } finally {
      if (mounted) setState(() => _savingWifi = false);
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      if (await widget.systemSettings.openNotificationSettings()) return;
    } on PlatformException {
      // Fall through to safe user feedback.
    } on MissingPluginException {
      // Fall through to safe user feedback.
    }
    if (mounted) _message('تعذر فتح إعدادات الإشعارات على هذا الجهاز.');
  }

  Future<void> _openDiscord() async {
    try {
      if (await widget.uriLauncher(_discordUri)) return;
    } on Exception {
      // Fall through to safe user feedback.
    }
    if (mounted) _message('تعذر فتح رابط Discord الآن.');
  }

  void _openHomeCustomization() {
    final repository = HomeCustomizationRepositoryScope.of(context);
    _push(HomeCustomizationScreen(repository: repository));
  }

  void _openLibraryCustomization() {
    final repository = LibraryCustomizationRepositoryScope.of(context);
    _push(LibraryCustomizationScreen(repository: repository));
  }

  void _openDownloads(AppDependencies dependencies) {
    _push(
      DownloadsScreen(
        repository: dependencies.downloadRepository,
        rewardedAds: dependencies.rewardedDownloadAdRepository,
        downloadAnalytics: dependencies.downloadAnalytics,
        readingHistoryRepository: dependencies.readingHistoryRepository,
      ),
    );
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'مجرة الروايات',
      applicationVersion: _versionLabel,
      applicationIcon: const Icon(Icons.auto_stories_rounded, size: 44),
    );
  }

  void _push(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: _screenNameFor(screen)),
        builder: (context) => screen,
      ),
    );
  }

  String? _screenNameFor(Widget screen) => switch (screen) {
    AccountScreen() => AppScreenNames.account,
    HomeCustomizationScreen() => AppScreenNames.homeCustomization,
    LibraryCustomizationScreen() => AppScreenNames.libraryCustomization,
    ReaderSettingsScreen() => AppScreenNames.readerSettings,
    DownloadsScreen() => AppScreenNames.downloads,
    DataManagementScreen() => AppScreenNames.dataManagement,
    PrivacyPolicyScreen() => AppScreenNames.privacy,
    AboutScreen() => AppScreenNames.about,
    _ => null,
  };

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.repository, required this.onOpen});

  final AuthRepository? repository;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final source = repository;
    if (source == null) {
      return GalaxySettingsAccountSummary(
        summary: const GalaxyAccountSummaryData(
          title: 'أنت تتصفح كزائر',
          subtitle: 'سجّل الدخول لحفظ حسابك وعضويتك',
        ),
        onTap: onOpen ?? () {},
      );
    }
    return ValueListenableBuilder<AuthSessionState>(
      valueListenable: source,
      builder: (context, state, child) {
        if (state.status == AuthSessionStatus.idle ||
            state.status == AuthSessionStatus.restoring ||
            state.status == AuthSessionStatus.authenticating) {
          return const _AccountLoadingSummary();
        }
        final user = state.user;
        if (user != null) {
          return GalaxySettingsAccountSummary(
            summary: GalaxyAccountSummaryData(
              title: user.displayName,
              subtitle: user.vip.active
                  ? 'عضويتك مفعّلة وتفضيلاتك جاهزة'
                  : 'حساب عادي',
              badge: user.vip.active
                  ? (user.vip.label.trim().isEmpty ? 'VIP' : user.vip.label)
                  : null,
              avatarUrl: user.avatar?.toString(),
            ),
            onTap: onOpen ?? () {},
          );
        }
        if (state.status == AuthSessionStatus.failure) {
          return GalaxySettingsAccountSummary(
            summary: const GalaxyAccountSummaryData(
              title: 'تعذر استعادة الحساب',
              subtitle: 'اضغط لإعادة المحاولة',
            ),
            onTap: () => unawaited(source.restoreSession()),
          );
        }
        return GalaxySettingsAccountSummary(
          summary: const GalaxyAccountSummaryData(
            title: 'أنت تتصفح كزائر',
            subtitle: 'سجّل الدخول للوصول إلى الحساب والعضوية',
          ),
          onTap: onOpen ?? () {},
        );
      },
    );
  }
}

class _AccountLoadingSummary extends StatelessWidget {
  const _AccountLoadingSummary();

  @override
  Widget build(BuildContext context) {
    return const GalaxySurface(
      variant: GalaxySurfaceVariant.tonal,
      padding: EdgeInsets.all(GalaxyMetrics.space16),
      child: SizedBox(height: 96, child: GalaxySkeleton()),
    );
  }
}

class _AppThemeSection extends StatelessWidget {
  const _AppThemeSection();

  @override
  Widget build(BuildContext context) {
    final controller = AppThemeControllerScope.of(context);
    return ValueListenableBuilder<AppThemeChoice>(
      valueListenable: controller,
      builder: (context, selected, child) {
        final disableAnimations = MediaQuery.disableAnimationsOf(context);
        final tokens = _themeChoiceTokens(selected);
        void select(AppThemeChoice next) {
          if (next == selected) return;
          unawaited(controller.update(next));
          if (!disableAnimations) unawaited(HapticFeedback.selectionClick());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: GalaxyMetrics.space8,
                bottom: GalaxyMetrics.space8,
              ),
              child: Text(
                'المظهر والثيمات',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: GalaxyDesignTokens.of(context).contentSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            KeyedSubtree(
              key: const ValueKey('app-theme-large-preview'),
              child: GalaxyCompactThemePreview(
                preview: GalaxyThemePreviewData(
                  title: _themeChoiceTitle(selected),
                  canvas: tokens.canvas,
                  surface: tokens.surface,
                  surfaceRaised: tokens.surfaceRaised,
                  brand: tokens.brand,
                  onBrand: tokens.onBrand,
                ),
              ),
            ),
            const SizedBox(height: GalaxyMetrics.space12),
            _ThemeChoiceStrip(
              key: const ValueKey('app-theme-dark-choice-strip'),
              label: 'ثيمات داكنة',
              choices: _darkThemeChoices,
              selected: selected,
              onSelect: select,
            ),
            const SizedBox(height: GalaxyMetrics.space12),
            _ThemeChoiceStrip(
              key: const ValueKey('app-theme-light-choice-strip'),
              label: 'ثيمات فاتحة',
              choices: _lightThemeChoices,
              selected: selected,
              onSelect: select,
            ),
          ],
        );
      },
    );
  }
}

const _darkThemeChoices = <AppThemeChoice>[
  AppThemeChoice.galaxyNoir,
  AppThemeChoice.neutralDark,
  AppThemeChoice.cosmicNight,
  AppThemeChoice.oceanAsh,
  AppThemeChoice.moonForest,
  AppThemeChoice.garnetVelvet,
  AppThemeChoice.copperDusk,
  AppThemeChoice.midnightTide,
];

const _lightThemeChoices = <AppThemeChoice>[
  AppThemeChoice.starlightPaper,
  AppThemeChoice.lightNature,
];

class _ThemeChoiceStrip extends StatelessWidget {
  const _ThemeChoiceStrip({
    required this.label,
    required this.choices,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final String label;
  final List<AppThemeChoice> choices;
  final AppThemeChoice selected;
  final ValueChanged<AppThemeChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: GalaxyDesignTokens.of(context).contentSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: GalaxyMetrics.space8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final choice in choices) ...[
                _ThemeChoice(
                  choice: choice,
                  selected: choice == selected,
                  onTap: () => onSelect(choice),
                ),
                if (choice != choices.last)
                  const SizedBox(width: GalaxyMetrics.space8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final AppThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = _themeChoiceTokens(choice);
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Semantics(
      selected: selected,
      button: true,
      label: _themeChoiceTitle(choice),
      child: Material(
        color: selected ? tokens.brandContainer : tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GalaxyMetrics.radiusControl),
          side: BorderSide(
            color: selected ? tokens.brand : tokens.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('theme-choice-card-${choice.name}'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GalaxyMetrics.minimumTouchTarget,
            ),
            child: SizedBox(
              width: textScale > 1.4 ? 170 : 138,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GalaxyMetrics.space12,
                  vertical: GalaxyMetrics.space8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _themeChoiceTitle(choice),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: tokens.contentPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (selected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: tokens.brand,
                          ),
                      ],
                    ),
                    const SizedBox(height: GalaxyMetrics.space8),
                    Row(
                      children: [
                        _ThemeDot(color: tokens.canvas),
                        const SizedBox(width: GalaxyMetrics.space4),
                        _ThemeDot(color: tokens.surfaceRaised),
                        const SizedBox(width: GalaxyMetrics.space4),
                        _ThemeDot(color: tokens.brand),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

AppThemeTokens _themeChoiceTokens(AppThemeChoice choice) {
  return switch (choice) {
    AppThemeChoice.starlightPaper => AppTheme.starlightPaper,
    AppThemeChoice.neutralDark => AppTheme.neutralDark,
    AppThemeChoice.galaxyNoir => AppTheme.galaxyNoir,
    AppThemeChoice.cosmicNight => AppTheme.cosmicNight,
    AppThemeChoice.lightNature => AppTheme.lightNature,
    AppThemeChoice.oceanAsh => AppTheme.oceanAsh,
    AppThemeChoice.moonForest => AppTheme.moonForest,
    AppThemeChoice.garnetVelvet => AppTheme.garnetVelvet,
    AppThemeChoice.copperDusk => AppTheme.copperDusk,
    AppThemeChoice.midnightTide => AppTheme.midnightTide,
  };
}

String _themeChoiceTitle(AppThemeChoice choice) {
  return switch (choice) {
    AppThemeChoice.starlightPaper => 'نور الصفحات',
    AppThemeChoice.neutralDark => 'سكون الليل',
    AppThemeChoice.galaxyNoir => 'أطياف السديم',
    AppThemeChoice.cosmicNight => 'مدار النجوم',
    AppThemeChoice.lightNature => 'نسيم الواحة',
    AppThemeChoice.oceanAsh => 'رماد المحيط',
    AppThemeChoice.moonForest => 'غابة القمر',
    AppThemeChoice.garnetVelvet => 'مخمل العقيق',
    AppThemeChoice.copperDusk => 'نحاس الغروب',
    AppThemeChoice.midnightTide => 'مدّ منتصف الليل',
  };
}

String _downloadsSummary(DownloadsDashboard dashboard) {
  if (dashboard.isInitializing) return 'جارٍ استعادة التنزيلات…';
  final count = dashboard.novels.length;
  return '$count رواية • ${formatStorageSize(dashboard.totalBytes)}';
}

String _privacyStatusLabel(AdPrivacyOptionsStatus? status) {
  return switch (status) {
    null => 'جارٍ التحقق من خيارات Google…',
    AdPrivacyOptionsStatus.required => 'إدارة موافقة الإعلانات وخياراتها',
    AdPrivacyOptionsStatus.notRequired => 'لا يلزم إجراء إضافي حاليًا',
    AdPrivacyOptionsStatus.unavailable => 'تعذر التحقق — اضغط لإعادة المحاولة',
  };
}
