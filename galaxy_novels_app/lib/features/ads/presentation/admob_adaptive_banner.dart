import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobAdaptiveBanner extends StatefulWidget {
  const AdMobAdaptiveBanner({required this.adUnitId, super.key});

  static const double reservedHeight = 56;

  final String adUnitId;

  @override
  State<AdMobAdaptiveBanner> createState() => _AdMobAdaptiveBannerState();
}

class _AdMobAdaptiveBannerState extends State<AdMobAdaptiveBanner> {
  BannerAd? _bannerAd;
  int? _requestedWidth;
  bool _isLoading = false;
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (width > 0 && width != _requestedWidth && !_isLoading) {
          unawaited(_loadBanner(width));
        }

        final bannerAd = _bannerAd;
        if (!_isLoaded || bannerAd == null) {
          return const SizedBox.expand();
        }

        return Center(
          child: SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: AdWidget(ad: bannerAd),
          ),
        );
      },
    );
  }

  Future<void> _loadBanner(int width) async {
    _isLoading = true;
    _requestedWidth = width;
    _isLoaded = false;

    final nextSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || nextSize == null || _requestedWidth != width) {
      _isLoading = false;
      return;
    }

    final previousAd = _bannerAd;
    final nextAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: nextSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !identical(ad, _bannerAd)) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _isLoading = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted || !identical(ad, _bannerAd)) {
            return;
          }
          setState(() {
            _isLoaded = false;
            _isLoading = false;
            _bannerAd = null;
          });
        },
      ),
    );
    _bannerAd = nextAd;
    unawaited(previousAd?.dispose());
    await nextAd.load();
  }

  @override
  void dispose() {
    unawaited(_bannerAd?.dispose());
    super.dispose();
  }
}
