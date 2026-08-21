import 'package:flutter/foundation.dart';

import '../domain/reader_term_replacement.dart';

abstract class ReaderTermReplacementRepository
    implements ValueListenable<List<ReaderTermReplacement>> {
  Future<void> load();

  Future<void> save(
    ReaderTermReplacement replacement, {
    ReaderTermReplacement? replacing,
  });

  Future<void> remove(ReaderTermReplacement replacement);
}
