// ─── Adjustment panel ─────────────────────────────────────────────────────────

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:flutter/material.dart';

class AdjPanel extends StatelessWidget {
  const AdjPanel({
    required this.adjustment,
    required this.fmt,
    required this.isEmpty,
    this.displayVertical = false,
    super.key,
  });

  final AdjustmentData adjustment;
  final AdjustmentDisplayFormat fmt;
  final bool isEmpty;
  final bool displayVertical;

  String _elevDir() {
    if (adjustment.elevation.isEmpty) return '';
    final pos = adjustment.elevation.first.isPositive;
    return switch (fmt) {
      AdjustmentDisplayFormat.arrows => pos ? '↑' : '↓',
      AdjustmentDisplayFormat.signs => pos ? '+' : '−',
      AdjustmentDisplayFormat.letters => pos ? 'U' : 'D',
    };
  }

  String _windDir() {
    if (adjustment.windage.isEmpty) return '';
    final pos = adjustment.windage.first.isPositive;
    return switch (fmt) {
      AdjustmentDisplayFormat.arrows => pos ? '→' : '←',
      AdjustmentDisplayFormat.signs => pos ? '+' : '−',
      AdjustmentDisplayFormat.letters => pos ? 'R' : 'L',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    if (isEmpty) {
      return Center(child: Text('Enable units...', style: tt.bodySmall));
    }

    final headerStyle = tt.labelMedium!.copyWith(
      color: cs.onSurface.withAlpha(180),
      fontWeight: FontWeight.w600,
    );
    final dirStyle = tt.titleSmall!.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );
    final valStyle = tt.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    final unitStyle = tt.bodySmall!.copyWith(
      color: cs.onSurface.withAlpha(140),
    );

    Widget valueRow(AdjustmentValue v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              v.absValue.toStringAsFixed(v.decimals),
              style: valStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              v.symbol,
              style: unitStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    Widget sectionHeader(String label, String dir) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            label,
            style: headerStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (dir.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(dir, style: dirStyle, overflow: TextOverflow.ellipsis),
          ),
        ],
      ],
    );

    // Створюємо вертикальний блок для Drop або Windage
    Widget buildSection(
      String label,
      String dir,
      List<AdjustmentValue> values,
    ) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          sectionHeader(label, dir),
          const SizedBox(height: 2),
          ...values.map(valueRow),
        ],
      );
    }

    // Якщо вертикальне відображення
    if (displayVertical) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSection('Drop', _elevDir(), adjustment.elevation),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 12),
            buildSection('Windage', _windDir(), adjustment.windage),
          ],
        ),
      );
    }

    // Горизонтальне відображення
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSection('Drop', _elevDir(), adjustment.elevation),
          const SizedBox(width: 16),
          const VerticalDivider(width: 1, thickness: 1),
          const SizedBox(width: 16),
          buildSection('Windage', _windDir(), adjustment.windage),
        ],
      ),
    );
  }
}
