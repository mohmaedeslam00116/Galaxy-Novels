import 'reader_advanced_terminology.dart';
import 'reader_term_replacement.dart';

class ReaderTextTransformResult {
  const ReaderTextTransformResult(this.segments);

  final List<ReaderTermTextSegment> segments;

  String get text => segments.map((segment) => segment.text).join();
  bool get isEmpty => text.trim().isEmpty;
}

ReaderTextTransformResult transformReaderText({
  required String text,
  required int novelId,
  required List<ReaderTermReplacement> personalReplacements,
  required ReaderAdvancedTerminologyState advancedState,
}) {
  if (text.isEmpty) return const ReaderTextTransformResult([]);
  if (!advancedState.accessUnlocked) {
    return ReaderTextTransformResult(
      segmentReaderTermReplacements(text, personalReplacements, novelId),
    );
  }

  var workingText = text;
  final personalRemovals = advancedState.personalRemovals
      .where((rule) => rule.appliesToNovel(novelId))
      .map((rule) => _RemovalPattern(rule.source, boundaryAware: true));
  final pack = advancedState.transformationsEnabled ? advancedState.pack : null;
  final packRemovals = <_RemovalPattern>[];
  if (pack != null && advancedState.features.guardRemoval) {
    for (final source in pack.guardSentences) {
      if (advancedState.disabledGuardSentences.contains(source)) continue;
      packRemovals.add(
        _RemovalPattern(
          advancedState.guardOverrides[source] ?? source,
          boundaryAware: false,
        ),
      );
    }
  }
  if (pack != null &&
      advancedState.features.footerRemoval &&
      pack.footerText.isNotEmpty) {
    packRemovals.add(_RemovalPattern(pack.footerText, boundaryAware: false));
  }
  workingText = _removePatterns(workingText, [
    ...personalRemovals,
    ...packRemovals,
  ]);
  if (workingText.isEmpty) return const ReaderTextTransformResult([]);

  final replacements = <String, String>{};
  if (pack != null && advancedState.features.replacements) {
    for (final rule in pack.replacements) {
      if (advancedState.disabledReplacementSources.contains(rule.source)) {
        continue;
      }
      replacements[rule.source] =
          advancedState.replacementOverrides[rule.source] ?? rule.replacement;
    }
  }
  for (final rule in personalReplacements) {
    if (rule.scope == ReaderTermScope.allNovels) {
      replacements[rule.source] = rule.replacement;
    }
  }
  for (final rule in personalReplacements) {
    if (rule.scope == ReaderTermScope.currentNovel &&
        rule.appliesToNovel(novelId)) {
      replacements[rule.source] = rule.replacement;
    }
  }
  if (replacements.isEmpty) {
    return ReaderTextTransformResult([
      ReaderTermTextSegment(text: workingText, isReplacement: false),
    ]);
  }

  final exceptions = <String>{...advancedState.personalExceptions};
  if (pack != null && advancedState.features.replacements) {
    for (final source in pack.exceptions) {
      if (advancedState.disabledExceptions.contains(source)) continue;
      exceptions.add(advancedState.exceptionOverrides[source] ?? source);
    }
  }
  final protectedRanges = _protectedRanges(workingText, exceptions);
  final rules = replacements.entries.toList()
    ..sort((first, second) => second.key.length.compareTo(first.key.length));
  final segments = <ReaderTermTextSegment>[];
  var plain = StringBuffer();
  var offset = 0;
  while (offset < workingText.length) {
    MapEntry<String, String>? match;
    for (final candidate in rules) {
      if (!_matchesAt(workingText, offset, candidate.key)) continue;
      final end = offset + candidate.key.length;
      if (_overlapsProtected(offset, end, protectedRanges)) continue;
      match = candidate;
      break;
    }
    if (match == null) {
      plain.writeCharCode(workingText.codeUnitAt(offset));
      offset += 1;
      continue;
    }
    if (plain.isNotEmpty) {
      segments.add(
        ReaderTermTextSegment(text: plain.toString(), isReplacement: false),
      );
      plain = StringBuffer();
    }
    segments.add(ReaderTermTextSegment(text: match.value, isReplacement: true));
    offset += match.key.length;
  }
  if (plain.isNotEmpty) {
    segments.add(
      ReaderTermTextSegment(text: plain.toString(), isReplacement: false),
    );
  }
  return ReaderTextTransformResult(List.unmodifiable(segments));
}

class _RemovalPattern {
  const _RemovalPattern(this.source, {required this.boundaryAware});

  final String source;
  final bool boundaryAware;
}

String _removePatterns(String text, Iterable<_RemovalPattern> patterns) {
  final sorted = patterns.where((entry) => entry.source.isNotEmpty).toList()
    ..sort(
      (first, second) => second.source.length.compareTo(first.source.length),
    );
  if (sorted.isEmpty) return text;
  final output = StringBuffer();
  var offset = 0;
  while (offset < text.length) {
    _RemovalPattern? match;
    for (final candidate in sorted) {
      final matched = candidate.boundaryAware
          ? _matchesAt(text, offset, candidate.source)
          : _startsWithForMatching(text, offset, candidate.source);
      if (matched) {
        match = candidate;
        break;
      }
    }
    if (match == null) {
      output.writeCharCode(text.codeUnitAt(offset));
      offset += 1;
    } else {
      offset += match.source.length;
    }
  }
  return output
      .toString()
      .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
      .replaceAll(RegExp(r'\s+([،,.!?؟:؛])'), r'$1')
      .trim();
}

List<({int start, int end})> _protectedRanges(
  String text,
  Iterable<String> exceptions,
) {
  final ranges = <({int start, int end})>[];
  final normalizedText = _normalizedForMatching(text);
  for (final phrase in exceptions.where((value) => value.isNotEmpty)) {
    var offset = 0;
    while (offset < text.length) {
      final match = normalizedText.indexOf(
        _normalizedForMatching(phrase),
        offset,
      );
      if (match < 0) break;
      ranges.add((start: match, end: match + phrase.length));
      offset = match + phrase.length;
    }
  }
  return ranges;
}

bool _overlapsProtected(
  int start,
  int end,
  List<({int start, int end})> ranges,
) {
  return ranges.any((range) => start < range.end && end > range.start);
}

bool _matchesAt(String text, int offset, String source) {
  if (!_startsWithForMatching(text, offset, source)) return false;
  final end = offset + source.length;
  final beginsWithWord = _isTermCodeUnit(source.codeUnitAt(0));
  final endsWithWord = _isTermCodeUnit(source.codeUnitAt(source.length - 1));
  if (beginsWithWord &&
      offset > 0 &&
      _isTermCodeUnit(text.codeUnitAt(offset - 1))) {
    return false;
  }
  if (endsWithWord &&
      end < text.length &&
      _isTermCodeUnit(text.codeUnitAt(end))) {
    return false;
  }
  return true;
}

bool _startsWithForMatching(String text, int offset, String source) {
  if (offset + source.length > text.length) return false;
  for (var index = 0; index < source.length; index += 1) {
    final textCodeUnit = text.codeUnitAt(offset + index);
    final sourceCodeUnit = source.codeUnitAt(index);
    if (_normalizedSpace(textCodeUnit) != _normalizedSpace(sourceCodeUnit)) {
      return false;
    }
  }
  return true;
}

String _normalizedForMatching(String text) => text.replaceAll('\u00A0', ' ');

int _normalizedSpace(int codeUnit) => codeUnit == 0xA0 ? 0x20 : codeUnit;

bool _isTermCodeUnit(int codeUnit) {
  return codeUnit == 0x5F ||
      (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      (codeUnit >= 0x621 && codeUnit <= 0x63A) ||
      (codeUnit >= 0x641 && codeUnit <= 0x65F) ||
      (codeUnit >= 0x660 && codeUnit <= 0x669) ||
      (codeUnit >= 0x671 && codeUnit <= 0x6D3) ||
      (codeUnit >= 0x6F0 && codeUnit <= 0x6F9);
}
