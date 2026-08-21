import 'package:flutter/material.dart';

typedef ReaderChromePalette = ({
  Color background,
  Color border,
  Color foreground,
  Color primary,
  Color primaryForeground,
});

ReaderChromePalette resolveReaderChromePalette({required ColorScheme scheme}) {
  return (
    background: scheme.surface,
    border: scheme.outlineVariant,
    foreground: scheme.onSurface,
    primary: scheme.primary,
    primaryForeground: scheme.onPrimary,
  );
}
