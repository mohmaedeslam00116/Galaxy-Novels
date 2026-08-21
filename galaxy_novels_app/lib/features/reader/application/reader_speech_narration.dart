import 'dart:math' as math;

import '../../../data/models/reader_content_data.dart';
import '../data/chapter_html_parser.dart';
import '../domain/reader_advanced_terminology.dart';
import '../domain/reader_speech_models.dart';
import '../domain/reader_term_replacement.dart';
import '../domain/reader_text_transformer.dart';

class ReaderSpeechChapterRequest {
  const ReaderSpeechChapterRequest({
    required this.content,
    required this.contentApi,
    required this.novelTitle,
    required this.coverUrl,
    required this.personalReplacements,
    required this.advancedState,
  });

  final ReaderChapterContent content;
  final String contentApi;
  final String novelTitle;
  final String coverUrl;
  final List<ReaderTermReplacement> personalReplacements;
  final ReaderAdvancedTerminologyState advancedState;
}

ReaderSpeechChapter buildReaderSpeechChapter(
  ReaderSpeechChapterRequest request,
) {
  final blocks = _speechBlocks(request);
  return ReaderSpeechChapter(
    chapterId: request.content.id,
    novelId: request.content.novelId,
    contentApi: request.contentApi,
    novelTitle: request.novelTitle,
    chapterTitle: request.content.effectiveTitle,
    coverUrl: request.coverUrl,
    previousContentApi: request.content.navigation.previousApi,
    nextContentApi: request.content.navigation.nextApi,
    blocks: blocks,
    contentFingerprint: _contentFingerprint(blocks),
  );
}

List<ReaderSpeechBlock> _speechBlocks(ReaderSpeechChapterRequest request) {
  final parsed = parseChapterHtml(request.content.contentHtml);
  final speechBlocks = <ReaderSpeechBlock>[];
  for (var index = 0; index < parsed.length; index += 1) {
    final transformed = transformReaderText(
      text: parsed[index].text,
      novelId: request.content.novelId,
      personalReplacements: request.personalReplacements,
      advancedState: request.advancedState,
    );
    final speechText = _normalizedSpeechText(transformed.text);
    if (speechText.isEmpty) continue;
    speechBlocks.add(
      ReaderSpeechBlock(
        sourceIndex: index,
        kind: parsed[index].type == ChapterTextBlockType.heading
            ? ReaderSpeechBlockKind.heading
            : ReaderSpeechBlockKind.paragraph,
        text: speechText,
      ),
    );
  }
  return List.unmodifiable(speechBlocks);
}

List<ReaderSpeechChunk> splitReaderSpeechBlock(
  ReaderSpeechBlock block, {
  required int maxInputLength,
}) {
  if (maxInputLength <= 0) {
    throw ArgumentError.value(maxInputLength, 'maxInputLength');
  }
  final chunks = <ReaderSpeechChunk>[];
  var start = _skipWhitespace(block.text, 0);
  while (start < block.text.length) {
    final hardEnd = math.min(start + maxInputLength, block.text.length);
    final end = _chunkEnd(block.text, start, hardEnd);
    final textEnd = _trimTrailingWhitespace(block.text, start, end);
    if (textEnd > start) {
      chunks.add(
        ReaderSpeechChunk(
          sourceIndex: block.sourceIndex,
          start: start,
          end: textEnd,
          text: block.text.substring(start, textEnd),
        ),
      );
    }
    start = _skipWhitespace(block.text, end);
  }
  return List.unmodifiable(chunks);
}

int _chunkEnd(String text, int start, int hardEnd) {
  if (hardEnd == text.length) return hardEnd;
  final safeHardEnd = _surrogateSafeEnd(text, hardEnd);
  final sentenceEnd = _lastSentenceBoundary(text, start, safeHardEnd);
  if (sentenceEnd > start) return sentenceEnd;
  final whitespaceEnd = _lastWhitespace(text, start, safeHardEnd);
  return whitespaceEnd > start ? whitespaceEnd : safeHardEnd;
}

int _lastSentenceBoundary(String text, int start, int end) {
  for (var index = end - 1; index > start; index -= 1) {
    if (!_isWhitespace(text.codeUnitAt(index))) continue;
    final previous = _previousNonWhitespace(text, index - 1, start);
    if (previous >= start &&
        _isSentencePunctuation(text.codeUnitAt(previous))) {
      return index;
    }
  }
  return start;
}

int _lastWhitespace(String text, int start, int end) {
  for (var index = end - 1; index > start; index -= 1) {
    if (_isWhitespace(text.codeUnitAt(index))) return index;
  }
  return start;
}

int _surrogateSafeEnd(String text, int end) {
  if (end <= 0 || end >= text.length) return end;
  final previous = text.codeUnitAt(end - 1);
  final next = text.codeUnitAt(end);
  return _isHighSurrogate(previous) && _isLowSurrogate(next) ? end - 1 : end;
}

int _skipWhitespace(String text, int start) {
  var index = start;
  while (index < text.length && _isWhitespace(text.codeUnitAt(index))) {
    index += 1;
  }
  return index;
}

int _trimTrailingWhitespace(String text, int start, int end) {
  var index = end;
  while (index > start && _isWhitespace(text.codeUnitAt(index - 1))) {
    index -= 1;
  }
  return index;
}

int _previousNonWhitespace(String text, int start, int minimum) {
  var index = start;
  while (index >= minimum && _isWhitespace(text.codeUnitAt(index))) {
    index -= 1;
  }
  return index;
}

bool _isWhitespace(int codeUnit) =>
    codeUnit == 0x20 ||
    codeUnit == 0x09 ||
    codeUnit == 0x0A ||
    codeUnit == 0x0D;

bool _isSentencePunctuation(int codeUnit) =>
    codeUnit == 0x2E ||
    codeUnit == 0x21 ||
    codeUnit == 0x3F ||
    codeUnit == 0x61F ||
    codeUnit == 0x61B;

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;

String _normalizedSpeechText(String text) {
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _contentFingerprint(List<ReaderSpeechBlock> blocks) {
  var hash = 0xcbf29ce484222325;
  for (final block in blocks) {
    for (final codeUnit in '${block.kind.name}:${block.text}\n'.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
    }
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
