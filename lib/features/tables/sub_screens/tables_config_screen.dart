import 'dart:async';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

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
    final l10n = AppLocalizations.of(context)!;

    void save(void Function(TablesSettings) mutate) {
      final updated = TablesSettings()
        ..id = cfg.id
        ..owner.target = cfg.owner.target
        ..distanceStartMeter = cfg.distanceStartMeter
        ..distanceEndMeter = cfg.distanceEndMeter
        ..distanceStepMeter = cfg.distanceStepMeter
        ..showZeros = cfg.showZeros
        ..showSubsonicTransition = cfg.showSubsonicTransition
        ..hiddenCols = List<String>.from(cfg.hiddenCols)
        ..showMrad = cfg.showMrad
        ..showMoa = cfg.showMoa
        ..showMil = cfg.showMil
        ..showCmPer100m = cfg.showCmPer100m
        ..showInPer100yd = cfg.showInPer100yd
        ..showInClicks = cfg.showInClicks;

      mutate(updated);
      unawaited(notifier.saveSettings(updated));
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
          ListSectionTile(l10n.tablesConfigSectionDistance),

          _ConstrainedDistanceTile(
            icon: Icons.first_page_outlined,
            label: l10n.tablesConfigDistanceStart,
            rawValueM: cfg.distanceStartMeter,
            constraints: FC.tableRange,
            displayUnit: distanceUnit,
            maxRawM: cfg.distanceEndMeter,
            onChanged: (v) => save((s) => s.distanceStartMeter = v),
          ),

          _ConstrainedDistanceTile(
            icon: Icons.last_page_outlined,
            label: l10n.tablesConfigDistanceEnd,
            rawValueM: cfg.distanceEndMeter,
            constraints: FC.tableRange,
            displayUnit: distanceUnit,
            minRawM: cfg.distanceStartMeter,
            onChanged: (v) => save((s) => s.distanceEndMeter = v),
          ),

          _ConstrainedDistanceTile(
            icon: IconDef.range,
            label: l10n.tablesConfigDistanceStep,
            rawValueM: cfg.distanceStepMeter,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => save((s) => s.distanceStepMeter = v),
          ),

          const TileDivider(),

          // ── Extra tables ───────────────────────────────────────────────
          ListSectionTile(l10n.tablesConfigSectionExtra),

          SwitchListTile(
            secondary: const Icon(Icons.swap_vert_outlined),
            title: Text(l10n.tablesConfigShowZeroCrossingTable),
            value: cfg.showZeros,
            onChanged: (v) => save((s) => s.showZeros = v),
            dense: true,
          ),
          SwitchListTile(
            secondary: const Icon(IconDef.velocity),
            title: Text(l10n.tablesConfigShowSubsonicTransition),
            value: cfg.showSubsonicTransition,
            onChanged: (v) => save((s) => s.showSubsonicTransition = v),
            dense: true,
          ),

          const TileDivider(),
          ListSectionTile(l10n.tablesConfigSectionVisibleColumns),

          for (final col in _columnDefs)
            if (!col.alwaysOn)
              SwitchListTile(
                title: Text(col.labelBuilder(l10n)),
                value: !cfg.hiddenCols.contains(col.id),
                onChanged: (v) => toggleCol(col.id, v),
                dense: true,
              ),

          const TileDivider(),
          ListSectionTile(l10n.tablesConfigSectionAdjustmentColumns),

          SwitchListTile(
            title: Text(l10n.unitMrad),
            value: cfg.showMrad,
            onChanged: (v) => save((s) => s.showMrad = v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitMoa),
            value: cfg.showMoa,
            onChanged: (v) => save((s) => s.showMoa = v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitMil),
            value: cfg.showMil,
            onChanged: (v) => save((s) => s.showMil = v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitCmPer100m),
            value: cfg.showCmPer100m,
            onChanged: (v) => save((s) => s.showCmPer100m = v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitInPer100Yd),
            value: cfg.showInPer100yd,
            onChanged: (v) => save((s) => s.showInPer100yd = v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitClicks),
            value: cfg.showInClicks,
            onChanged: (v) => save((s) => s.showInClicks = v),
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
  final String Function(AppLocalizations l10n) labelBuilder;
  final bool alwaysOn;
  const _ColEntry(this.id, this.labelBuilder, {this.alwaysOn = false});
}

final _columnDefs = [
  _ColEntry('range', (l10n) => l10n.columnRange, alwaysOn: true),
  _ColEntry('time', (l10n) => l10n.columnTime),
  _ColEntry('velocity', (l10n) => l10n.columnVelocity),
  _ColEntry('height', (l10n) => l10n.columnHeight),
  _ColEntry('drop', (l10n) => l10n.columnDrop),
  _ColEntry('adjDrop', (l10n) => l10n.columnDropAngle),
  _ColEntry('wind', (l10n) => l10n.columnWind),
  _ColEntry('adjWind', (l10n) => l10n.columnWindAngle),
  _ColEntry('mach', (l10n) => l10n.columnMach),
  _ColEntry('drag', (l10n) => l10n.columnDrag),
  _ColEntry('energy', (l10n) => l10n.columnEnergy),
];
