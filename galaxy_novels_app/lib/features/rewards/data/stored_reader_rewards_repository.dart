import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/reader_rewards_repository.dart';

export '../application/reader_rewards_repository.dart';

class StoredReaderRewardsRepository implements ReaderRewardsRepository {
  StoredReaderRewardsRepository({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
  }) : _preferences = preferences,
       _now = now ?? DateTime.now,
       _memoryOnly = false;

  StoredReaderRewardsRepository.memory({
    int initialPoints = 0,
    DateTime Function()? now,
  }) : _preferences = null,
       _now = now ?? DateTime.now,
       _memoryOnly = true {
    _state.value = ReaderRewardsState(
      points: initialPoints,
      rewardedAdsDayKey: _dayKey(_now()),
    );
    _fallbackValue = _encode(_state.value);
  }

  static const key = 'reader_download_rewards.v1';

  SharedPreferencesAsync? _preferences;
  final DateTime Function() _now;
  final bool _memoryOnly;
  String? _fallbackValue;
  final ValueNotifier<ReaderRewardsState> _state = ValueNotifier(
    ReaderRewardsState(rewardedAdsDayKey: _dayKey(DateTime.now())),
  );

  @override
  ValueListenable<ReaderRewardsState> get state => _state;

  @override
  Future<void> load() async {
    final encoded = await _read();
    final decoded = encoded == null
        ? ReaderRewardsState(rewardedAdsDayKey: _dayKey(_now()))
        : _decode(encoded, fallbackDayKey: _dayKey(_now()));
    _state.value = _withCurrentDay(decoded);
    await _write(_state.value);
  }

  @override
  void grantRewardedAdPoints() {
    final current = _withCurrentDay(_state.value);
    if (!current.canWatchRewardedAd) {
      throw const RewardedAdDailyLimitException();
    }
    _setState(
      current.copyWith(
        points: current.points + ReaderRewardsState.rewardedAdPoints,
        rewardedAdsWatchedToday: current.rewardedAdsWatchedToday + 1,
      ),
    );
  }

  @override
  void spendForDownload(int chapterCount) {
    if (chapterCount <= 0) {
      return;
    }
    final requiredPoints =
        chapterCount * ReaderRewardsState.pointsPerChapterDownload;
    final current = _withCurrentDay(_state.value);
    if (current.points < requiredPoints) {
      throw InsufficientDownloadPointsException(
        requiredPoints: requiredPoints,
        availablePoints: current.points,
      );
    }
    _setState(current.copyWith(points: current.points - requiredPoints));
  }

  @override
  void refundDownloadPoints(int chapterCount) {
    if (chapterCount <= 0) {
      return;
    }
    final refund = chapterCount * ReaderRewardsState.pointsPerChapterDownload;
    final current = _withCurrentDay(_state.value);
    _setState(current.copyWith(points: current.points + refund));
  }

  void dispose() {
    _state.dispose();
  }

  void _setState(ReaderRewardsState state) {
    _state.value = state;
    unawaited(_write(state));
  }

  ReaderRewardsState _withCurrentDay(ReaderRewardsState state) {
    final today = _dayKey(_now());
    if (state.rewardedAdsDayKey == today) {
      return state;
    }
    return state.copyWith(rewardedAdsDayKey: today, rewardedAdsWatchedToday: 0);
  }

  Future<String?> _read() async {
    if (_memoryOnly) {
      return _fallbackValue;
    }
    final preferences = _safePreferences();
    if (preferences == null) {
      return _fallbackValue;
    }
    try {
      return await preferences.getString(key) ?? _fallbackValue;
    } on MissingPluginException {
      return _fallbackValue;
    } on PlatformException {
      return _fallbackValue;
    }
  }

  Future<void> _write(ReaderRewardsState state) async {
    final encoded = _encode(state);
    _fallbackValue = encoded;
    if (_memoryOnly) {
      return;
    }
    final preferences = _safePreferences();
    if (preferences == null) {
      return;
    }
    try {
      await preferences.setString(key, encoded);
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  SharedPreferencesAsync? _safePreferences() {
    try {
      return _preferences ??= SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }
}

String _encode(ReaderRewardsState state) {
  return jsonEncode({
    'version': 1,
    'points': state.points,
    'rewarded_ads_day_key': state.rewardedAdsDayKey,
    'rewarded_ads_watched_today': state.rewardedAdsWatchedToday,
  });
}

ReaderRewardsState _decode(String encoded, {required String fallbackDayKey}) {
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map) {
      throw const FormatException('Rewards payload is not a map.');
    }
    return ReaderRewardsState(
      points: _asNonNegativeInt(decoded['points']),
      rewardedAdsDayKey:
          decoded['rewarded_ads_day_key']?.toString() ?? fallbackDayKey,
      rewardedAdsWatchedToday: _asNonNegativeInt(
        decoded['rewarded_ads_watched_today'],
      ),
    );
  } on FormatException {
    return ReaderRewardsState(rewardedAdsDayKey: fallbackDayKey);
  }
}

int _asNonNegativeInt(Object? value) {
  final number = switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value) ?? 0,
    _ => 0,
  };
  return number < 0 ? 0 : number;
}

String _dayKey(DateTime dateTime) {
  final local = dateTime.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
