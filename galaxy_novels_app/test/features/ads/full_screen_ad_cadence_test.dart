import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/ads/application/full_screen_ad_cadence.dart';
import 'package:galaxy_novels_app/features/ads/domain/reader_interstitial_policy.dart';

void main() {
  test(
    'first app-open ad becomes due after the first three launches',
    () async {
      var now = DateTime.utc(2026, 7, 21, 10);
      final cadence = FullScreenAdCadence(
        store: _MemoryCadenceStore(),
        now: () => now,
      );

      expect(await cadence.registerColdLaunchAndIsAppOpenDue(), isFalse);
      expect(await cadence.registerColdLaunchAndIsAppOpenDue(), isFalse);
      expect(await cadence.registerColdLaunchAndIsAppOpenDue(), isFalse);
      expect(await cadence.registerColdLaunchAndIsAppOpenDue(), isTrue);

      await cadence.markAppOpenShown();
      now = now.add(const Duration(hours: 3, minutes: 59));
      expect(await cadence.isForegroundAppOpenDue(), isFalse);
      now = now.add(const Duration(minutes: 1));
      expect(await cadence.isForegroundAppOpenDue(), isTrue);
    },
  );

  test(
    'browse interstitial becomes due on the fifth novel details open',
    () async {
      final cadence = FullScreenAdCadence(store: _MemoryCadenceStore());

      for (var open = 1; open <= 3; open++) {
        final decision = await cadence.registerNovelDetailsOpen();
        expect(decision.isDue, isFalse);
        expect(decision.shouldPreload, isFalse);
      }

      final preloadDecision = await cadence.registerNovelDetailsOpen();
      expect(preloadDecision.isDue, isFalse);
      expect(preloadDecision.shouldPreload, isTrue);

      final dueDecision = await cadence.registerNovelDetailsOpen();
      expect(dueDecision.isDue, isTrue);
      expect(dueDecision.opensSinceLastBrowseAd, 5);
    },
  );

  test(
    'browse interstitial respects five minute full-screen spacing',
    () async {
      var now = DateTime.utc(2026, 8, 10, 12);
      final cadence = FullScreenAdCadence(
        store: _MemoryCadenceStore(),
        now: () => now,
      );

      for (var open = 0; open < 5; open++) {
        await cadence.registerNovelDetailsOpen();
      }
      await cadence.markBrowseInterstitialShown();

      for (var open = 0; open < 5; open++) {
        await cadence.registerNovelDetailsOpen();
      }
      expect((await cadence.peekBrowseInterstitialDecision()).isDue, isFalse);

      now = now.add(const Duration(minutes: 5));
      expect((await cadence.peekBrowseInterstitialDecision()).isDue, isTrue);
    },
  );

  test('app-open marks shared full-screen spacing for browse ads', () async {
    var now = DateTime.utc(2026, 8, 10, 12);
    final cadence = FullScreenAdCadence(
      store: _MemoryCadenceStore(),
      now: () => now,
    );

    for (var open = 0; open < 5; open++) {
      await cadence.registerNovelDetailsOpen();
    }
    await cadence.markAppOpenShown();
    expect((await cadence.peekBrowseInterstitialDecision()).isDue, isFalse);

    now = now.add(const Duration(minutes: 5));
    expect((await cadence.peekBrowseInterstitialDecision()).isDue, isTrue);
  });

  test(
    'reader cadence selects an inclusive target and preloads two chapters ahead',
    () async {
      final cadence = FullScreenAdCadence(
        store: _MemoryCadenceStore(),
        readerTargetPicker: (minimum, maximum) {
          expect(minimum, 5);
          expect(maximum, 20);
          return 5;
        },
      );

      final first = await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      expect(first.transitionsSinceLastAd, 1);
      expect(first.targetTransitions, 5);
      expect(first.shouldPreload, isFalse);
      expect(first.isDue, isFalse);

      await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      final preload = await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      expect(preload.transitionsSinceLastAd, 3);
      expect(preload.shouldPreload, isTrue);
      expect(preload.isDue, isFalse);

      await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      final due = await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      expect(due.isDue, isTrue);
      expect(due.blockedByFullScreenSpacing, isFalse);
    },
  );

  test(
    'reader cadence keeps its target until an ad is actually shown',
    () async {
      var pickedTarget = 5;
      final store = _MemoryCadenceStore();
      final cadence = FullScreenAdCadence(
        store: store,
        readerTargetPicker: (_, _) => pickedTarget,
      );

      for (var transition = 0; transition < 5; transition++) {
        await cadence.registerReaderForwardTransition(
          ReaderInterstitialPolicy.defaults,
        );
      }
      await cadence.deferReaderInterstitial();
      expect(store.state.readerInterstitialTarget, 5);
      expect(store.state.readerInterstitialRetryAtTransition, 7);

      final sixth = await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      expect(sixth.isDue, isFalse);
      final seventh = await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
      expect(seventh.isDue, isTrue);
      expect(seventh.targetTransitions, 7);

      pickedTarget = 20;
      await cadence.markReaderInterstitialShown(
        ReaderInterstitialPolicy.defaults,
      );
      expect(store.state.readerForwardTransitionsSinceInterstitial, 0);
      expect(store.state.readerInterstitialTarget, 20);
      expect(store.state.readerInterstitialRetryAtTransition, 0);
    },
  );

  test(
    'disabled reader policy pauses cadence without changing its cycle',
    () async {
      final store = _MemoryCadenceStore(
        const FullScreenAdCadenceState(
          readerForwardTransitionsSinceInterstitial: 3,
          readerInterstitialTarget: 8,
        ),
      );
      final cadence = FullScreenAdCadence(store: store);

      final decision = await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults.copyWith(enabled: false),
      );

      expect(decision.enabled, isFalse);
      expect(store.state.readerForwardTransitionsSinceInterstitial, 3);
      expect(store.state.readerInterstitialTarget, 8);
    },
  );

  test('reader cadence shares full-screen spacing with app-open ads', () async {
    var now = DateTime.utc(2026, 8, 10, 12);
    final cadence = FullScreenAdCadence(
      store: _MemoryCadenceStore(),
      now: () => now,
      readerTargetPicker: (_, _) => 5,
    );

    for (var transition = 0; transition < 4; transition++) {
      await cadence.registerReaderForwardTransition(
        ReaderInterstitialPolicy.defaults,
      );
    }
    await cadence.markAppOpenShown();
    final blocked = await cadence.registerReaderForwardTransition(
      ReaderInterstitialPolicy.defaults,
    );
    expect(blocked.thresholdReached, isTrue);
    expect(blocked.isDue, isFalse);
    expect(blocked.blockedByFullScreenSpacing, isTrue);

    now = now.add(const Duration(minutes: 5));
    final due = await cadence.peekReaderInterstitialDecision(
      ReaderInterstitialPolicy.defaults,
    );
    expect(due.isDue, isTrue);
  });
}

class _MemoryCadenceStore implements FullScreenAdCadenceStore {
  _MemoryCadenceStore([this.state = const FullScreenAdCadenceState()]);

  FullScreenAdCadenceState state;

  @override
  Future<FullScreenAdCadenceState> read() async => state;

  @override
  Future<void> write(FullScreenAdCadenceState state) async {
    this.state = state;
  }
}
