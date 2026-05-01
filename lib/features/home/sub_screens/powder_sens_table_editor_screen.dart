import 'package:bclibc_ffi/bclibc.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/two_column_table_editor.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _kPowderSensRowCount = 5;

typedef PowderSensTableResult = ({
  List<({double tempC, double vMps})> table,
  double? sensitivity,
});

/// Powder-sensitivity measurement table editor (Temperature → Velocity).
///
/// Returns [PowderSensTableResult] via [context.pop]:
///   - `table`       — saved rows (v ≤ 0 filtered out, sorted ascending by T)
///   - `sensitivity` — arithmetic mean of `calcPowderSensCoeff` for all
///                     valid pairs; `null` if no valid pairs exist
///   - whole result `null` → discarded (no change)
class PowderSensTableEditorScreen extends ConsumerStatefulWidget {
  const PowderSensTableEditorScreen({
    this.initialTable,
    this.referenceMvMps,
    this.referenceTempC,
    super.key,
  });

  final List<({double tempC, double vMps})>? initialTable;

  /// Reference muzzle velocity in m/s (`ammo.muzzleVelocityMps`).
  final double? referenceMvMps;

  /// Reference powder temperature in °C (`ammo.muzzleVelocityTemperatureC`).
  final double? referenceTempC;

  @override
  ConsumerState<PowderSensTableEditorScreen> createState() =>
      _PowderSensTableEditorScreenState();
}

class _PowderSensTableEditorScreenState
    extends ConsumerState<PowderSensTableEditorScreen> {
  double? _preview;

  // ── Live preview ──────────────────────────────────────────────────────────

  void _onRowsChanged(List<(double, double)> rows) {
    setState(() => _preview = _computePreview(rows));
  }

  /// Computes averaged pairwise powder-sensitivity coefficient from display-unit
  /// pairs (tempDisplay, vDisplay). Unit-agnostic: [calcPowderSensCoeff] uses
  /// only ratios and differences.
  static double? _computePreview(List<(double, double)> rows) {
    if (rows.isEmpty) return null;
    if (rows.length == 1) return 0.0;

    final sorted = [...rows]..sort((a, b) => a.$1.compareTo(b.$1));
    final coeffs = <double>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final c = calcPowderSensCoeff(
        sorted[i].$2,
        sorted[i].$1,
        sorted[i + 1].$2,
        sorted[i + 1].$1,
      );
      if (c != null) coeffs.add(c);
    }
    if (coeffs.isEmpty) return 0.0;
    return coeffs.reduce((a, b) => a + b) / coeffs.length;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSettingsProvider);
    final l10n = AppLocalizations.of(context)!;
    final vUnit = units.velocityUnit;
    final tUnit = units.temperatureUnit;
    final vAcc = FC.muzzleVelocity.accuracyFor(vUnit);
    final tAcc = FC.temperature.accuracyFor(tUnit);

    // Local vars for Dart nullable field promotion
    final mvMps = widget.referenceMvMps;
    final refTempC = widget.referenceTempC;

    final initialRows = widget.initialTable?.map((r) {
      final tDisplay = Temperature.celsius(r.tempC).in_(tUnit);
      final vDisplay = Velocity.mps(r.vMps).in_(vUnit);
      return (tDisplay.toStringAsFixed(tAcc), vDisplay.toStringAsFixed(vAcc));
    }).toList();

    // Pre-fill row 0 with the reference MV / T₀ when no existing table.
    List<(String, String)>? prefilled = initialRows;
    if ((prefilled == null || prefilled.isEmpty) &&
        mvMps != null &&
        mvMps > 0 &&
        refTempC != null) {
      final tDisplay = Temperature.celsius(refTempC).in_(tUnit);
      final vDisplay = Velocity.mps(mvMps).in_(vUnit);
      prefilled = [
        (tDisplay.toStringAsFixed(tAcc), vDisplay.toStringAsFixed(vAcc)),
      ];
    }

    return TwoColumnTableEditorScreen(
      title: l10n.powderSensTableEditorTitle,
      rowCount: _kPowderSensRowCount,
      col1Header: '${l10n.temperature} (${tUnit.localizedSymbol(l10n)})',
      col2Header: '${l10n.columnVelocity} (${vUnit.localizedSymbol(l10n)})',
      col1Hint: '0',
      col2Hint: '0',
      initialRows: prefilled,
      sortAscending: true,
      col1Signed: true,
      col1RequirePositive: false,
      headerChild: _SensitivityPreview(sensitivity: _preview),
      onRowsParsed: _onRowsChanged,
      footerText: l10n.nonPositiveRowsHint,
      onSave: (rawRows) {
        final table = rawRows
            .map(
              (r) => (
                tempC: Temperature(r.$1, tUnit).in_(Unit.celsius),
                vMps: Velocity(r.$2, vUnit).in_(Unit.mps),
              ),
            )
            .toList();

        double? sensitivity;
        if (table.length == 1) {
          sensitivity = 0.0;
        } else if (table.length >= 2) {
          final sorted = [...table]..sort((a, b) => a.tempC.compareTo(b.tempC));
          final coeffs = <double>[];
          for (var i = 0; i < sorted.length - 1; i++) {
            final c = calcPowderSensCoeff(
              sorted[i].vMps,
              sorted[i].tempC,
              sorted[i + 1].vMps,
              sorted[i + 1].tempC,
            );
            if (c != null) coeffs.add(c);
          }
          sensitivity = coeffs.isEmpty
              ? 0.0
              : coeffs.reduce((a, b) => a + b) / coeffs.length;
        }

        context.pop<PowderSensTableResult>((
          table: table,
          sensitivity: sensitivity,
        ));
      },
      onDiscard: () => context.pop(null),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SensitivityPreview extends StatelessWidget {
  const _SensitivityPreview({required this.sensitivity});

  final double? sensitivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);
    final l10n = AppLocalizations.of(context)!;

    final isError = sensitivity == null;

    final String label;
    if (sensitivity == null) {
      label = l10n.noMeasurementsYet;
    } else {
      final acc = FC.powderSensitivity.accuracyFor(Unit.percent);
      final pct = Ratio.fraction(sensitivity!).in_(Unit.percent);
      label = '${pct.toStringAsFixed(acc)} %/15°C';
    }

    return Card(
      color: isError ? cs.errorContainer : cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.calculatedSensitivity,
                    style: tt.labelMedium?.copyWith(
                      color: isError
                          ? cs.onErrorContainer
                          : cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: tt.titleMedium?.copyWith(
                      color: isError
                          ? cs.onErrorContainer
                          : cs.onPrimaryContainer,
                      fontFamily: isError ? null : 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
