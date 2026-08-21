import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/reader_preferences.dart';

const _readerMeasureSample =
    'في هدوء الليل تمتد الحكاية بين النجوم وتعود الكلمات إلى قارئها';
const _readerTabletCeiling = 780.0;

bool isReaderTabletLandscape(MediaQueryData mediaQuery) {
  return mediaQuery.orientation == Orientation.landscape &&
      mediaQuery.size.shortestSide >= 600;
}

double readerMeasureWidth({
  required TextStyle paragraphStyle,
  required ReaderTextWidth textWidth,
  required TextScaler textScaler,
}) {
  final painter = TextPainter(
    text: TextSpan(text: _readerMeasureSample, style: paragraphStyle),
    textDirection: TextDirection.rtl,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();
  final averageCharacterWidth =
      painter.width / _readerMeasureSample.runes.length;
  final targetCharacters = switch (textWidth) {
    ReaderTextWidth.compact => 65,
    ReaderTextWidth.comfortable => 70,
    ReaderTextWidth.wide => 75,
  };
  return (averageCharacterWidth * targetCharacters)
      .clamp(0.0, _readerTabletCeiling)
      .toDouble();
}

double readerContentWidth({
  required double measuredWidth,
  required ReaderTextWidth textWidth,
  required double availableWidth,
  required bool tabletLandscape,
}) {
  if (!tabletLandscape) return math.min(measuredWidth, availableWidth);

  final (fraction, ceiling) = switch (textWidth) {
    ReaderTextWidth.compact => (0.60, 800.0),
    ReaderTextWidth.comfortable => (0.76, 1024.0),
    ReaderTextWidth.wide => (0.92, 1280.0),
  };
  final adaptiveWidth = math.max(measuredWidth, availableWidth * fraction);
  return math.min(availableWidth, math.min(adaptiveWidth, ceiling));
}

class ReaderReadingColumn extends StatelessWidget {
  const ReaderReadingColumn({
    required this.paragraphStyle,
    required this.textWidth,
    required this.textScaler,
    required this.child,
    super.key,
  });

  final TextStyle paragraphStyle;
  final ReaderTextWidth textWidth;
  final TextScaler textScaler;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final tabletLandscape = isReaderTabletLandscape(mediaQuery);
    final horizontalPadding = tabletLandscape ? 24.0 : 16.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = math.max(
          0.0,
          constraints.maxWidth - horizontalPadding * 2,
        );
        final measuredWidth = readerMeasureWidth(
          paragraphStyle: paragraphStyle,
          textWidth: textWidth,
          textScaler: textScaler,
        );
        final maxWidth = readerContentWidth(
          measuredWidth: measuredWidth,
          textWidth: textWidth,
          availableWidth: availableWidth,
          tabletLandscape: tabletLandscape,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: maxWidth, child: child),
          ),
        );
      },
    );
  }
}
