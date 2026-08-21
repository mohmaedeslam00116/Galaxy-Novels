import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_novels_app/features/reader/domain/reader_speech_models.dart';

void main() {
  test('legacy speech preferences use free safe defaults', () {
    final preferences = ReaderSpeechPreferences.fromJson(const {});

    expect(preferences.rate, 1);
    expect(preferences.autoNextChapter, isTrue);
    expect(preferences.engineId, isNull);
    expect(preferences.voiceName, isNull);
    expect(preferences.approvedNetworkVoiceIds, isEmpty);
  });

  test('speech preferences round trip and clamp rate boundaries', () {
    final preferences = ReaderSpeechPreferences.fromJson({
      'engine_id': 'com.example.tts',
      'voice_name': 'ar-eg-x-test',
      'voice_locale': 'ar-EG',
      'rate': 8,
      'auto_next_chapter': false,
      'approved_network_voice_ids': [
        'com.example.tts|ar-eg-x-test|ar-EG',
        'com.example.tts|ar-eg-x-test|ar-EG',
      ],
    });

    expect(preferences.rate, ReaderSpeechPreferences.maxRate);
    expect(preferences.autoNextChapter, isFalse);
    expect(preferences.approvedNetworkVoiceIds, [
      'com.example.tts|ar-eg-x-test|ar-EG',
    ]);
    expect(ReaderSpeechPreferences.fromJson(preferences.toJson()), preferences);
    expect(
      preferences.copyWith(rate: -2).rate,
      ReaderSpeechPreferences.minRate,
    );
  });

  test('speech checkpoint round trips its content identity and position', () {
    const checkpoint = ReaderSpeechCheckpoint(
      novelId: 91,
      chapterId: 312,
      contentApi: '/chapters/312',
      blockIndex: 7,
      characterOffset: 18,
      contentFingerprint: 'a31f90',
    );

    expect(ReaderSpeechCheckpoint.fromJson(checkpoint.toJson()), checkpoint);
  });

  test('offline Arabic voice wins by quality then latency', () {
    const voices = [
      ReaderSpeechVoice(
        engineId: 'engine',
        name: 'network-premium',
        locale: 'ar-EG',
        quality: 500,
        latency: 100,
        networkRequired: true,
      ),
      ReaderSpeechVoice(
        engineId: 'engine',
        name: 'offline-slow',
        locale: 'ar-SA',
        quality: 400,
        latency: 400,
        networkRequired: false,
      ),
      ReaderSpeechVoice(
        engineId: 'engine',
        name: 'offline-fast',
        locale: 'ar-XA',
        quality: 400,
        latency: 200,
        networkRequired: false,
      ),
      ReaderSpeechVoice(
        engineId: 'engine',
        name: 'english',
        locale: 'en-US',
        quality: 500,
        latency: 100,
        networkRequired: false,
      ),
    ];

    expect(selectPreferredArabicVoice(voices)?.name, 'offline-fast');
    expect(sortedArabicVoices(voices).map((voice) => voice.name), [
      'offline-fast',
      'offline-slow',
      'network-premium',
    ]);
  });

  test('unapproved saved network voice falls back to offline Arabic', () {
    const offline = ReaderSpeechVoice(
      engineId: 'engine',
      name: 'offline',
      locale: 'ar-SA',
      quality: 300,
      latency: 300,
      networkRequired: false,
    );
    const network = ReaderSpeechVoice(
      engineId: 'engine',
      name: 'network',
      locale: 'ar-EG',
      quality: 500,
      latency: 100,
      networkRequired: true,
    );
    final saved = ReaderSpeechPreferences.defaults.copyWith(
      engineId: network.engineId,
      voiceName: network.name,
      voiceLocale: network.locale,
    );

    expect(resolveReaderSpeechVoice(const [network, offline], saved), offline);
    expect(
      resolveReaderSpeechVoice(const [
        network,
        offline,
      ], saved.approveNetworkVoice(network.id)),
      network,
    );
  });

  test(
    'chapter content identity includes novel and normalized content API',
    () {
      const chapter = ReaderSpeechChapter(
        chapterId: 12,
        novelId: 8,
        contentApi: '/chapters/12/',
        novelTitle: 'novel',
        chapterTitle: 'chapter',
        coverUrl: '',
        previousContentApi: '',
        nextContentApi: '',
        blocks: [],
        contentFingerprint: 'fingerprint',
      );
      const sameContent = ReaderSpeechChapter(
        chapterId: 12,
        novelId: 8,
        contentApi: '/chapters/12',
        novelTitle: 'renamed novel',
        chapterTitle: 'renamed chapter',
        coverUrl: '',
        previousContentApi: '',
        nextContentApi: '',
        blocks: [],
        contentFingerprint: 'fingerprint',
      );
      const otherNovel = ReaderSpeechChapter(
        chapterId: 12,
        novelId: 9,
        contentApi: '/chapters/12',
        novelTitle: 'other novel',
        chapterTitle: 'chapter',
        coverUrl: '',
        previousContentApi: '',
        nextContentApi: '',
        blocks: [],
        contentFingerprint: 'fingerprint',
      );

      expect(chapter.hasSameContentIdentity(sameContent), isTrue);
      expect(chapter.hasSameContentIdentity(otherNovel), isFalse);
    },
  );
}
