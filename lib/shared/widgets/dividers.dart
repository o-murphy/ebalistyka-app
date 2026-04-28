import 'package:ebalistyka/shared/constants/ui_dimensions.dart';
import 'package:flutter/material.dart';

/// Thin 1px divider used between list tiles.
class TileDivider extends StatelessWidget {
  const TileDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: kTileDividerHeight);
}

/// Taller 24px divider used between sections.
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: kSectionDividerHeight);
}
