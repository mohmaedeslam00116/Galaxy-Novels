import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../downloads/application/download_analytics.dart';
import '../../downloads/application/download_repository.dart';
import '../../downloads/domain/download_entitlement.dart';
import '../../downloads/domain/download_models.dart';
import '../domain/readable_chapter.dart';
import 'chapter_download_request.dart';

enum DownloadPlannerSelectionMode { next, range, all, manual }

@immutable
class DownloadPlannerCatalogResult {
  DownloadPlannerCatalogResult({
    required List<ReadableChapter> chapters,
    required this.complete,
    this.errorMessage,
  }) : chapters = List.unmodifiable(chapters);

  final List<ReadableChapter> chapters;
  final bool complete;
  final String? errorMessage;
}

@immutable
class DownloadPlanPreview {
  DownloadPlanPreview({
    required List<ReadableChapter> chapters,
    required this.skippedDownloaded,
    required this.skippedQueued,
    required this.allowance,
  }) : chapters = List.unmodifiable(chapters);

  final List<ReadableChapter> chapters;
  final int skippedDownloaded;
  final int skippedQueued;
  final DownloadAllowance allowance;

  int get availableNow => math.min(chapters.length, allowance.remaining);

  int get availableThroughRewards {
    final waiting = math.max(0, chapters.length - availableNow);
    return math.min(
      waiting,
      allowance.adsRemaining * allowance.plan.rewardPerAd,
    );
  }

  int get rewardAdsNeeded {
    if (availableThroughRewards == 0) return 0;
    return (availableThroughRewards / allowance.plan.rewardPerAd).ceil();
  }

  int get deferredUntilReset =>
      math.max(0, chapters.length - availableNow - availableThroughRewards);
}

class DownloadPlannerController extends ChangeNotifier {
  DownloadPlannerController({
    required List<ReadableChapter> chapters,
    required DownloadsDashboard dashboard,
    int? readingChapterPosition,
    DownloadAnalytics analytics = const NoopDownloadAnalytics(),
  }) : _chapters = _ordered(chapters),
       _dashboard = dashboard,
       _readingChapterPosition = readingChapterPosition,
       _analytics = analytics {
    unawaited(
      _analytics.record(
        DownloadAnalyticsEvent.plannerOpened(
          selectionType: _mode.name,
          membershipTier: _membershipTier,
        ),
      ),
    );
  }

  static const defaultQuickCount = 25;

  List<ReadableChapter> _chapters;
  DownloadsDashboard _dashboard;
  final int? _readingChapterPosition;
  final DownloadAnalytics _analytics;
  DownloadPlannerSelectionMode _mode = DownloadPlannerSelectionMode.next;
  int _quickCount = defaultQuickCount;
  int _rangeStart = 1;
  int _rangeEnd = 1;
  Set<String> _manualKeys = const {};
  bool _isLoadingCatalog = false;
  String? _catalogError;
  bool _isSubmitting = false;
  String? _submitError;
  DownloadEnqueueResult? _submission;

  DownloadPlannerSelectionMode get mode => _mode;
  int get quickCount => _quickCount;
  int get rangeStart => _rangeStart;
  int get rangeEnd => _rangeEnd;
  DownloadsDashboard get dashboard => _dashboard;
  bool get isLoadingCatalog => _isLoadingCatalog;
  String? get catalogError => _catalogError;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  DownloadEnqueueResult? get submission => _submission;

  DownloadPlanPreview get preview {
    final selection = switch (_mode) {
      DownloadPlannerSelectionMode.next => _nextSelection(),
      DownloadPlannerSelectionMode.range => _rangeSelection(),
      DownloadPlannerSelectionMode.all => _filteredSelection(_chapters),
      DownloadPlannerSelectionMode.manual => _manualSelection(),
    };
    return DownloadPlanPreview(
      chapters: selection.chapters,
      skippedDownloaded: selection.skippedDownloaded,
      skippedQueued: selection.skippedQueued,
      allowance: _dashboard.allowance,
    );
  }

  void selectNext(int count) {
    _mode = DownloadPlannerSelectionMode.next;
    _quickCount = count;
    notifyListeners();
    _recordSelectionChanged();
  }

  void selectRange({required int start, required int end}) {
    _mode = DownloadPlannerSelectionMode.range;
    _rangeStart = start;
    _rangeEnd = end;
    notifyListeners();
    _recordSelectionChanged();
  }

  void selectAll() {
    _mode = DownloadPlannerSelectionMode.all;
    notifyListeners();
    _recordSelectionChanged();
  }

  Future<void> loadAllChapters(
    Future<DownloadPlannerCatalogResult> Function() loader,
  ) async {
    _mode = DownloadPlannerSelectionMode.all;
    _isLoadingCatalog = true;
    _catalogError = null;
    notifyListeners();
    _recordSelectionChanged();
    try {
      final catalog = await loader();
      _chapters = _ordered(catalog.chapters);
      _catalogError = catalog.complete ? null : catalog.errorMessage;
    } catch (_) {
      _catalogError = 'تعذر تحميل بقية الفصول الآن.';
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  void selectManual(Set<String> chapterKeys) {
    _mode = DownloadPlannerSelectionMode.manual;
    _manualKeys = Set.unmodifiable(chapterKeys);
    notifyListeners();
    _recordSelectionChanged();
  }

  void replaceAccessibleChapters(List<ReadableChapter> chapters) {
    _chapters = _ordered(chapters);
    notifyListeners();
  }

  void includeAccessibleChapters(Iterable<ReadableChapter> chapters) {
    final merged = <String, ReadableChapter>{
      for (final chapter in _chapters) chapter.dedupeKey: chapter,
      for (final chapter in chapters) chapter.dedupeKey: chapter,
    };
    _chapters = _ordered(merged.values.toList(growable: false));
    notifyListeners();
  }

  void updateDashboard(DownloadsDashboard dashboard) {
    _dashboard = dashboard;
    notifyListeners();
  }

  Future<void> submit(
    Future<DownloadEnqueueResult> Function(List<ReadableChapter>) enqueue,
  ) async {
    if (_isSubmitting || preview.chapters.isEmpty) return;
    final submittedPreview = preview;
    unawaited(
      _analytics.record(
        DownloadAnalyticsEvent.planConfirmed(
          selectionType: _mode.name,
          chapterCount: submittedPreview.chapters.length,
          availableNow: submittedPreview.availableNow,
          rewardCapacity: submittedPreview.availableThroughRewards,
          deferredCount: submittedPreview.deferredUntilReset,
          skippedCount:
              submittedPreview.skippedDownloaded +
              submittedPreview.skippedQueued,
          membershipTier: _membershipTier,
        ),
      ),
    );
    _isSubmitting = true;
    _submitError = null;
    notifyListeners();
    try {
      _submission = await enqueue(submittedPreview.chapters);
      unawaited(
        _analytics.record(
          DownloadAnalyticsEvent.groupStarted(
            acceptedCount: _submission!.acceptedChapterKeys.length,
            skippedCount: _submission!.skippedChapterKeys.length,
            membershipTier: _membershipTier,
          ),
        ),
      );
    } on DownloadUnavailableException {
      _submitError = 'تعذر إضافة الفصول للتنزيل. حاول مرة أخرى.';
      _recordGroupFailure(submittedPreview.chapters.length);
    } catch (_) {
      _submitError = 'تعذر إضافة الفصول للتنزيل. حاول مرة أخرى.';
      _recordGroupFailure(submittedPreview.chapters.length);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String get _membershipTier =>
      downloadMembershipLabel(_dashboard.allowance.plan);

  void _recordSelectionChanged() {
    unawaited(
      _analytics.record(
        DownloadAnalyticsEvent.selectionChanged(
          selectionType: _mode.name,
          chapterCount: preview.chapters.length,
        ),
      ),
    );
  }

  void _recordGroupFailure(int chapterCount) {
    unawaited(
      _analytics.record(
        DownloadAnalyticsEvent.groupFailed(
          chapterCount: chapterCount,
          membershipTier: _membershipTier,
        ),
      ),
    );
  }

  _PlannerSelection _nextSelection() {
    final anchor = _readingChapterPosition;
    final candidates = anchor == null || anchor <= 0
        ? _chapters
        : _chapters
              .where((chapter) => chapter.sortPosition > anchor)
              .toList(growable: false);
    final downloaded = _downloadedKeys(_dashboard);
    final queued = _queuedKeys(_dashboard);
    final selected = <ReadableChapter>[];
    var skippedDownloaded = 0;
    var skippedQueued = 0;
    for (final chapter in candidates) {
      final key = chapterDownloadKey(chapter);
      if (downloaded.contains(key)) {
        skippedDownloaded++;
      } else if (queued.contains(key)) {
        skippedQueued++;
      } else {
        selected.add(chapter);
        if (selected.length == _quickCount) break;
      }
    }
    return _PlannerSelection(
      chapters: selected,
      skippedDownloaded: skippedDownloaded,
      skippedQueued: skippedQueued,
    );
  }

  _PlannerSelection _rangeSelection() {
    final candidates = _chapters.where((chapter) {
      final position = chapter.sortPosition;
      return position >= _rangeStart && position <= _rangeEnd;
    });
    return _filteredSelection(candidates);
  }

  _PlannerSelection _manualSelection() {
    return _filteredSelection(
      _chapters.where(
        (chapter) => _manualKeys.contains(chapterDownloadKey(chapter)),
      ),
    );
  }

  _PlannerSelection _filteredSelection(Iterable<ReadableChapter> candidates) {
    final downloaded = _downloadedKeys(_dashboard);
    final queued = _queuedKeys(_dashboard);
    final selected = <ReadableChapter>[];
    var skippedDownloaded = 0;
    var skippedQueued = 0;
    for (final chapter in candidates) {
      final key = chapterDownloadKey(chapter);
      if (downloaded.contains(key)) {
        skippedDownloaded++;
      } else if (queued.contains(key)) {
        skippedQueued++;
      } else {
        selected.add(chapter);
      }
    }
    return _PlannerSelection(
      chapters: selected,
      skippedDownloaded: skippedDownloaded,
      skippedQueued: skippedQueued,
    );
  }
}

@immutable
class _PlannerSelection {
  const _PlannerSelection({
    required this.chapters,
    required this.skippedDownloaded,
    required this.skippedQueued,
  });

  final List<ReadableChapter> chapters;
  final int skippedDownloaded;
  final int skippedQueued;
}

List<ReadableChapter> _ordered(List<ReadableChapter> chapters) {
  return List.unmodifiable(
    [...chapters]..sort(
      (first, second) => first.sortPosition.compareTo(second.sortPosition),
    ),
  );
}

Set<String> _downloadedKeys(DownloadsDashboard dashboard) {
  return dashboard.novels
      .expand((novel) => novel.chapters)
      .map((chapter) => chapter.chapterKey)
      .toSet();
}

Set<String> _queuedKeys(DownloadsDashboard dashboard) {
  return dashboard.groups
      .expand((group) => group.jobs)
      .where(
        (job) =>
            job.status != DownloadJobStatus.canceled &&
            job.status != DownloadJobStatus.completed,
      )
      .map((job) => job.chapterKey)
      .toSet();
}
