import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return fmt.elevDir(pos);
  }

  String _windDir() {
    if (adjustment.windage.isEmpty) return '';
    final pos = adjustment.windage.first.isPositive;
    return fmt.windDir(pos);
  }

  Widget _buildEmpty(
    BuildContext context,
    TextTheme tt,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.adjustmentDisplayDisabled,
            style: tt.bodyMedium?.copyWith(
              color: cs.error,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () => context.push(Routes.settingsAdjustment),
            style: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.adjustmentDisplayDisabledHint,
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                const Icon(IconDef.settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplay(
    BuildContext context,
    TextTheme tt,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        final baseWidth = 180.0;
        final baseHeight = 120.0;

        final widthScale = availableWidth / baseWidth;
        final heightScale = availableHeight / baseHeight;

        final scaleFactor = displayVertical
            ? heightScale.clamp(0.7, 2.0)
            : widthScale.clamp(0.7, 2.0);

        final headerStyle = tt.titleSmall?.copyWith(
          color: cs.onSurface.withAlpha(180),
          fontWeight: FontWeight.w600,
          fontSize: 8 * scaleFactor,
        );

        final dirStyle = tt.titleMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12 * scaleFactor,
        );

        final valStyle = tt.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 12 * scaleFactor,
        );

        final unitStyle = tt.bodyMedium?.copyWith(
          color: cs.onSurface.withAlpha(140),
          fontWeight: FontWeight.w700,
          fontSize: 10 * scaleFactor,
        );

        final padding = 8.0;
        final spacing = 4.0;
        final dividerSpacing = 8.0;

        Widget valueRow(AdjustmentValue v) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                v.absValue.toStringAsFixed(v.decimals),
                style: valStyle?.copyWith(color: cs.primary),
              ),
              SizedBox(width: 8),
              Text(
                v.isClicks ? l10n.nClicks(v.absValue.round()) : v.symbol,
                style: unitStyle,
              ),
            ],
          ),
        );

        Widget sectionHeader(String label, String dir) => Padding(
          padding: EdgeInsets.only(bottom: 4 * spacing),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (dir.isNotEmpty) ...[
                Text(dir, style: dirStyle),
                SizedBox(width: 4 * spacing),
              ],
              Text(label, style: headerStyle),
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
                  buildSection(
                    l10n.holdoversVertical,
                    _elevDir(),
                    adjustment.elevation,
                  ),
                  SizedBox(height: dividerSpacing),
                  Container(
                    height: 1,
                    width: 100 * scaleFactor,
                    color: cs.outline.withAlpha(100),
                  ),
                  SizedBox(height: dividerSpacing),
                  buildSection(
                    l10n.holdoversHorizontal,
                    _windDir(),
                    adjustment.windage,
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildSection(
                    l10n.holdoversVertical,
                    _elevDir(),
                    adjustment.elevation,
                  ),
                  SizedBox(width: dividerSpacing),
                  Container(
                    height: 20 * rowCount * scaleFactor,
                    width: 1,
                    color: cs.outline.withAlpha(100),
                  ),
                  SizedBox(width: dividerSpacing),
                  buildSection(
                    l10n.holdoversHorizontal,
                    _windDir(),
                    adjustment.windage,
                  ),
                ],
              );

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

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return isEmpty
        ? _buildEmpty(context, tt, cs, l10n)
        : _buildDisplay(context, tt, cs, l10n);
  }
}
