import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/unit.dart';

// ─── Table Configuration Screen ───────────────────────────────────────────────

class TableConfigScreen extends ConsumerWidget {
  const TableConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(tablesSettingsProvider);
    final notifier = ref.read(tablesSettingsNotifierProvider.notifier);
    final distanceUnit = ref.watch(unitSettingsProvider).distanceUnit;

    void save(void Function(TablesSettings) mutate) {
      // Створюємо копію з мутаціями
      final updated = TablesSettings()
        ..id = cfg.id
        ..owner.target = cfg.owner.target
        ..distanceEndMeter = cfg.distanceEndMeter
        ..showMil = cfg.showMil
        ..hiddenCols = List<String>.from(cfg.hiddenCols);

      mutate(updated);
      notifier.saveSettings(updated);
    }

    void toggleCol(String colId, bool visible) {
      final hidden = List<String>.from(cfg.hiddenCols);
      if (visible) {
        hidden.remove(colId);
      } else {
        if (!hidden.contains(colId)) hidden.add(colId);
      }
      save((s) => s.hiddenCols = hidden);
    }

    return BaseScreen(
      title: 'Table Configuration',
      isSubscreen: true,
      body: ListView(
        children: [
          // ── Range ──────────────────────────────────────────────────────
          const ListSectionTile('Range'),

          _ConstrainedDistanceTile(
            icon: Icons.first_page_outlined,
            label: 'Start distance',
            rawValueM: cfg.distanceStartMeter,
            constraints: FC.tableRange,
            displayUnit: distanceUnit,
            maxRawM: cfg.distanceEndMeter,
            onChanged: (v) => save((s) => s.distanceStartMeter = v),
          ),

          _ConstrainedDistanceTile(
            icon: Icons.last_page_outlined,
            label: 'End distance',
            rawValueM: cfg.distanceEndMeter,
            constraints: FC.tableRange,
            displayUnit: distanceUnit,
            minRawM: cfg.distanceStartMeter,
            onChanged: (v) => save((s) => s.distanceEndMeter = v),
          ),

          _ConstrainedDistanceTile(
            icon: IconDef.range,
            label: 'Distance step',
            rawValueM: cfg.distanceStepMeter,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => save((s) => s.distanceStepMeter = v),
          ),

          const Divider(height: 1),

          // ── Extra tables ───────────────────────────────────────────────
          const ListSectionTile('Extra'),

          SwitchListTile(
            secondary: const Icon(Icons.swap_vert_outlined),
            title: const Text('Show zero crossings table'),
            value: cfg.showZeros,
            onChanged: (v) => save((s) => s.showZeros = v),
            dense: true,
          ),
          SwitchListTile(
            secondary: const Icon(IconDef.velocity),
            title: const Text('Show subsonic transition'),
            value: cfg.showSubsonicTransition,
            onChanged: (v) => save((s) => s.showSubsonicTransition = v),
            dense: true,
          ),

          const Divider(height: 1),
          const ListSectionTile('Visible columns'),

          for (final col in _columnDefs)
            if (!col.alwaysOn)
              SwitchListTile(
                title: Text(col.label),
                value: !cfg.hiddenCols.contains(col.id),
                onChanged: (v) => toggleCol(col.id, v),
                dense: true,
              ),

          const Divider(height: 1),
          const ListSectionTile('Adjustment columns'),

          SwitchListTile(
            title: const Text('MRAD'),
            value: cfg.showMrad,
            onChanged: (v) => save((s) => s.showMrad = v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MOA'),
            value: cfg.showMoa,
            onChanged: (v) => save((s) => s.showMoa = v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MIL'),
            value: cfg.showMil,
            onChanged: (v) => save((s) => s.showMil = v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('cm/100m'),
            value: cfg.showCmPer100m,
            onChanged: (v) => save((s) => s.showCmPer100m = v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('in/100yd'),
            value: cfg.showInPer100yd,
            onChanged: (v) => save((s) => s.showInPer100yd = v),
            dense: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Distance tile with cross-field constraints (min/max in metres).
class _ConstrainedDistanceTile extends StatelessWidget {
  const _ConstrainedDistanceTile({
    required this.icon,
    required this.label,
    required this.rawValueM,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    this.minRawM,
    this.maxRawM,
  });

  final IconData icon;
  final String label;
  final double rawValueM;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double> onChanged;
  final double? minRawM;
  final double? maxRawM;

  @override
  Widget build(BuildContext context) {
    final effectiveMin =
        minRawM?.clamp(constraints.minRaw, constraints.maxRaw) ??
        constraints.minRaw;
    final effectiveMax =
        maxRawM?.clamp(constraints.minRaw, constraints.maxRaw) ??
        constraints.maxRaw;

    final updatedConstraints = FieldConstraints(
      rawUnit: constraints.rawUnit,
      minRaw: effectiveMin,
      maxRaw: effectiveMax,
      stepRaw: constraints.stepRaw,
      accuracy: constraints.accuracy,
    );

    return UnitValueFieldTile(
      icon: icon,
      title: label,
      rawValue: rawValueM,
      constraints: updatedConstraints,
      displayUnit: displayUnit,
      onChanged: onChanged,
    );
  }
}

// ── Column catalogue ─────────────────────────────────────────────────────────

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
