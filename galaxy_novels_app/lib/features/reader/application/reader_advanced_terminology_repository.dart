import 'package:flutter/foundation.dart';

import '../domain/reader_advanced_terminology.dart';

abstract class ReaderAdvancedTerminologyRepository
    implements ValueListenable<ReaderAdvancedTerminologyState> {
  Future<void> load();

  Future<void> unlock();

  Future<void> hideTools();

  Future<void> replacePack(
    ReaderTerminologyImportPreview preview, {
    required ReaderPackFeatureSelection features,
  });

  Future<void> clearPack();

  Future<void> setPackEnabled(bool enabled);

  Future<void> setFeatures(ReaderPackFeatureSelection features);

  Future<void> setRuleEnabled(
    ReaderAdvancedRuleKind kind,
    String source,
    bool enabled,
  );

  Future<void> setReplacementOverride(String source, String replacement);

  Future<void> setRemovalOverride(String source, String replacement);

  Future<void> setExceptionOverride(String source, String replacement);

  Future<void> restoreRule(ReaderAdvancedRuleKind kind, String source);

  Future<void> savePersonalRemoval(ReaderTextRemovalRule rule);

  Future<void> removePersonalRemoval(ReaderTextRemovalRule rule);

  Future<void> savePersonalException(String source);

  Future<void> removePersonalException(String source);
}

abstract class ReaderAdvancedTerminologyStateStore {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

abstract class ReaderAdvancedTerminologyAccessStore {
  Future<bool> read();

  Future<void> write(bool value);
}
