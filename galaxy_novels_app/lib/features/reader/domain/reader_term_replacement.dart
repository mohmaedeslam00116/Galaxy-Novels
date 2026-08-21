enum ReaderTermScope { currentNovel, allNovels }

class ReaderTermReplacement {
  const ReaderTermReplacement({
    required this.source,
    required this.replacement,
    required this.scope,
    required this.novelId,
  });

  final String source;
  final String replacement;
  final ReaderTermScope scope;
  final int novelId;

  bool appliesToNovel(int currentNovelId) {
    return scope == ReaderTermScope.allNovels || novelId == currentNovelId;
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'replacement': replacement,
      'scope': scope.name,
      'novel_id': novelId,
    };
  }

  static ReaderTermReplacement? fromJson(Map<String, dynamic> json) {
    final source = json['source']?.toString().trim() ?? '';
    final replacement = json['replacement']?.toString().trim() ?? '';
    final scope = ReaderTermScope.values.firstWhere(
      (candidate) => candidate.name == json['scope']?.toString(),
      orElse: () => ReaderTermScope.currentNovel,
    );
    final novelId = int.tryParse(json['novel_id']?.toString() ?? '') ?? 0;
    if (source.isEmpty || replacement.isEmpty) return null;
    if (scope == ReaderTermScope.currentNovel && novelId <= 0) return null;
    return ReaderTermReplacement(
      source: source,
      replacement: replacement,
      scope: scope,
      novelId: scope == ReaderTermScope.allNovels ? 0 : novelId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderTermReplacement &&
        other.source == source &&
        other.replacement == replacement &&
        other.scope == scope &&
        other.novelId == novelId;
  }

  @override
  int get hashCode => Object.hash(source, replacement, scope, novelId);
}

class ReaderTermTextSegment {
  const ReaderTermTextSegment({
    required this.text,
    required this.isReplacement,
  });

  final String text;
  final bool isReplacement;
}

String applyReaderTermReplacements(
  String text,
  List<ReaderTermReplacement> replacements,
  int novelId,
) {
  return segmentReaderTermReplacements(
    text,
    replacements,
    novelId,
  ).map((segment) => segment.text).join();
}

List<ReaderTermTextSegment> segmentReaderTermReplacements(
  String text,
  List<ReaderTermReplacement> replacements,
  int novelId,
) {
  if (text.isEmpty) return const [];
  final activeRules = _activeTermRules(replacements, novelId);
  if (activeRules.isEmpty) {
    return [ReaderTermTextSegment(text: text, isReplacement: false)];
  }

  final segments = <ReaderTermTextSegment>[];
  var plainText = StringBuffer();
  var offset = 0;
  while (offset < text.length) {
    final match = _termMatchAt(text, offset, activeRules);
    if (match == null) {
      plainText.writeCharCode(text.codeUnitAt(offset));
      offset += 1;
      continue;
    }
    if (plainText.length > 0) {
      segments.add(
        ReaderTermTextSegment(text: plainText.toString(), isReplacement: false),
      );
      plainText = StringBuffer();
    }
    segments.add(
      ReaderTermTextSegment(text: match.replacement, isReplacement: true),
    );
    offset += match.source.length;
  }
  if (plainText.length > 0) {
    segments.add(
      ReaderTermTextSegment(text: plainText.toString(), isReplacement: false),
    );
  }
  return List.unmodifiable(segments);
}

List<ReaderTermReplacement> _activeTermRules(
  List<ReaderTermReplacement> replacements,
  int novelId,
) {
  final activeBySource = <String, ReaderTermReplacement>{};
  for (final rule in replacements) {
    if (rule.scope == ReaderTermScope.allNovels) {
      activeBySource[rule.source] = rule;
    }
  }
  for (final rule in replacements) {
    if (rule.scope == ReaderTermScope.currentNovel &&
        rule.appliesToNovel(novelId)) {
      activeBySource[rule.source] = rule;
    }
  }
  final activeRules = activeBySource.values.toList()
    ..sort(
      (first, second) => second.source.length.compareTo(first.source.length),
    );
  return activeRules;
}

ReaderTermReplacement? _termMatchAt(
  String text,
  int offset,
  List<ReaderTermReplacement> rules,
) {
  for (final rule in rules) {
    if (!text.startsWith(rule.source, offset)) continue;
    final end = offset + rule.source.length;
    final beginsWithWord = _isTermCodeUnit(rule.source.codeUnitAt(0));
    final endsWithWord = _isTermCodeUnit(
      rule.source.codeUnitAt(rule.source.length - 1),
    );
    if (beginsWithWord &&
        offset > 0 &&
        _isTermCodeUnit(text.codeUnitAt(offset - 1))) {
      continue;
    }
    if (endsWithWord &&
        end < text.length &&
        _isTermCodeUnit(text.codeUnitAt(end))) {
      continue;
    }
    return rule;
  }
  return null;
}

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
