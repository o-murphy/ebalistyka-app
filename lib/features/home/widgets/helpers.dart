import 'package:ebalistyka/features/home/home_ui_state.dart';
import 'package:flutter/material.dart';

Widget zeroOffsetMessageLine(ReticleUiState rs, ColorScheme cs, TextTheme tt) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      rs.zeroOffsetMessageLine!,
      textAlign: TextAlign.center,
      softWrap: true,
      overflow: TextOverflow.visible,
      style: tt.labelMedium?.copyWith(color: cs.tertiary),
    ),
  );
}

Widget adjustedMessageLine(ReticleUiState rs, ColorScheme cs, TextTheme tt) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      rs.adjustedMessageLine!,
      textAlign: TextAlign.center,
      softWrap: true,
      overflow: TextOverflow.visible,
      style: tt.labelMedium?.copyWith(color: cs.tertiary),
    ),
  );
}
