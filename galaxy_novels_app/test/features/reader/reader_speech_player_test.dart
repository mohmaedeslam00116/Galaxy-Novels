import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/application/reader_speech_controller.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';
import 'package:galaxy_novels_app/features/reader/presentation/reader_speech_player.dart';

void main() {
  testWidgets('mini player exposes chapter and playback controls', (
    tester,
  ) async {
    final controller = _FakeSpeechController(
      ReaderSpeechState(
        status: ReaderSpeechStatus.paused,
        chapter: _chapter,
        blockIndex: 0,
        characterStart: 0,
        characterEnd: 0,
        errorMessage: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderSpeechMiniPlayer(controller: controller, onExpand: () {}),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('reader-speech-mini-player')), findsOne);
    expect(find.text('الفصل الصوتي'), findsOne);
    expect(find.byTooltip('تشغيل القراءة الصوتية'), findsOne);

    await tester.tap(find.byTooltip('تشغيل القراءة الصوتية'));
    await tester.pump();

    expect(controller.playCalls, 1);
  });

  testWidgets('expanded player exposes rate, auto-next and voice management', (
    tester,
  ) async {
    final controller = _FakeSpeechController(
      ReaderSpeechState(
        status: ReaderSpeechStatus.paused,
        chapter: _chapter,
        blockIndex: 0,
        characterStart: 0,
        characterEnd: 0,
        errorMessage: null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderSpeechPanel(
            controller: controller,
            onManageVoices: () async => true,
          ),
        ),
      ),
    );

    expect(find.textContaining('سرعة القراءة'), findsOne);
    expect(find.text('الانتقال تلقائيًا للفصل التالي'), findsOne);
    expect(find.text('إدارة أصوات الجهاز'), findsOne);
    expect(find.text('مؤقت النوم'), findsOne);
  });

  testWidgets('expanded player displays a saved voice fallback notice', (
    tester,
  ) async {
    final controller = _FakeSpeechController(
      ReaderSpeechState(
        status: ReaderSpeechStatus.paused,
        chapter: _chapter,
        blockIndex: 0,
        characterStart: 0,
        characterEnd: 0,
        errorMessage: null,
        noticeMessage: 'تم اختيار صوت عربي بديل.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReaderSpeechPanel(controller: controller)),
      ),
    );

    expect(find.byKey(const ValueKey('reader-speech-voice-notice')), findsOne);
    expect(find.text('تم اختيار صوت عربي بديل.'), findsOne);
  });
}

const _chapter = ReaderSpeechChapter(
  chapterId: 2,
  novelId: 1,
  contentApi: '/chapters/2',
  novelTitle: 'رواية الاختبار',
  chapterTitle: 'الفصل الصوتي',
  coverUrl: '',
  previousContentApi: '/chapters/1',
  nextContentApi: '/chapters/3',
  blocks: [
    ReaderSpeechBlock(
      sourceIndex: 0,
      kind: ReaderSpeechBlockKind.paragraph,
      text: 'نص الفقرة',
    ),
  ],
  contentFingerprint: 'fingerprint',
);

class _FakeSpeechController extends ChangeNotifier
    implements ReaderSpeechController {
  _FakeSpeechController(this._value);

  ReaderSpeechState _value;
  int playCalls = 0;

  @override
  ReaderSpeechState get value => _value;

  @override
  ReaderSpeechPreferences get preferences => ReaderSpeechPreferences.defaults;

  @override
  List<ReaderSpeechVoice> get availableVoices => const [];

  @override
  ReaderSpeechSleepTimer get sleepTimer => ReaderSpeechSleepTimer.off;

  @override
  DateTime? get sleepTimerEndsAt => null;

  @override
  Future<void> play() async {
    playCalls += 1;
    _value = _value.copyWith(status: ReaderSpeechStatus.playing);
    notifyListeners();
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> prepareChapter(
    ReaderSpeechChapter chapter, {
    int? visibleBlockIndex,
  }) async {}

  @override
  Future<void> previewVoice(ReaderSpeechVoice voice) async {}

  @override
  Future<void> setSleepTimer(ReaderSpeechSleepTimer timer) async {}

  @override
  Future<void> skipNextBlock() async {}

  @override
  Future<void> skipPreviousBlock() async {}

  @override
  Future<void> startFromBlock(int blockIndex) async {}

  @override
  Future<void> updatePreferences(ReaderSpeechPreferences preferences) async {}

  @override
  void bindChapterSource(ReaderSpeechChapterSource source) {}
}
