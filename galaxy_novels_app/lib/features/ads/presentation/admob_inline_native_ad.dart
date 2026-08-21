import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../application/inline_native_ad_repository.dart';
import '../application/ad_analytics.dart';

class AdMobInlineNativeAd extends StatefulWidget {
  const AdMobInlineNativeAd({
    required this.adUnitId,
    required this.placement,
    required this.readiness,
    required this.analytics,
    super.key,
  });

  static const factoryId = 'galaxyInlineNativeAd';

  final String adUnitId;
  final InlineNativeAdPlacement placement;
  final Future<bool> readiness;
  final AdAnalytics analytics;

  @override
  State<AdMobInlineNativeAd> createState() => _AdMobInlineNativeAdState();
}

class _AdMobInlineNativeAdState extends State<AdMobInlineNativeAd> {
  NativeAd? _ad;
  bool _loadStarted = false;
  bool _loaded = false;
  bool _failed = false;
  late final AdAnalyticsSession _measurement = AdAnalyticsSession(
    analytics: widget.analytics,
    format: AdAnalyticsFormat.native,
    placement: widget.placement.analyticsPlacement,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadStarted) return;
    _loadStarted = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    final scheme = Theme.of(context).colorScheme;
    try {
      final ready = await widget.readiness;
      if (!mounted) return;
      if (!ready) {
        setState(() => _failed = true);
        return;
      }
      await _measurement.loadRequested();
      late final NativeAd nativeAd;
      nativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: AdMobInlineNativeAd.factoryId,
        customOptions: {
          'placement': widget.placement.name,
          'backgroundColor': scheme.surface.toARGB32(),
          'headlineColor': scheme.onSurface.toARGB32(),
          'bodyColor': scheme.onSurfaceVariant.toARGB32(),
          'accentColor': scheme.primary.toARGB32(),
          'accentContentColor': scheme.onPrimary.toARGB32(),
        },
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted || !identical(ad, _ad)) {
              ad.dispose();
              return;
            }
            unawaited(_measurement.loadSuccess());
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (!mounted || !identical(ad, _ad)) return;
            unawaited(_measurement.loadFailure(error.code));
            _ad = null;
            setState(() => _failed = true);
          },
          onAdImpression: (_) {
            unawaited(_measurement.impression());
          },
          onAdClicked: (_) {
            unawaited(_measurement.click());
          },
        ),
      );
      _ad = nativeAd;
      await nativeAd.load();
    } on Exception {
      unawaited(_measurement.loadFailure(-1));
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final metrics = _InlineAdMetrics.forPlacement(widget.placement);
    return Padding(
      key: ValueKey('inline-native-ad-${widget.placement.name}'),
      padding: metrics.padding,
      child: SizedBox(
        height: metrics.height,
        width: double.infinity,
        child: _loaded && _ad != null
            ? AdWidget(ad: _ad!)
            : const _BorderlessInlineAdPlaceholder(),
      ),
    );
  }
}

class _InlineAdMetrics {
  const _InlineAdMetrics({required this.height, required this.padding});

  final double height;
  final EdgeInsets padding;

  static _InlineAdMetrics forPlacement(InlineNativeAdPlacement placement) {
    return switch (placement) {
      InlineNativeAdPlacement.home => const _InlineAdMetrics(
        height: 108,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      ),
      InlineNativeAdPlacement.novelDetails => const _InlineAdMetrics(
        height: 112,
        padding: EdgeInsets.fromLTRB(16, 6, 16, 14),
      ),
      InlineNativeAdPlacement.library => const _InlineAdMetrics(
        height: 116,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      ),
      InlineNativeAdPlacement.rankings => const _InlineAdMetrics(
        height: 104,
        padding: EdgeInsets.fromLTRB(12, 6, 12, 10),
      ),
      InlineNativeAdPlacement.readerJourney => const _InlineAdMetrics(
        height: 104,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      ),
    };
  }
}

class _BorderlessInlineAdPlaceholder extends StatelessWidget {
  const _BorderlessInlineAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 9),
              FractionallySizedBox(
                widthFactor: .62,
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .38),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
