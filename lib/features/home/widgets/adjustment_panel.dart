import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:flutter/material.dart';

class AdjustmentsDisplayPanel extends StatelessWidget {
  const AdjustmentsDisplayPanel({
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Базові розміри для одного рядка тексту
        final baseWidth = 180.0;
        final baseHeight = 120.0;

        // Розраховуємо scaleFactor на основі доступного простору
        final widthScale = availableWidth / baseWidth;
        final heightScale = availableHeight / baseHeight;

        // Для вертикального режиму важливіше висота
        final scaleFactor = displayVertical
            ? heightScale.clamp(0.7, 2.0)
            : widthScale.clamp(0.7, 2.0);

        // Стилі з масштабуванням
        final headerStyle = tt.titleSmall?.copyWith(
          color: cs.onSurface.withAlpha(180),
          fontWeight: FontWeight.w600,
          fontSize: 8 * scaleFactor,
        );

        final dirStyle = tt.titleMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
          fontSize: 10 * scaleFactor,
        );

        final valStyle = tt.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 12 * scaleFactor,
        );

        final unitStyle = tt.bodyMedium?.copyWith(
          color: cs.onSurface.withAlpha(140),
          fontSize: 6 * scaleFactor,
        );

        final padding = 8.0;
        final spacing = 4.0;
        final dividerSpacing = 8.0;

        Widget valueRow(AdjustmentValue v) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(v.absValue.toStringAsFixed(v.decimals), style: valStyle),
              SizedBox(width: 4),
              Text(v.symbol, style: unitStyle),
            ],
          ),
        );

        Widget sectionHeader(String label, String dir) => Padding(
          padding: EdgeInsets.only(bottom: 4 * spacing),
          child: Row(
            children: [
              Text(label, style: headerStyle),
              if (dir.isNotEmpty) ...[
                SizedBox(width: 4 * spacing),
                Text(dir, style: dirStyle),
              ],
            ],
          ),
        );

        Widget buildSection(
          String label,
          String dir,
          List<AdjustmentValue> values,
        ) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [sectionHeader(label, dir), ...values.map(valueRow)],
          );
        }

        final int rowCount = adjustment.elevation.length + 1;

        final content = displayVertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSection('Drop', _elevDir(), adjustment.elevation),
                  SizedBox(height: dividerSpacing),
                  Container(
                    height: 1,
                    width: 80 * scaleFactor,
                    color: cs.outline.withAlpha(100),
                  ),
                  SizedBox(height: dividerSpacing),
                  buildSection('Windage', _windDir(), adjustment.windage),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildSection('Drop', _elevDir(), adjustment.elevation),
                  SizedBox(width: dividerSpacing),
                  Container(
                    height: 20 * rowCount * scaleFactor,
                    width: 1,
                    color: cs.outline.withAlpha(100),
                  ),
                  SizedBox(width: dividerSpacing),
                  buildSection('Windage', _windDir(), adjustment.windage),
                ],
              );

        // Використовуємо Center та FittedBox без додаткових контейнерів
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
