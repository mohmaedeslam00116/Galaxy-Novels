import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/app/app_theme_controller.dart';
import 'package:galaxy_novels_app/core/platform/app_system_settings.dart';
import 'package:galaxy_novels_app/design_system/components/galaxy_skeleton.dart';
import 'package:galaxy_novels_app/features/account/application/auth_repository.dart';
import 'package:galaxy_novels_app/features/account/domain/auth_session.dart';
import 'package:galaxy_novels_app/features/ads/application/ad_privacy_options_repository.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_entitlement.dart';
import 'package:galaxy_novels_app/features/downloads/domain/download_models.dart';
import 'package:galaxy_novels_app/features/settings/presentation/settings_screen.dart';

import '../../helpers/fake_auth_repository.dart';

void main() {
  testWidgets(
    'account summary covers loading guest authenticated and failure',
    (tester) async {
      final auth = _MutableAuthRepository(const AuthSessionState.restoring());
      await tester.pumpWidget(_surface(SettingsScreen(authRepository: auth)));
      await tester.pump();
      expect(find.byType(GalaxySkeleton), findsOneWidget);

      auth.value = const AuthSessionState.guest();
      await tester.pump();
      expect(find.text('أنت تتصفح كزائر'), findsOneWidget);

      auth.value = const AuthSessionState.authenticated(_vipUser);
      await tester.pump();
      expect(find.text('قارئ المجرة'), findsOneWidget);

      auth.value = const AuthSessionState.failure('network');
      await tester.pump();
      await tester.tap(find.text('تعذر استعادة الحساب'));
      expect(auth.restoreCalls, 1);
    },
  );

  testWidgets('renders authenticated account membership and download summary', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      initialState: const AuthSessionState.authenticated(_vipUser),
    );
    final downloads = _MemoryDownloadRepository(_dashboard);
    await tester.pumpWidget(
      _surface(
        SettingsScreen(
          authRepository: auth,
          downloadRepository: downloads,
          adPrivacyOptionsRepository: _MemoryAdPrivacy(
            AdPrivacyOptionsStatus.notRequired,
          ),
          versionLoader: () async => throw Exception('not available'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('قارئ المجرة'), findsOneWidget);
    expect(find.text('VIP 2'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('settings-downloads')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1 رواية'), findsOneWidget);
    expect(find.textContaining('2.0 ك.ب'), findsOneWidget);
  });

  testWidgets('saves Wi-Fi preference immediately and rolls back on failure', (
    tester,
  ) async {
    final downloads = _MemoryDownloadRepository(_dashboard);
    await tester.pumpWidget(
      _surface(SettingsScreen(downloadRepository: downloads)),
    );
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('settings-wifi-only'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect(downloads.value.wifiOnly, isTrue);

    downloads.failSaves = true;
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect(downloads.value.wifiOnly, isTrue);
    expect(find.textContaining('بقيت القيمة السابقة'), findsOneWidget);
  });

  testWidgets('handles ad privacy and notification-system failure safely', (
    tester,
  ) async {
    final privacy = _MemoryAdPrivacy(AdPrivacyOptionsStatus.required);
    await tester.pumpWidget(
      _surface(
        SettingsScreen(
          adPrivacyOptionsRepository: privacy,
          systemSettings: const _UnavailableSystemSettings(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final notification = find.byKey(const ValueKey('settings-notifications'));
    await tester.ensureVisible(notification);
    await tester.pumpAndSettle();
    await tester.tap(notification);
    await tester.pump();
    expect(find.textContaining('تعذر فتح إعدادات الإشعارات'), findsOneWidget);

    final privacyRow = find.byKey(const ValueKey('settings-ad-privacy'));
    await tester.ensureVisible(privacyRow);
    await tester.tap(privacyRow);
    await tester.pumpAndSettle();
    expect(privacy.presentations, 1);
  });

  testWidgets('hub remains readable at compact width and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_surface(const SettingsScreen(), textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('settings-hub-screen')), findsOneWidget);
  });
}

Widget _surface(Widget child, {double textScale = 1}) {
  final controller = _MemoryThemeController();
  return AppThemeControllerScope(
    controller: controller,
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    ),
  );
}

class _MemoryThemeController extends ChangeNotifier
    implements AppThemeController {
  AppThemeChoice _choice = AppThemeChoice.galaxyNoir;

  @override
  AppThemeChoice get value => _choice;

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppThemeChoice choice) async {
    _choice = choice;
    notifyListeners();
  }
}

class _MutableAuthRepository extends ValueNotifier<AuthSessionState>
    implements AuthRepository {
  _MutableAuthRepository(super.value);

  int restoreCalls = 0;

  @override
  Future<void> restoreSession() async {
    restoreCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryDownloadRepository extends ChangeNotifier
    implements DownloadRepository {
  _MemoryDownloadRepository(this._value);

  DownloadsDashboard _value;
  bool failSaves = false;

  @override
  DownloadsDashboard get value => _value;

  @override
  Future<void> setWifiOnly(bool enabled) async {
    if (failSaves) throw Exception('save failed');
    _value = DownloadsDashboard(
      allowance: _value.allowance,
      groups: _value.groups,
      novels: _value.novels,
      wifiOnly: enabled,
      totalBytes: _value.totalBytes,
      quotaBlockGeneration: _value.quotaBlockGeneration,
      isInitializing: _value.isInitializing,
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryAdPrivacy implements AdPrivacyOptionsRepository {
  _MemoryAdPrivacy(this.status);

  AdPrivacyOptionsStatus status;
  int presentations = 0;

  @override
  Future<AdPrivacyOptionsStatus> loadStatus() async => status;

  @override
  Future<AdPrivacyOptionsOutcome> show() async {
    presentations += 1;
    status = AdPrivacyOptionsStatus.notRequired;
    return AdPrivacyOptionsOutcome.shown;
  }
}

class _UnavailableSystemSettings extends AppSystemSettings {
  const _UnavailableSystemSettings();

  @override
  Future<bool> openNotificationSettings() async => false;
}

const _vipUser = AuthUser(
  id: 21,
  displayName: 'قارئ المجرة',
  avatar: null,
  vip: AuthVip(active: true, tier: 'vip2', label: 'VIP 2', expiresAt: null),
  xp: AuthXp(
    total: 100,
    today: 5,
    secondsTotal: 500,
    chaptersTotal: 10,
    rank: AuthRank(level: 2, display: 'مستكشف'),
  ),
);

const _dashboard = DownloadsDashboard(
  allowance: DownloadAllowance(
    plan: DownloadPlan(baseChapters: 100, maxRewardedAds: 4, rewardPerAd: 20),
    remaining: 90,
    adsRemaining: 4,
    shouldReset: false,
    effectiveDayOrdinal: 1,
  ),
  groups: [],
  novels: [
    DownloadedNovel(
      novelId: 1,
      title: 'رواية محمّلة',
      coverUrl: '',
      coverPath: '',
      totalBytes: 2048,
      chapters: [],
    ),
  ],
  wifiOnly: false,
  totalBytes: 2048,
  quotaBlockGeneration: 0,
  isInitializing: false,
);
