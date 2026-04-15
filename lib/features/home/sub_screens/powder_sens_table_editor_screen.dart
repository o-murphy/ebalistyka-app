import 'package:bclibc_ffi/bclibc.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
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
class PowderSensTableEditorScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSettingsProvider);
    final vUnit = units.velocityUnit;
    final tUnit = units.temperatureUnit;
    final vAcc = FC.muzzleVelocity.accuracyFor(vUnit);
    final tAcc = FC.temperature.accuracyFor(tUnit);

    // Local vars for Dart nullable field promotion
    final mvMps = referenceMvMps;
    final refTempC = referenceTempC;

    final initialRows = initialTable?.map((r) {
      final tDisplay = Temperature.celsius(r.tempC).in_(tUnit);
      final vDisplay = Velocity.mps(r.vMps).in_(vUnit);
      return (tDisplay.toStringAsFixed(tAcc), vDisplay.toStringAsFixed(vAcc));
    }).toList();

    return _PowderSensEditorScreen(
      initialRows: initialRows,
      col1Header: 'T (${tUnit.symbol})',
      col2Header: 'V (${vUnit.symbol})',
      // Pass reference values in display units for live preview
      referenceMvDisplay: mvMps != null && mvMps > 0
          ? Velocity.mps(mvMps).in_(vUnit)
          : null,
      referenceTDisplay: refTempC != null
          ? Temperature.celsius(refTempC).in_(tUnit)
          : null,
      vUnit: vUnit,
      tUnit: tUnit,
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

// ── Internal screen ───────────────────────────────────────────────────────────

class _PowderSensEditorScreen extends StatefulWidget {
  const _PowderSensEditorScreen({
    required this.col1Header,
    required this.col2Header,
    required this.onSave,
    required this.onDiscard,
    required this.vUnit,
    required this.tUnit,
    this.initialRows,
    this.referenceMvDisplay,
    this.referenceTDisplay,
  });

  final String col1Header;
  final String col2Header;
  final List<(String, String)>? initialRows;

  /// Reference MV in the *display* velocity unit — for live preview.
  final double? referenceMvDisplay;

  /// Reference temperature in the *display* temperature unit — for live preview.
  final double? referenceTDisplay;

  final Unit vUnit;
  final Unit tUnit;

  /// Receives filtered + sorted (tempDisplay, vDisplay) raw double pairs.
  final void Function(List<(double, double)>) onSave;
  final VoidCallback onDiscard;

  @override
  State<_PowderSensEditorScreen> createState() =>
      _PowderSensEditorScreenState();
}

class _PowderSensEditorScreenState extends State<_PowderSensEditorScreen> {
  late final List<TextEditingController> _tCtrls;
  late final List<TextEditingController> _vCtrls;

  @override
  void initState() {
    super.initState();
    _tCtrls = List.generate(
      _kPowderSensRowCount,
      (_) => TextEditingController(),
    );
    _vCtrls = List.generate(
      _kPowderSensRowCount,
      (_) => TextEditingController(),
    );
    final rows = widget.initialRows;
    if (rows != null && rows.isNotEmpty) {
      final count = rows.length.clamp(0, _kPowderSensRowCount);
      for (var i = 0; i < count; i++) {
        _tCtrls[i].text = rows[i].$1;
        _vCtrls[i].text = rows[i].$2;
      }
    } else {
      // Pre-fill row 0 with the reference MV / T₀ so the user starts
      // from the known reference point and only needs to add deltas.
      final refT = widget.referenceTDisplay;
      final refV = widget.referenceMvDisplay;
      if (refT != null && refV != null && refV > 0) {
        final tAcc = FC.temperature.accuracyFor(widget.tUnit);
        final vAcc = FC.muzzleVelocity.accuracyFor(widget.vUnit);
        _tCtrls[0].text = refT.toStringAsFixed(tAcc);
        _vCtrls[0].text = refV.toStringAsFixed(vAcc);
      }
    }
    for (final c in [..._tCtrls, ..._vCtrls]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [..._tCtrls, ..._vCtrls]) {
      c.removeListener(_onChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  // ── Live sensitivity preview ──────────────────────────────────────────────

  /// Returns the averaged pairwise coefficient, 0 for a single valid row,
  /// or null for no valid rows.
  ///
  /// Works in *display* units — unit-agnostic since [calcPowderSensCoeff]
  /// uses only ratios and differences.
  double? _computePreview() {
    final valid = <(double, double)>[];
    for (var i = 0; i < _kPowderSensRowCount; i++) {
      final t = double.tryParse(_tCtrls[i].text.trim());
      final v = double.tryParse(_vCtrls[i].text.trim()) ?? 0.0;
      if (t == null || v <= 0) continue;
      valid.add((t, v));
    }
    if (valid.isEmpty) return null;
    if (valid.length == 1) return 0.0;

    valid.sort((a, b) => a.$1.compareTo(b.$1));
    final coeffs = <double>[];
    for (var i = 0; i < valid.length - 1; i++) {
      final c = calcPowderSensCoeff(
        valid[i].$2,
        valid[i].$1,
        valid[i + 1].$2,
        valid[i + 1].$1,
      );
      if (c != null) coeffs.add(c);
    }
    if (coeffs.isEmpty) return 0.0;
    return coeffs.reduce((a, b) => a + b) / coeffs.length;
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  void _handleSave() {
    final rows = <(double, double)>[];
    for (var i = 0; i < _kPowderSensRowCount; i++) {
      final t = double.tryParse(_tCtrls[i].text.trim());
      final v = double.tryParse(_vCtrls[i].text.trim()) ?? 0.0;
      if (t == null || v <= 0) continue;
      rows.add((t, v));
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    widget.onSave(rows);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final preview = _computePreview();

    return BaseScreen(
      title: 'Powder Sensitivity Table',
      isSubscreen: true,
      showBack: false,
      bottomBar: _ActionBar(onDiscard: widget.onDiscard, onSave: _handleSave),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _SensitivityPreview(sensitivity: preview),
          const SizedBox(height: 8),
          _Header(col1: widget.col1Header, col2: widget.col2Header),
          const Divider(height: 16),
          for (var i = 0; i < _kPowderSensRowCount; i++) ...[
            _RowEditor(index: i, tCtrl: _tCtrls[i], vCtrl: _vCtrls[i]),
            if (i < _kPowderSensRowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Text(
            'Rows with empty or non-positive velocity are ignored.\n'
            'Temperature may be negative, zero, or positive.\n'
            'Sensitivity is averaged across all valid pairs.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SensitivityPreview extends StatelessWidget {
  const _SensitivityPreview({required this.sensitivity});

  final double? sensitivity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = sensitivity == null;

    final String label;
    if (sensitivity == null) {
      label = 'No measurements yet';
    } else {
      final acc = FC.powderSensitivity.accuracyFor(Unit.percent);
      final pct = Ratio.fraction(sensitivity!).in_(Unit.percent);
      label = '${pct.toStringAsFixed(acc)} %/15°C';
    }

    return Card(
      color: isError
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculated sensitivity',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isError
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isError
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
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

class _Header extends StatelessWidget {
  const _Header({required this.col1, required this.col2});
  final String col1;
  final String col2;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        const SizedBox(width: 32),
        Expanded(
          child: Text(col1, style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(col2, style: style, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _RowEditor extends StatelessWidget {
  const _RowEditor({
    required this.index,
    required this.tCtrl,
    required this.vCtrl,
  });

  final int index;
  final TextEditingController tCtrl;
  final TextEditingController vCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: tCtrl,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: vCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onDiscard, required this.onSave});

  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton(onPressed: onDiscard, child: const Text('Discard')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: onSave, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
