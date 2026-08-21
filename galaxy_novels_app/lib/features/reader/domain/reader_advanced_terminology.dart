import 'dart:convert';
import 'dart:typed_data';

import 'reader_term_replacement.dart';

const int readerTerminologyMaxFileBytes = 1024 * 1024;
const int readerTerminologyMaxRuleCount = 5000;
const int readerTerminologyMaxEntryLength = 4096;

enum ReaderTerminologyImportError {
  fileTooLarge,
  invalidJson,
  unsupportedType,
  unsupportedSchema,
  missingSettings,
  invalidRule,
  conflictingRule,
  tooManyRules,
}

enum ReaderAdvancedRuleKind { replacement, removal, exception }

class ReaderTerminologyImportException implements Exception {
  const ReaderTerminologyImportException(this.code, this.message);

  final ReaderTerminologyImportError code;
  final String message;

  @override
  String toString() => message;
}

class ReaderPackFeatureSelection {
  const ReaderPackFeatureSelection({
    required this.replacements,
    required this.guardRemoval,
    required this.footerRemoval,
  });

  static const enabled = ReaderPackFeatureSelection(
    replacements: true,
    guardRemoval: true,
    footerRemoval: true,
  );

  final bool replacements;
  final bool guardRemoval;
  final bool footerRemoval;

  ReaderPackFeatureSelection copyWith({
    bool? replacements,
    bool? guardRemoval,
    bool? footerRemoval,
  }) {
    return ReaderPackFeatureSelection(
      replacements: replacements ?? this.replacements,
      guardRemoval: guardRemoval ?? this.guardRemoval,
      footerRemoval: footerRemoval ?? this.footerRemoval,
    );
  }

  Map<String, dynamic> toJson() => {
    'replacements': replacements,
    'guard_removal': guardRemoval,
    'footer_removal': footerRemoval,
  };

  static ReaderPackFeatureSelection fromJson(Object? value) {
    if (value is! Map) return enabled;
    return ReaderPackFeatureSelection(
      replacements: _asBool(value['replacements'], fallback: true),
      guardRemoval: _asBool(value['guard_removal'], fallback: true),
      footerRemoval: _asBool(value['footer_removal'], fallback: true),
    );
  }
}

class ReaderPackReplacement {
  const ReaderPackReplacement({
    required this.source,
    required this.replacement,
  });

  final String source;
  final String replacement;

  Map<String, dynamic> toJson() => {
    'source': source,
    'replacement': replacement,
  };

  static ReaderPackReplacement? fromJson(Object? value) {
    if (value is! Map) return null;
    final source = value['source']?.toString().trim() ?? '';
    final replacement = value['replacement']?.toString().trim() ?? '';
    if (source.isEmpty || replacement.isEmpty) return null;
    return ReaderPackReplacement(source: source, replacement: replacement);
  }
}

class ReaderTextRemovalRule {
  const ReaderTextRemovalRule({
    required this.source,
    required this.scope,
    required this.novelId,
  });

  final String source;
  final ReaderTermScope scope;
  final int novelId;

  bool appliesToNovel(int currentNovelId) {
    return scope == ReaderTermScope.allNovels || novelId == currentNovelId;
  }

  Map<String, dynamic> toJson() => {
    'source': source,
    'scope': scope.name,
    'novel_id': scope == ReaderTermScope.allNovels ? 0 : novelId,
  };

  static ReaderTextRemovalRule? fromJson(Object? value) {
    if (value is! Map) return null;
    final source = value['source']?.toString().trim() ?? '';
    final scope = ReaderTermScope.values.firstWhere(
      (candidate) => candidate.name == value['scope']?.toString(),
      orElse: () => ReaderTermScope.currentNovel,
    );
    final novelId = int.tryParse(value['novel_id']?.toString() ?? '') ?? 0;
    if (source.isEmpty ||
        source.length > readerTerminologyMaxEntryLength ||
        (scope == ReaderTermScope.currentNovel && novelId <= 0)) {
      return null;
    }
    return ReaderTextRemovalRule(
      source: source,
      scope: scope,
      novelId: scope == ReaderTermScope.allNovels ? 0 : novelId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderTextRemovalRule &&
        other.source == source &&
        other.scope == scope &&
        other.novelId == novelId;
  }

  @override
  int get hashCode => Object.hash(source, scope, novelId);
}

class ReaderProtectedPhrase {
  const ReaderProtectedPhrase(this.source);

  final String source;
}

class ReaderTerminologyPack {
  const ReaderTerminologyPack({
    required this.schemaVersion,
    required this.type,
    required this.themeVersion,
    required this.siteUrl,
    required this.guardEvery,
    required this.footerEvery,
    required this.replacements,
    required this.guardSentences,
    required this.exceptions,
    required this.footerText,
    this.defaultsInline = const {},
    this.defaultsBulk = const {},
  });

  final int schemaVersion;
  final String type;
  final String themeVersion;
  final String siteUrl;
  final int guardEvery;
  final int footerEvery;
  final List<ReaderPackReplacement> replacements;
  final List<String> guardSentences;
  final List<String> exceptions;
  final String footerText;
  final Map<String, bool> defaultsInline;
  final Map<String, bool> defaultsBulk;

  Map<String, dynamic> toJson() => {
    'schema_version': schemaVersion,
    'type': type,
    'theme_version': themeVersion,
    'site_url': siteUrl,
    'guard_every': guardEvery,
    'footer_every': footerEvery,
    'replacements': replacements.map((rule) => rule.toJson()).toList(),
    'guard_sentences': guardSentences,
    'exceptions': exceptions,
    'footer_text': footerText,
    'defaults_inline': defaultsInline,
    'defaults_bulk': defaultsBulk,
  };

  static ReaderTerminologyPack? fromJson(Object? value) {
    if (value is! Map) return null;
    final schemaVersion = _asInt(value['schema_version']);
    final type = value['type']?.toString() ?? '';
    if (schemaVersion != 1 || type != 'wor_reader_publish_commands') {
      return null;
    }
    final replacements = _objectList(value['replacements'])
        .map(ReaderPackReplacement.fromJson)
        .whereType<ReaderPackReplacement>()
        .toList(growable: false);
    return ReaderTerminologyPack(
      schemaVersion: schemaVersion,
      type: type,
      themeVersion: value['theme_version']?.toString() ?? '',
      siteUrl: value['site_url']?.toString() ?? '',
      guardEvery: _asInt(value['guard_every']),
      footerEvery: _asInt(value['footer_every']),
      replacements: replacements,
      guardSentences: _stringList(value['guard_sentences']),
      exceptions: _stringList(value['exceptions']),
      footerText: value['footer_text']?.toString() ?? '',
      defaultsInline: _boolMap(value['defaults_inline']),
      defaultsBulk: _boolMap(value['defaults_bulk']),
    );
  }
}

class ReaderTerminologyImportPreview {
  const ReaderTerminologyImportPreview({
    required this.pack,
    required this.rawReplacementCount,
    required this.duplicateReplacementCount,
    required this.initialFeatures,
  });

  final ReaderTerminologyPack pack;
  final int rawReplacementCount;
  final int duplicateReplacementCount;
  final ReaderPackFeatureSelection initialFeatures;
}

class ReaderAdvancedTerminologyState {
  const ReaderAdvancedTerminologyState({
    required this.accessUnlocked,
    required this.packEnabled,
    required this.features,
    required this.pack,
    required this.disabledReplacementSources,
    required this.disabledGuardSentences,
    required this.disabledExceptions,
    required this.replacementOverrides,
    required this.guardOverrides,
    required this.exceptionOverrides,
    required this.personalRemovals,
    required this.personalExceptions,
  });

  static const defaults = ReaderAdvancedTerminologyState(
    accessUnlocked: false,
    packEnabled: false,
    features: ReaderPackFeatureSelection.enabled,
    pack: null,
    disabledReplacementSources: <String>{},
    disabledGuardSentences: <String>{},
    disabledExceptions: <String>{},
    replacementOverrides: <String, String>{},
    guardOverrides: <String, String>{},
    exceptionOverrides: <String, String>{},
    personalRemovals: <ReaderTextRemovalRule>[],
    personalExceptions: <String>[],
  );

  final bool accessUnlocked;
  final bool packEnabled;
  final ReaderPackFeatureSelection features;
  final ReaderTerminologyPack? pack;
  final Set<String> disabledReplacementSources;
  final Set<String> disabledGuardSentences;
  final Set<String> disabledExceptions;
  final Map<String, String> replacementOverrides;
  final Map<String, String> guardOverrides;
  final Map<String, String> exceptionOverrides;
  final List<ReaderTextRemovalRule> personalRemovals;
  final List<String> personalExceptions;

  bool get transformationsEnabled =>
      accessUnlocked && packEnabled && pack != null;

  ReaderAdvancedTerminologyState copyWith({
    bool? accessUnlocked,
    bool? packEnabled,
    ReaderPackFeatureSelection? features,
    ReaderTerminologyPack? pack,
    bool clearPack = false,
    Set<String>? disabledReplacementSources,
    Set<String>? disabledGuardSentences,
    Set<String>? disabledExceptions,
    Map<String, String>? replacementOverrides,
    Map<String, String>? guardOverrides,
    Map<String, String>? exceptionOverrides,
    List<ReaderTextRemovalRule>? personalRemovals,
    List<String>? personalExceptions,
  }) {
    return ReaderAdvancedTerminologyState(
      accessUnlocked: accessUnlocked ?? this.accessUnlocked,
      packEnabled: packEnabled ?? this.packEnabled,
      features: features ?? this.features,
      pack: clearPack ? null : (pack ?? this.pack),
      disabledReplacementSources:
          disabledReplacementSources ?? this.disabledReplacementSources,
      disabledGuardSentences:
          disabledGuardSentences ?? this.disabledGuardSentences,
      disabledExceptions: disabledExceptions ?? this.disabledExceptions,
      replacementOverrides: replacementOverrides ?? this.replacementOverrides,
      guardOverrides: guardOverrides ?? this.guardOverrides,
      exceptionOverrides: exceptionOverrides ?? this.exceptionOverrides,
      personalRemovals: personalRemovals ?? this.personalRemovals,
      personalExceptions: personalExceptions ?? this.personalExceptions,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'pack_enabled': packEnabled,
    'features': features.toJson(),
    'pack': pack?.toJson(),
    'disabled_replacements': disabledReplacementSources.toList(),
    'disabled_guard_sentences': disabledGuardSentences.toList(),
    'disabled_exceptions': disabledExceptions.toList(),
    'replacement_overrides': replacementOverrides,
    'guard_overrides': guardOverrides,
    'exception_overrides': exceptionOverrides,
    'personal_removals': personalRemovals.map((rule) => rule.toJson()).toList(),
    'personal_exceptions': personalExceptions,
  };

  static ReaderAdvancedTerminologyState fromJson(
    Object? value, {
    required bool accessUnlocked,
  }) {
    if (value is! Map || _asInt(value['version']) != 1) {
      return defaults.copyWith(accessUnlocked: accessUnlocked);
    }
    return ReaderAdvancedTerminologyState(
      accessUnlocked: accessUnlocked,
      packEnabled: _asBool(value['pack_enabled']),
      features: ReaderPackFeatureSelection.fromJson(value['features']),
      pack: ReaderTerminologyPack.fromJson(value['pack']),
      disabledReplacementSources: _stringList(
        value['disabled_replacements'],
      ).toSet(),
      disabledGuardSentences: _stringList(
        value['disabled_guard_sentences'],
      ).toSet(),
      disabledExceptions: _stringList(value['disabled_exceptions']).toSet(),
      replacementOverrides: _stringMap(value['replacement_overrides']),
      guardOverrides: _stringMap(value['guard_overrides']),
      exceptionOverrides: _stringMap(value['exception_overrides']),
      personalRemovals: _objectList(value['personal_removals'])
          .map(ReaderTextRemovalRule.fromJson)
          .whereType<ReaderTextRemovalRule>()
          .toList(growable: false),
      personalExceptions: _stringList(value['personal_exceptions']),
    );
  }
}

ReaderTerminologyImportPreview parseReaderTerminologyPack(Uint8List bytes) {
  if (bytes.length > readerTerminologyMaxFileBytes) {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.fileTooLarge,
      'حجم الملف يتجاوز 1 ميغابايت.',
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(bytes, allowMalformed: false));
  } on FormatException {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.invalidJson,
      'ملف JSON غير صالح.',
    );
  }
  if (decoded is! Map) {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.invalidJson,
      'يجب أن يحتوي الملف على كائن JSON.',
    );
  }

  final type = decoded['type']?.toString() ?? '';
  if (type != 'wor_reader_publish_commands') {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.unsupportedType,
      'نوع ملف المصطلحات غير مدعوم.',
    );
  }
  final schemaVersion = _asInt(decoded['schema_version']);
  if (schemaVersion != 1) {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.unsupportedSchema,
      'إصدار ملف المصطلحات غير مدعوم.',
    );
  }
  final settings = decoded['settings'];
  if (settings is! Map ||
      settings['word_rules'] is! List ||
      settings['phrase_rules'] is! List ||
      settings['guard_sentences'] is! List ||
      settings['exceptions'] is! List ||
      settings['footer_content'] == null) {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.missingSettings,
      'يفتقد الملف حقول المصطلحات المطلوبة.',
    );
  }

  final rawRules = <Object?>[
    ..._objectList(settings['word_rules']),
    ..._objectList(settings['phrase_rules']),
  ];
  final guardSentences = _validatedUniqueStrings(
    settings['guard_sentences'],
    fieldName: 'جمل الحماية',
  );
  final exceptions = _validatedUniqueStrings(
    settings['exceptions'],
    fieldName: 'الاستثناءات',
  );
  final footerText = _plainTextFromHtml(settings['footer_content'].toString());
  final totalRuleCount =
      rawRules.length +
      guardSentences.length +
      exceptions.length +
      (footerText.isEmpty ? 0 : 1);
  if (totalRuleCount > readerTerminologyMaxRuleCount) {
    throw const ReaderTerminologyImportException(
      ReaderTerminologyImportError.tooManyRules,
      'عدد قواعد المصطلحات يتجاوز الحد المسموح.',
    );
  }

  final bySource = <String, ReaderPackReplacement>{};
  var duplicateCount = 0;
  for (final rawRule in rawRules) {
    if (rawRule is! Map) {
      throw const ReaderTerminologyImportException(
        ReaderTerminologyImportError.invalidRule,
        'توجد قاعدة استبدال غير صالحة.',
      );
    }
    final source = rawRule['from']?.toString().trim() ?? '';
    final replacement = rawRule['to']?.toString().trim() ?? '';
    _validateEntry(source, 'المصطلح الأصلي');
    _validateEntry(replacement, 'المصطلح البديل');
    final existing = bySource[source];
    if (existing != null) {
      if (existing.replacement != replacement) {
        throw ReaderTerminologyImportException(
          ReaderTerminologyImportError.conflictingRule,
          'توجد قيمتان مختلفتان للمصطلح «$source».',
        );
      }
      duplicateCount += 1;
      continue;
    }
    bySource[source] = ReaderPackReplacement(
      source: source,
      replacement: replacement,
    );
  }

  final pack = ReaderTerminologyPack(
    schemaVersion: schemaVersion,
    type: type,
    themeVersion: decoded['theme_version']?.toString() ?? '',
    siteUrl: decoded['site_url']?.toString() ?? '',
    guardEvery: _asInt(settings['guard_every']),
    footerEvery: _asInt(settings['footer_every']),
    replacements: List.unmodifiable(bySource.values),
    guardSentences: List.unmodifiable(guardSentences),
    exceptions: List.unmodifiable(exceptions),
    footerText: footerText,
    defaultsInline: _boolMap(settings['defaults_inline']),
    defaultsBulk: _boolMap(settings['defaults_bulk']),
  );
  return ReaderTerminologyImportPreview(
    pack: pack,
    rawReplacementCount: rawRules.length,
    duplicateReplacementCount: duplicateCount,
    initialFeatures: ReaderPackFeatureSelection(
      replacements: _asBool(settings['filter_enabled']),
      guardRemoval: _asBool(settings['guard_enabled']),
      footerRemoval: _asBool(settings['footer_enabled']),
    ),
  );
}

List<String> _validatedUniqueStrings(
  Object? value, {
  required String fieldName,
}) {
  if (value is! List) {
    throw ReaderTerminologyImportException(
      ReaderTerminologyImportError.invalidRule,
      'حقل $fieldName غير صالح.',
    );
  }
  final values = <String>{};
  for (final entry in value) {
    final text = entry?.toString().trim() ?? '';
    _validateEntry(text, fieldName);
    values.add(text);
  }
  return values.toList(growable: false);
}

void _validateEntry(String value, String fieldName) {
  if (value.isEmpty || value.length > readerTerminologyMaxEntryLength) {
    throw ReaderTerminologyImportException(
      ReaderTerminologyImportError.invalidRule,
      'قيمة $fieldName غير صالحة.',
    );
  }
}

String _plainTextFromHtml(String html) {
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');
  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final value = int.tryParse(match.group(1) ?? '');
    return value == null ? match.group(0)! : String.fromCharCode(value);
  });
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<Object?> _objectList(Object? value) =>
    value is List ? List<Object?>.from(value) : const [];

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry?.toString().trim() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key.toString().trim().isNotEmpty &&
          entry.value.toString().trim().isNotEmpty)
        entry.key.toString(): entry.value.toString(),
  };
}

Map<String, bool> _boolMap(Object? value) {
  if (value is! Map) return const {};
  return Map.unmodifiable({
    for (final entry in value.entries)
      if (entry.key.toString().trim().isNotEmpty)
        entry.key.toString(): _asBool(entry.value),
  });
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}
