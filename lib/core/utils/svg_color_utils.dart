import 'package:flutter/material.dart';

/// Replaces SVG color-role placeholders with actual hex colors from [cs].
///
/// SVG files reference Material 3 theme roles by name instead of hard-coded
/// hex values (e.g. fill="outlineVariant", stroke="primary").
///
String resolveSvgColorRoles(String svg, ColorScheme cs) {
  final roles = {
    'primary': cs.primary,
    'onPrimary': cs.onPrimary,
    'primaryContainer': cs.primaryContainer,
    'onPrimaryContainer': cs.onPrimaryContainer,
    'secondary': cs.secondary,
    'onSecondary': cs.onSecondary,
    'secondaryContainer': cs.secondaryContainer,
    'onSecondaryContainer': cs.onSecondaryContainer,
    'tertiary': cs.tertiary,
    'onTertiary': cs.onTertiary,
    'tertiaryContainer': cs.tertiaryContainer,
    'onTertiaryContainer': cs.onTertiaryContainer,
    'error': cs.error,
    'onError': cs.onError,
    'surface': cs.surface,
    'onSurface': cs.onSurface,
    'onSurfaceVariant': cs.onSurfaceVariant,
    'outline': cs.outline,
    'outlineVariant': cs.outlineVariant,
    'onBackground': cs.onSurface,
  };
  var result = svg;
  for (final e in roles.entries) {
    result = result.replaceAll('"${e.key}"', '"${svgHex(e.value)}"');
  }
  return result;
}

/// Converts a [Color] to a CSS hex string (e.g. `#ff0000`).
String svgHex(Color c) {
  final v = c.toARGB32();
  return '#${(v & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
