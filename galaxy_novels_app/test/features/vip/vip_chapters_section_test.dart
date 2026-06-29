import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_chapters_controller.dart';
import 'package:galaxy_novels_app/features/vip/application/vip_repository.dart';
import 'package:galaxy_novels_app/features/vip/domain/vip_chapter.dart';
import 'package:galaxy_novels_app/features/vip/presentation/vip_chapters_section.dart';

void main() {
  testWidgets(
    'shows a VIP access message when private reading is unavailable',
    (tester) async {
      var openedAccount = false;
      final controller = VipChaptersController(
        repository: _FakeVipRepository(),
        novelId: 1,
      );

      await tester.pumpWidget(
        _wrap(
          VipChaptersSection(
            controller: controller,
            canReadPrivate: false,
            nativeReaderAvailable: false,
            onSignIn: () => openedAccount = true,
            onOpenVipChapter: (_, _) {},
          ),
        ),
      );

      expect(find.text('فصول VIP'), findsOneWidget);
      expect(find.textContaining('متاحة للمشتركين فقط'), findsOneWidget);

      await tester.tap(find.text('حسابي'));
      expect(openedAccount, isTrue);
    },
  );

  testWidgets('keeps VIP row taps guarded when native route is unavailable', (
    tester,
  ) async {
    String? openedPath;
    final controller = VipChaptersController(
      repository: _FakeVipRepository(),
      novelId: 1,
    );

    await tester.pumpWidget(
      _wrap(
        VipChaptersSection(
          controller: controller,
          canReadPrivate: true,
          nativeReaderAvailable: false,
          onSignIn: () {},
          onOpenVipChapter: (path, _) => openedPath = path,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('فصول VIP الخاصة'), findsOneWidget);
    expect(find.text('الفصل 1'), findsOneWidget);

    await tester.tap(find.text('الفصل 1'));
    await tester.pump();

    expect(openedPath, isNull);
    expect(find.textContaining('تنتظر تحديث السيرفر'), findsOneWidget);
  });

  testWidgets('opens a VIP chapter through an internal vip path when enabled', (
    tester,
  ) async {
    String? openedPath;
    final controller = VipChaptersController(
      repository: _FakeVipRepository(),
      novelId: 1,
    );

    await tester.pumpWidget(
      _wrap(
        VipChaptersSection(
          controller: controller,
          canReadPrivate: true,
          nativeReaderAvailable: true,
          onSignIn: () {},
          onOpenVipChapter: (path, _) => openedPath = path,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الفصل 1'));

    expect(openedPath, 'vip:chapter:1');
  });

  testWidgets('opens a server-provided VIP content_api when present', (
    tester,
  ) async {
    String? openedPath;
    final controller = VipChaptersController(
      repository: _FakeVipRepository(
        contentApi: '/wp-json/wor-reader-app/v1/vip/chapters/1',
      ),
      novelId: 1,
    );

    await tester.pumpWidget(
      _wrap(
        VipChaptersSection(
          controller: controller,
          canReadPrivate: true,
          nativeReaderAvailable: false,
          onSignIn: () {},
          onOpenVipChapter: (path, _) => openedPath = path,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الفصل 1'));

    expect(openedPath, '/wp-json/wor-reader-app/v1/vip/chapters/1');
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(body: CustomScrollView(slivers: [child])),
    ),
  );
}

class _FakeVipRepository implements VipRepository {
  const _FakeVipRepository({this.contentApi = ''});

  final String contentApi;

  @override
  Future<VipChapterPage> loadChapters(VipChapterQuery query) async {
    return VipChapterPage(
      items: [
        VipChapter(
          id: 1,
          number: '1',
          position: 1,
          order: '1.000000',
          title: 'فصل خاص',
          url: '',
          publicAt: '',
          views: 0,
          comments: 0,
          contentApi: contentApi,
        ),
      ],
      hasMore: false,
      nextCursorOrder: '',
      nextCursorId: 0,
      totalAvailable: 1,
    );
  }
}
