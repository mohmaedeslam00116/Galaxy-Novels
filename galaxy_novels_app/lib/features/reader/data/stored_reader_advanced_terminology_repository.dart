import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../application/reader_advanced_terminology_repository.dart';
import '../domain/reader_advanced_terminology.dart';

class StoredReaderAdvancedTerminologyRepository extends ChangeNotifier
    implements ReaderAdvancedTerminologyRepository {
  StoredReaderAdvancedTerminologyRepository({
    required ReaderAdvancedTerminologyStateStore stateStore,
    required ReaderAdvancedTerminologyAccessStore accessStore,
  }) : _stateStore = stateStore,
       _accessStore = accessStore;

  final ReaderAdvancedTerminologyStateStore _stateStore;
  final ReaderAdvancedTerminologyAccessStore _accessStore;
  ReaderAdvancedTerminologyState _value =
      ReaderAdvancedTerminologyState.defaults;
  Future<void>? _loadOperation;
  Future<void> _writeQueue = Future.value();
  bool _didLoad = false;

  @override
  ReaderAdvancedTerminologyState get value => _value;

  @override
  Future<void> load() {
    if (_didLoad) return Future.value();
    return _loadOperation ??= _load();
  }

  Future<void> _load() async {
    var accessUnlocked = false;
    try {
      accessUnlocked = await _accessStore.read();
    } catch (_) {
      accessUnlocked = false;
    }
    try {
      final raw = await _stateStore.read();
      final Object? decoded = raw == null || raw.isEmpty
          ? null
          : jsonDecode(raw);
      _value = ReaderAdvancedTerminologyState.fromJson(
        decoded,
        accessUnlocked: accessUnlocked,
      );
    } catch (_) {
      _value = ReaderAdvancedTerminologyState.defaults.copyWith(
        accessUnlocked: accessUnlocked,
      );
    } finally {
      _didLoad = true;
      notifyListeners();
    }
  }

  @override
  Future<void> unlock() async {
    await _accessStore.write(true);
    _setValue(_value.copyWith(accessUnlocked: true));
  }

  @override
  Future<void> hideTools() async {
    final next = _value.copyWith(accessUnlocked: false, packEnabled: false);
    await _writeState(next);
    await _accessStore.write(false);
    _setValue(next);
  }

  @override
  Future<void> replacePack(
    ReaderTerminologyImportPreview preview, {
    required ReaderPackFeatureSelection features,
  }) {
    final pack = preview.pack;
    final replacementSources = pack.replacements
        .map((rule) => rule.source)
        .toSet();
    final guardSources = pack.guardSentences.toSet();
    final exceptionSources = pack.exceptions.toSet();
    return _commit(
      _value.copyWith(
        pack: pack,
        packEnabled: true,
        features: features,
        disabledReplacementSources: _retainedSet(
          _value.disabledReplacementSources,
          replacementSources,
        ),
        disabledGuardSentences: _retainedSet(
          _value.disabledGuardSentences,
          guardSources,
        ),
        disabledExceptions: _retainedSet(
          _value.disabledExceptions,
          exceptionSources,
        ),
        replacementOverrides: _retainedMap(
          _value.replacementOverrides,
          replacementSources,
        ),
        guardOverrides: _retainedMap(_value.guardOverrides, guardSources),
        exceptionOverrides: _retainedMap(
          _value.exceptionOverrides,
          exceptionSources,
        ),
      ),
    );
  }

  @override
  Future<void> clearPack() {
    return _commit(
      _value.copyWith(
        clearPack: true,
        packEnabled: false,
        disabledReplacementSources: const {},
        disabledGuardSentences: const {},
        disabledExceptions: const {},
        replacementOverrides: const {},
        guardOverrides: const {},
        exceptionOverrides: const {},
      ),
    );
  }

  @override
  Future<void> setPackEnabled(bool enabled) {
    if (_value.pack == null && enabled) return Future.value();
    return _commit(_value.copyWith(packEnabled: enabled));
  }

  @override
  Future<void> setFeatures(ReaderPackFeatureSelection features) {
    return _commit(_value.copyWith(features: features));
  }

  @override
  Future<void> setRuleEnabled(
    ReaderAdvancedRuleKind kind,
    String source,
    bool enabled,
  ) {
    final disabled = switch (kind) {
      ReaderAdvancedRuleKind.replacement => {
        ..._value.disabledReplacementSources,
      },
      ReaderAdvancedRuleKind.removal => {..._value.disabledGuardSentences},
      ReaderAdvancedRuleKind.exception => {..._value.disabledExceptions},
    };
    if (enabled) {
      disabled.remove(source);
    } else {
      disabled.add(source);
    }
    final next = switch (kind) {
      ReaderAdvancedRuleKind.replacement => _value.copyWith(
        disabledReplacementSources: disabled,
      ),
      ReaderAdvancedRuleKind.removal => _value.copyWith(
        disabledGuardSentences: disabled,
      ),
      ReaderAdvancedRuleKind.exception => _value.copyWith(
        disabledExceptions: disabled,
      ),
    };
    return _commit(next);
  }

  @override
  Future<void> setReplacementOverride(String source, String replacement) {
    return _setOverride(
      source,
      replacement,
      current: _value.replacementOverrides,
      apply: (overrides) => _value.copyWith(replacementOverrides: overrides),
    );
  }

  @override
  Future<void> setRemovalOverride(String source, String replacement) {
    return _setOverride(
      source,
      replacement,
      current: _value.guardOverrides,
      apply: (overrides) => _value.copyWith(guardOverrides: overrides),
    );
  }

  @override
  Future<void> setExceptionOverride(String source, String replacement) {
    return _setOverride(
      source,
      replacement,
      current: _value.exceptionOverrides,
      apply: (overrides) => _value.copyWith(exceptionOverrides: overrides),
    );
  }

  Future<void> _setOverride(
    String source,
    String replacement, {
    required Map<String, String> current,
    required ReaderAdvancedTerminologyState Function(Map<String, String>) apply,
  }) {
    final normalizedSource = source.trim();
    final normalizedReplacement = replacement.trim();
    if (normalizedSource.isEmpty || normalizedReplacement.isEmpty) {
      return Future.error(ArgumentError('source and replacement are required'));
    }
    final overrides = {...current, normalizedSource: normalizedReplacement};
    return _commit(apply(overrides));
  }

  @override
  Future<void> restoreRule(ReaderAdvancedRuleKind kind, String source) {
    final next = switch (kind) {
      ReaderAdvancedRuleKind.replacement => _value.copyWith(
        replacementOverrides: {..._value.replacementOverrides}..remove(source),
        disabledReplacementSources: {..._value.disabledReplacementSources}
          ..remove(source),
      ),
      ReaderAdvancedRuleKind.removal => _value.copyWith(
        guardOverrides: {..._value.guardOverrides}..remove(source),
        disabledGuardSentences: {..._value.disabledGuardSentences}
          ..remove(source),
      ),
      ReaderAdvancedRuleKind.exception => _value.copyWith(
        exceptionOverrides: {..._value.exceptionOverrides}..remove(source),
        disabledExceptions: {..._value.disabledExceptions}..remove(source),
      ),
    };
    return _commit(next);
  }

  @override
  Future<void> savePersonalRemoval(ReaderTextRemovalRule rule) {
    final removals = [..._value.personalRemovals]
      ..removeWhere(
        (candidate) =>
            candidate.source == rule.source &&
            candidate.scope == rule.scope &&
            candidate.novelId == rule.novelId,
      )
      ..add(rule);
    return _commit(_value.copyWith(personalRemovals: removals));
  }

  @override
  Future<void> removePersonalRemoval(ReaderTextRemovalRule rule) {
    return _commit(
      _value.copyWith(
        personalRemovals: _value.personalRemovals
            .where((candidate) => candidate != rule)
            .toList(growable: false),
      ),
    );
  }

  @override
  Future<void> savePersonalException(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) return Future.value();
    return _commit(
      _value.copyWith(
        personalExceptions: {..._value.personalExceptions, normalized}.toList(),
      ),
    );
  }

  @override
  Future<void> removePersonalException(String source) {
    return _commit(
      _value.copyWith(
        personalExceptions: _value.personalExceptions
            .where((candidate) => candidate != source)
            .toList(growable: false),
      ),
    );
  }

  Future<void> _commit(ReaderAdvancedTerminologyState next) async {
    await _writeState(next);
    _setValue(next);
  }

  Future<void> _writeState(ReaderAdvancedTerminologyState next) {
    final encoded = jsonEncode(next.toJson());
    final operation = _writeQueue
        .catchError((Object _) {})
        .then((_) => _stateStore.write(encoded));
    _writeQueue = operation.catchError((Object _) {});
    return operation;
  }

  void _setValue(ReaderAdvancedTerminologyState next) {
    _value = next;
    notifyListeners();
  }
}

Set<String> _retainedSet(Set<String> current, Set<String> validSources) =>
    current.intersection(validSources);

Map<String, String> _retainedMap(
  Map<String, String> current,
  Set<String> validSources,
) => {
  for (final entry in current.entries)
    if (validSources.contains(entry.key)) entry.key: entry.value,
};
