import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/providers/settings_provider.dart';
import 'package:eballistica/core/models/app_settings.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/features/settings/widgets/settings_helpers.dart';

// ─── Table Configuration Screen ───────────────────────────────────────────────

class TableConfigScreen extends ConsumerWidget {
  const TableConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final cfg = settings.tableConfig;
    final notifier = ref.read(settingsProvider.notifier);
    final units = ref.watch(unitSettingsProvider);

    void save(TableConfig updated) => notifier.updateTableConfig(updated);

    return BaseScreen(
      title: 'Table Configuration',
      isSubscreen: true,
      body: ListView(
        children: [
          // ── Range ──────────────────────────────────────────────────────
          const SettingsSectionLabel('Range'),

          _DistanceTile(
            icon: Icons.first_page_outlined,
            label: 'Start distance',
            valueM: cfg.startM,
            units: units.distance,
            constraints: FC.tableRange,
            maxValueM: cfg.endM,
            onChanged: (v) => save(cfg.copyWith(startM: v)),
          ),
          _DistanceTile(
            icon: Icons.last_page_outlined,
            label: 'End distance',
            valueM: cfg.endM,
            units: units.distance,
            constraints: FC.tableRange,
            minValueM: cfg.startM,
            onChanged: (v) => save(cfg.copyWith(endM: v)),
          ),

          _DistanceTile(
            icon: Icons.straighten_outlined,
            label: 'Distance step',
            valueM: cfg.stepM,
            units: units.distance,
            constraints: FC.distanceStep,
            onChanged: (v) => save(cfg.copyWith(stepM: v)),
          ),

          const Divider(height: 1),

          // ── Extra tables ───────────────────────────────────────────────
          const SettingsSectionLabel('Extra'),

          SwitchListTile(
            secondary: const Icon(Icons.swap_vert_outlined),
            title: const Text(
              'Show zero crossings table',
              style: TextStyle(fontSize: 14),
            ),
            value: cfg.showZeros,
            onChanged: (v) => save(cfg.copyWith(showZeros: v)),
            dense: true,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.speed_outlined),
            title: const Text(
              'Show subsonic transition',
              style: TextStyle(fontSize: 14),
            ),
            value: cfg.showSubsonicTransition,
            onChanged: (v) => save(cfg.copyWith(showSubsonicTransition: v)),
            dense: true,
          ),

          const Divider(height: 1),

          // ── Columns ────────────────────────────────────────────────────
          const SettingsSectionLabel('Table columns'),

          // Drop / Windage unit override
          _UnitOverrideTile(
            label: 'Drop / Windage unit',
            current: cfg.dropUnit,
            globalUnit: units.drop,
            options: const [
              Unit.meter,
              Unit.centimeter,
              Unit.millimeter,
              Unit.inch,
              Unit.foot,
            ],
            onChanged: (u) => save(cfg.copyWith(dropUnit: u)),
          ),

          // Adjustment mode
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjustment display',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Current unit')),
                      ButtonSegment(
                        value: true,
                        label: Text('All selected units'),
                      ),
                    ],
                    selected: {cfg.adjAllUnits},
                    onSelectionChanged: (s) =>
                        save(cfg.copyWith(adjAllUnits: s.first)),
                    expandedInsets: EdgeInsets.zero,
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _UnitOverrideTile(
            label: 'Adjustment unit',
            current: cfg.adjUnit,
            globalUnit: units.adjustment,
            options: const [
              Unit.mil,
              Unit.moa,
              Unit.mRad,
              Unit.cmPer100m,
              Unit.inPer100Yd,
            ],
            enabled: !cfg.adjAllUnits,
            onChanged: (u) => save(cfg.copyWith(adjUnit: u)),
          ),

          const Divider(height: 1),
          const SettingsSectionLabel('Visible columns'),

          for (final col in _columnDefs)
            if (!col.alwaysOn)
              SwitchListTile(
                title: Text(col.label, style: const TextStyle(fontSize: 14)),
                value: !cfg.hiddenCols.contains(col.id),
                onChanged: (v) {
                  final hidden = Set<String>.from(cfg.hiddenCols);
                  if (v) {
                    hidden.remove(col.id);
                  } else {
                    hidden.add(col.id);
                  }
                  save(cfg.copyWith(hiddenCols: hidden));
                },
                dense: true,
              ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
}

// ── Distance tile with text field dialog ──────────────────────────────────────

class _DistanceTile extends StatelessWidget {
  const _DistanceTile({
    required this.icon,
    required this.label,
    required this.valueM,
    required this.units,
    required this.constraints,
    required this.onChanged,
    this.minValueM,
    this.maxValueM,
  });

  final IconData icon;
  final String label;
  final double valueM;
  final Unit units;
  final FieldConstraints constraints;
  final ValueChanged<double> onChanged;

  /// Cross-field lower bound (metres). Overrides constraints.minRaw if set.
  final double? minValueM;

  /// Cross-field upper bound (metres). Overrides constraints.maxRaw if set.
  final double? maxValueM;

  @override
  Widget build(BuildContext context) {
    final acc = constraints.accuracyFor(units);
    final disp = Distance(valueM, Unit.meter).in_(units);
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        '${disp.toStringAsFixed(acc)} ${units.symbol}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dense: true,
      onTap: () => _showDialog(context, disp, acc),
    );
  }

  void _showDialog(BuildContext context, double currentDisp, int acc) {
    final ctrl = TextEditingController(text: currentDisp.toStringAsFixed(acc));
    final effectiveMinM = (minValueM != null && minValueM! > constraints.minRaw)
        ? minValueM!
        : constraints.minRaw;
    final effectiveMaxM = (maxValueM != null && maxValueM! < constraints.maxRaw)
        ? maxValueM!
        : constraints.maxRaw;
    final minDisp = Distance(effectiveMinM, Unit.meter).in_(units);
    final maxDisp = Distance(effectiveMaxM, Unit.meter).in_(units);
    final rangeMsg =
        '${minDisp.toStringAsFixed(acc)}–${maxDisp.toStringAsFixed(acc)} ${units.symbol}';

    String? error;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('$label (${units.symbol})'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: units.symbol,
              errorText: error,
            ),
            onChanged: (t) {
              setState(() {
                final v = double.tryParse(t.replaceAll(',', '.'));
                if (v == null) {
                  error = 'Invalid number';
                } else {
                  final rawM = Distance(v, units).in_(Unit.meter);
                  error = (rawM < effectiveMinM || rawM > effectiveMaxM)
                      ? rangeMsg
                      : null;
                }
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: error != null
                  ? null
                  : () {
                      final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                      if (v != null) {
                        final rawM = Distance(v, units).in_(Unit.meter);
                        onChanged(rawM.clamp(effectiveMinM, effectiveMaxM));
                      }
                      Navigator.pop(ctx);
                    },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unit override tile ────────────────────────────────────────────────────────

class _UnitOverrideTile extends StatelessWidget {
  const _UnitOverrideTile({
    required this.label,
    required this.current,
    required this.globalUnit,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final Unit? current;
  final Unit globalUnit;
  final List<Unit> options;
  final ValueChanged<Unit?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effective = current ?? globalUnit;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? null : cs.onSurface.withAlpha(80),
        ),
      ),
      subtitle: current == null
          ? Text(
              'Global (${globalUnit.symbol})',
              style: TextStyle(
                fontSize: 11,
                color: enabled ? null : cs.onSurface.withAlpha(60),
              ),
            )
          : null,
      trailing: Text(
        effective.symbol,
        style: TextStyle(
          color: enabled ? cs.primary : cs.onSurface.withAlpha(80),
          fontWeight: FontWeight.w600,
        ),
      ),
      dense: true,
      onTap: enabled ? () => _showPicker(context, effective) : null,
    );
  }

  void _showPicker(BuildContext context, Unit selected) {
    // Add "Global" option at the top
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(label),
        children: [
          RadioGroup<Unit?>(
            groupValue: current,
            onChanged: (_) {
              onChanged(null);
              Navigator.pop(ctx);
            },
            child: RadioListTile<Unit?>(
              value: null,
              title: Text('Global (${globalUnit.symbol})'),
              dense: true,
            ),
          ),
          const Divider(height: 1),
          ...options.map(
            (u) => RadioGroup<Unit?>(
              groupValue: current,
              onChanged: (_) {
                onChanged(u);
                Navigator.pop(ctx);
              },
              child: RadioListTile<Unit?>(
                value: u,
                title: Text('${u.label}  (${u.symbol})'),
                dense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Column catalogue (mirrors trajectory_table.dart) ─────────────────────────

class _ColEntry {
  final String id;
  final String label;
  final bool alwaysOn;
  const _ColEntry(this.id, this.label, {this.alwaysOn = false});
}

const _columnDefs = [
  _ColEntry('range', 'Range', alwaysOn: true),
  _ColEntry('time', 'Time'),
  _ColEntry('velocity', 'Velocity'),
  _ColEntry('height', 'Height'),
  _ColEntry('drop', 'Drop (slant height)'),
  _ColEntry('adjDrop', 'Drop adjustment'),
  _ColEntry('wind', 'Windage'),
  _ColEntry('adjWind', 'Windage adjustment'),
  _ColEntry('mach', 'Mach'),
  _ColEntry('drag', 'Drag coefficient'),
  _ColEntry('energy', 'Energy'),
];
