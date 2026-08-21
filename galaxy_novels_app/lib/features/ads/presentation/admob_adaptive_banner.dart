import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'adaptive_banner_frame.dart';

class AdMobAdaptiveBanner extends StatelessWidget {
  const AdMobAdaptiveBanner({
    required this.adUnitId,
    required this.readiness,
    super.key,
  });

  final String adUnitId;
  final Future<bool> readiness;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: readiness,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const AdaptiveBannerFrame(
            isLoaded: false,
            size: null,
            child: SizedBox.shrink(),
          );
        }
        return _ReadyAdMobAdaptiveBanner(adUnitId: adUnitId);
      },
    );
  }
}

class _ReadyAdMobAdaptiveBanner extends StatefulWidget {
  const _ReadyAdMobAdaptiveBanner({required this.adUnitId});

  final String adUnitId;

  @override
  State<_ReadyAdMobAdaptiveBanner> createState() =>
      _ReadyAdMobAdaptiveBannerState();
}

class _ReadyAdMobAdaptiveBannerState extends State<_ReadyAdMobAdaptiveBanner> {
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
        final bannerSize = bannerAd == null
            ? null
            : Size(
                bannerAd.size.width.toDouble(),
                bannerAd.size.height.toDouble(),
              );
        return AdaptiveBannerFrame(
          isLoaded: _isLoaded && bannerAd != null,
          size: bannerSize,
          child: bannerAd == null
              ? const SizedBox.shrink()
              : AdWidget(ad: bannerAd),
        );
      },
    );
  }

  Future<void> _loadBanner(int width) async {
    _isLoading = true;
    _requestedWidth = width;
    _isLoaded = false;

    try {
      final nextSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted || _requestedWidth != width) {
        _isLoading = false;
        return;
      }
      if (nextSize == null) {
        _collapseBanner();
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
    } on MissingPluginException {
      _collapseBanner();
    } on PlatformException {
      _collapseBanner();
    }
  }

  void _collapseBanner() {
    final ad = _bannerAd;
    _bannerAd = null;
    _isLoaded = false;
    _isLoading = false;
    unawaited(ad?.dispose());
  }

  @override
  void dispose() {
    unawaited(_bannerAd?.dispose());
    super.dispose();
  }
}
