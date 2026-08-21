import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/app/app_theme.dart';
import 'package:galaxy_novels_app/core/network/app_cache_maintenance.dart';
import 'package:galaxy_novels_app/features/downloads/application/download_repository.dart';
import 'package:galaxy_novels_app/features/home/application/home_recommendation_exclusion_repository.dart';
import 'package:galaxy_novels_app/features/settings/presentation/data_management_screen.dart';

void main() {
  testWidgets(
    'shows scoped storage and clears only confirmed temporary cache',
    (tester) async {
      final cache = _MemoryCacheMaintenance(bytes: 2048);
      final exclusions = _MemoryExclusions({12, 44});
      await tester.pumpWidget(
        _surface(
          DataManagementScreen(
            cacheMaintenance: cache,
            downloadRepository: const NoopDownloadRepository(),
            exclusionRepository: exclusions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('2.0 ك.ب'), findsOneWidget);
      expect(find.textContaining('2 رواية'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('data-cache-row')));
      await tester.pumpAndSettle();
      expect(cache.clearCalls, 0);
      await tester.tap(find.text('مسح'));
      await tester.pumpAndSettle();

      expect(cache.clearCalls, 1);
      expect(find.text('تم مسح الملفات المؤقتة.'), findsOneWidget);
      expect(find.textContaining('لا توجد ملفات مؤقتة'), findsOneWidget);
    },
  );

  testWidgets('restores hidden recommendations only after confirmation', (
    tester,
  ) async {
    final exclusions = _MemoryExclusions({1, 2, 3});
    await tester.pumpWidget(
      _surface(
        DataManagementScreen(
          cacheMaintenance: _MemoryCacheMaintenance(),
          downloadRepository: const NoopDownloadRepository(),
          exclusionRepository: exclusions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('data-hidden-recommendations-row')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة'));
    await tester.pumpAndSettle();

    expect(exclusions.clearCalls, 1);
    expect(find.textContaining('لا توجد روايات مخفية'), findsOneWidget);
  });

  testWidgets('survives 200 percent text at compact width', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _surface(
        DataManagementScreen(
          cacheMaintenance: _MemoryCacheMaintenance(bytes: 900),
          downloadRepository: const NoopDownloadRepository(),
        ),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Widget _surface(Widget child, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

class _MemoryCacheMaintenance implements AppCacheMaintenance {
  _MemoryCacheMaintenance({this.bytes = 0});

  int bytes;
  int clearCalls = 0;

  @override
  Future<int> cacheSizeBytes() async => bytes;

  @override
  Future<void> clearTemporaryCache() async {
    clearCalls += 1;
    bytes = 0;
  }
}

class _MemoryExclusions extends ChangeNotifier
    implements HomeRecommendationExclusionRepository {
  _MemoryExclusions(Set<int> ids) : _ids = ids;

  Set<int> _ids;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls += 1;
    _ids = {};
    notifyListeners();
  }

  @override
  Future<void> hide(int novelId) async {
    _ids.add(novelId);
    notifyListeners();
  }

  @override
  Future<Set<int>> load() async => Set.of(_ids);

  @override
  Future<void> restore(int novelId) async {
    _ids.remove(novelId);
    notifyListeners();
  }
}
