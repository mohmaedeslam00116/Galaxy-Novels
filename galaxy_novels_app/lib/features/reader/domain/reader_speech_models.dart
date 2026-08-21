import 'package:flutter/foundation.dart';

enum ReaderSpeechStatus { idle, loading, playing, paused, error }

enum ReaderSpeechBlockKind { heading, paragraph }

enum ReaderSpeechSleepTimer {
  off,
  minutes15,
  minutes30,
  minutes60,
  endOfChapter,
}

class ReaderSpeechPreferences {
  const ReaderSpeechPreferences({
    required this.engineId,
    required this.voiceName,
    required this.voiceLocale,
    required this.rate,
    required this.autoNextChapter,
    required this.approvedNetworkVoiceIds,
  });

  static const minRate = 0.5;
  static const maxRate = 2.0;

  static const defaults = ReaderSpeechPreferences(
    engineId: null,
    voiceName: null,
    voiceLocale: null,
    rate: 1,
    autoNextChapter: true,
    approvedNetworkVoiceIds: [],
  );

  final String? engineId;
  final String? voiceName;
  final String? voiceLocale;
  final double rate;
  final bool autoNextChapter;
  final List<String> approvedNetworkVoiceIds;

  factory ReaderSpeechPreferences.fromJson(Map<String, dynamic> json) {
    return ReaderSpeechPreferences(
      engineId: _nullableText(json['engine_id']),
      voiceName: _nullableText(json['voice_name']),
      voiceLocale: _nullableText(json['voice_locale']),
      rate: _boundedRate(_doubleValue(json['rate']) ?? defaults.rate),
      autoNextChapter: json['auto_next_chapter'] != false,
      approvedNetworkVoiceIds: _uniqueStrings(
        json['approved_network_voice_ids'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'engine_id': engineId,
    'voice_name': voiceName,
    'voice_locale': voiceLocale,
    'rate': rate,
    'auto_next_chapter': autoNextChapter,
    'approved_network_voice_ids': approvedNetworkVoiceIds,
  };

  ReaderSpeechPreferences copyWith({
    String? engineId,
    String? voiceName,
    String? voiceLocale,
    double? rate,
    bool? autoNextChapter,
    List<String>? approvedNetworkVoiceIds,
  }) {
    return ReaderSpeechPreferences(
      engineId: engineId ?? this.engineId,
      voiceName: voiceName ?? this.voiceName,
      voiceLocale: voiceLocale ?? this.voiceLocale,
      rate: _boundedRate(rate ?? this.rate),
      autoNextChapter: autoNextChapter ?? this.autoNextChapter,
      approvedNetworkVoiceIds: List.unmodifiable(
        approvedNetworkVoiceIds ?? this.approvedNetworkVoiceIds,
      ),
    );
  }

  ReaderSpeechPreferences approveNetworkVoice(String voiceId) {
    final approvals = {...approvedNetworkVoiceIds, voiceId}.toList()..sort();
    return copyWith(approvedNetworkVoiceIds: approvals);
  }

  ReaderSpeechPreferences clearVoice() {
    return ReaderSpeechPreferences(
      engineId: null,
      voiceName: null,
      voiceLocale: null,
      rate: rate,
      autoNextChapter: autoNextChapter,
      approvedNetworkVoiceIds: approvedNetworkVoiceIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderSpeechPreferences &&
        other.engineId == engineId &&
        other.voiceName == voiceName &&
        other.voiceLocale == voiceLocale &&
        other.rate == rate &&
        other.autoNextChapter == autoNextChapter &&
        listEquals(other.approvedNetworkVoiceIds, approvedNetworkVoiceIds);
  }

  @override
  int get hashCode => Object.hash(
    engineId,
    voiceName,
    voiceLocale,
    rate,
    autoNextChapter,
    Object.hashAll(approvedNetworkVoiceIds),
  );
}

class ReaderSpeechCheckpoint {
  const ReaderSpeechCheckpoint({
    required this.novelId,
    required this.chapterId,
    required this.contentApi,
    required this.blockIndex,
    required this.characterOffset,
    required this.contentFingerprint,
    this.novelTitle = '',
    this.chapterTitle = '',
    this.coverUrl = '',
  });

  final int novelId;
  final int chapterId;
  final String contentApi;
  final int blockIndex;
  final int characterOffset;
  final String contentFingerprint;
  final String novelTitle;
  final String chapterTitle;
  final String coverUrl;

  factory ReaderSpeechCheckpoint.fromJson(Map<String, dynamic> json) {
    return ReaderSpeechCheckpoint(
      novelId: _intValue(json['novel_id']),
      chapterId: _intValue(json['chapter_id']),
      contentApi: json['content_api']?.toString() ?? '',
      blockIndex: _intValue(json['block_index']),
      characterOffset: _intValue(json['character_offset']),
      contentFingerprint: json['content_fingerprint']?.toString() ?? '',
      novelTitle: json['novel_title']?.toString() ?? '',
      chapterTitle: json['chapter_title']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'novel_id': novelId,
    'chapter_id': chapterId,
    'content_api': contentApi,
    'block_index': blockIndex,
    'character_offset': characterOffset,
    'content_fingerprint': contentFingerprint,
    'novel_title': novelTitle,
    'chapter_title': chapterTitle,
    'cover_url': coverUrl,
  };

  @override
  bool operator ==(Object other) {
    return other is ReaderSpeechCheckpoint &&
        other.novelId == novelId &&
        other.chapterId == chapterId &&
        other.contentApi == contentApi &&
        other.blockIndex == blockIndex &&
        other.characterOffset == characterOffset &&
        other.contentFingerprint == contentFingerprint &&
        other.novelTitle == novelTitle &&
        other.chapterTitle == chapterTitle &&
        other.coverUrl == coverUrl;
  }

  @override
  int get hashCode => Object.hash(
    novelId,
    chapterId,
    contentApi,
    blockIndex,
    characterOffset,
    contentFingerprint,
    novelTitle,
    chapterTitle,
    coverUrl,
  );
}

class ReaderSpeechVoice {
  const ReaderSpeechVoice({
    required this.engineId,
    required this.name,
    required this.locale,
    required this.quality,
    required this.latency,
    required this.networkRequired,
  });

  final String engineId;
  final String name;
  final String locale;
  final int quality;
  final int latency;
  final bool networkRequired;

  String get id => '$engineId|$name|$locale';
  bool get isArabic => locale.toLowerCase().startsWith('ar');

  @override
  bool operator ==(Object other) {
    return other is ReaderSpeechVoice &&
        other.engineId == engineId &&
        other.name == name &&
        other.locale == locale &&
        other.quality == quality &&
        other.latency == latency &&
        other.networkRequired == networkRequired;
  }

  @override
  int get hashCode =>
      Object.hash(engineId, name, locale, quality, latency, networkRequired);
}

class ReaderSpeechBlock {
  const ReaderSpeechBlock({
    required this.sourceIndex,
    required this.kind,
    required this.text,
  });

  final int sourceIndex;
  final ReaderSpeechBlockKind kind;
  final String text;
}

class ReaderSpeechChunk {
  const ReaderSpeechChunk({
    required this.sourceIndex,
    required this.start,
    required this.end,
    required this.text,
  });

  final int sourceIndex;
  final int start;
  final int end;
  final String text;
}

class ReaderSpeechChapter {
  const ReaderSpeechChapter({
    required this.chapterId,
    required this.novelId,
    required this.contentApi,
    required this.novelTitle,
    required this.chapterTitle,
    required this.coverUrl,
    required this.previousContentApi,
    required this.nextContentApi,
    required this.blocks,
    required this.contentFingerprint,
  });

  final int chapterId;
  final int novelId;
  final String contentApi;
  final String novelTitle;
  final String chapterTitle;
  final String coverUrl;
  final String previousContentApi;
  final String nextContentApi;
  final List<ReaderSpeechBlock> blocks;
  final String contentFingerprint;

  bool hasSameContentIdentity(ReaderSpeechChapter other) {
    return novelId == other.novelId &&
        chapterId == other.chapterId &&
        _normalizedContentApi(contentApi) ==
            _normalizedContentApi(other.contentApi) &&
        contentFingerprint == other.contentFingerprint;
  }
}

String _normalizedContentApi(String value) {
  final trimmed = value.trim();
  if (trimmed.length > 1 && trimmed.endsWith('/')) {
    return trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

class ReaderSpeechState {
  const ReaderSpeechState({
    required this.status,
    required this.chapter,
    required this.blockIndex,
    required this.characterStart,
    required this.characterEnd,
    required this.errorMessage,
    this.noticeMessage,
  });

  static const idle = ReaderSpeechState(
    status: ReaderSpeechStatus.idle,
    chapter: null,
    blockIndex: 0,
    characterStart: 0,
    characterEnd: 0,
    errorMessage: null,
    noticeMessage: null,
  );

  final ReaderSpeechStatus status;
  final ReaderSpeechChapter? chapter;
  final int blockIndex;
  final int characterStart;
  final int characterEnd;
  final String? errorMessage;
  final String? noticeMessage;

  bool get isActive =>
      status == ReaderSpeechStatus.playing ||
      status == ReaderSpeechStatus.paused ||
      status == ReaderSpeechStatus.loading;

  bool get suspendsAutoScroll =>
      status == ReaderSpeechStatus.playing ||
      status == ReaderSpeechStatus.loading;

  ReaderSpeechState copyWith({
    ReaderSpeechStatus? status,
    ReaderSpeechChapter? chapter,
    int? blockIndex,
    int? characterStart,
    int? characterEnd,
    String? errorMessage,
    String? noticeMessage,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return ReaderSpeechState(
      status: status ?? this.status,
      chapter: chapter ?? this.chapter,
      blockIndex: blockIndex ?? this.blockIndex,
      characterStart: characterStart ?? this.characterStart,
      characterEnd: characterEnd ?? this.characterEnd,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
    );
  }
}

List<ReaderSpeechVoice> sortedArabicVoices(Iterable<ReaderSpeechVoice> voices) {
  final arabic = voices.where((voice) => voice.isArabic).toList();
  arabic.sort(_compareVoices);
  return List.unmodifiable(arabic);
}

ReaderSpeechVoice? selectPreferredArabicVoice(
  Iterable<ReaderSpeechVoice> voices,
) {
  final offline = sortedArabicVoices(
    voices.where((voice) => !voice.networkRequired),
  );
  return offline.isEmpty ? null : offline.first;
}

ReaderSpeechVoice? resolveReaderSpeechVoice(
  Iterable<ReaderSpeechVoice> voices,
  ReaderSpeechPreferences preferences,
) {
  final available = voices.toList();
  final saved = available.where((voice) {
    return voice.engineId == preferences.engineId &&
        voice.name == preferences.voiceName &&
        voice.locale == preferences.voiceLocale;
  }).firstOrNull;
  if (saved != null &&
      (!saved.networkRequired ||
          preferences.approvedNetworkVoiceIds.contains(saved.id))) {
    return saved;
  }
  return selectPreferredArabicVoice(available);
}

int _compareVoices(ReaderSpeechVoice first, ReaderSpeechVoice second) {
  final networkOrder = _boolOrder(
    first.networkRequired,
    second.networkRequired,
  );
  if (networkOrder != 0) return networkOrder;
  final qualityOrder = second.quality.compareTo(first.quality);
  if (qualityOrder != 0) return qualityOrder;
  final latencyOrder = first.latency.compareTo(second.latency);
  return latencyOrder != 0 ? latencyOrder : first.name.compareTo(second.name);
}

int _boolOrder(bool first, bool second) {
  if (first == second) return 0;
  return first ? 1 : -1;
}

double _boundedRate(double rate) {
  return rate
      .clamp(ReaderSpeechPreferences.minRate, ReaderSpeechPreferences.maxRate)
      .toDouble();
}

double? _doubleValue(Object? rawValue) {
  if (rawValue is num) return rawValue.toDouble();
  return double.tryParse(rawValue?.toString() ?? '');
}

int _intValue(Object? rawValue) {
  if (rawValue is num) return rawValue.toInt();
  return int.tryParse(rawValue?.toString() ?? '') ?? 0;
}

String? _nullableText(Object? rawValue) {
  final text = rawValue?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _uniqueStrings(Object? rawValues) {
  if (rawValues is! List) return const [];
  final unique =
      rawValues
          .map((rawValue) => rawValue.toString().trim())
          .where((text) => text.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return List.unmodifiable(unique);
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
