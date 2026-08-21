import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/novel_details_transition.dart';
import 'package:galaxy_novels_app/features/novel_details/presentation/widgets/novel_details_content.dart';
import 'package:galaxy_novels_app/shared/widgets/novel_cover.dart';

void main() {
  testWidgets('details loading state keeps the incoming cover Hero', (
    tester,
  ) async {
    const transition = NovelDetailsTransitionData(
      heroTag: 'home-cover:updatedNovels:7',
      title: 'رواية انتقالية',
      coverUrl: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: NovelDetailsSkeleton(transition: transition)),
      ),
    );

    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, transition.heroTag);
    expect(find.byType(NovelCover), findsOneWidget);
  });

  testWidgets('ordinary details loading keeps the plain skeleton', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NovelDetailsSkeleton())),
    );

    expect(find.byType(Hero), findsNothing);
    expect(find.byType(NovelCover), findsNothing);
  });
}
