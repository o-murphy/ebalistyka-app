import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/models/formatted_row.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;

// ── State ────────────────────────────────────────────────────────────────────

sealed class TrajectoryTablesUiState {
  const TrajectoryTablesUiState();
}

class TrajectoryTablesUiLoading extends TrajectoryTablesUiState {
  const TrajectoryTablesUiLoading();
}

class TrajectoryTablesUiEmpty extends TrajectoryTablesUiState {
  const TrajectoryTablesUiEmpty();
}

class TrajectoryTablesUiReady extends TrajectoryTablesUiState {
  final FormattedTableData? zeroCrossings;
  final FormattedTableData mainTable;
  final bool zeroCrossingEnabled;

  const TrajectoryTablesUiReady({
    this.zeroCrossings,
    required this.mainTable,
    this.zeroCrossingEnabled = false,
  });
}

class TrajectoryTablesUiError extends TrajectoryTablesUiState {
  final String message;
  const TrajectoryTablesUiError(this.message);
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class TrajectoryTablesViewModel extends AsyncNotifier<TrajectoryTablesUiState> {
  @override
  Future<TrajectoryTablesUiState> build() async =>
      const TrajectoryTablesUiLoading();

  Future<void> recalculate() async {
    final ctx = ref.read(shotContextProvider).value;
    final tablesSettings = ref.read(tablesSettingsProvider);
    final units = ref.read(unitSettingsProvider);
    final formatter = ref.read(unitFormatterProvider);

    if (ctx == null) {
      state = const AsyncData(TrajectoryTablesUiEmpty());
      return;
    }

    final profile = ctx.profile;
    final conditions = ctx.conditions;

    if (profile.ammo.target == null) {
      state = const AsyncData(TrajectoryTablesUiEmpty());
      return;
    }

    if (state.value is! TrajectoryTablesUiReady) {
      state = const AsyncData(TrajectoryTablesUiLoading());
    }

    try {
      final opts = TableCalcOptions(
        startM: tablesSettings.distanceStartMeter,
        endM: tablesSettings.distanceEndMeter,
        stepM: tablesSettings.distanceStepMeter < 1.0
            ? tablesSettings.distanceStepMeter
            : 1.0,
      );

      final result = await ref
          .read(ballisticsServiceProvider)
          .calculateTable(profile, conditions, opts);

      final uiState = _buildReadyState(
        profile: profile,
        conditions: conditions,
        tablesSettings: tablesSettings,
        units: units,
        formatter: formatter,
        result: result,
      );

      state = AsyncData(uiState);
    } catch (e) {
      state = AsyncData(TrajectoryTablesUiError(e.toString()));
    }
  }

  // ── Private builders ───────────────────────────────────────────────────────

  TrajectoryTablesUiReady _buildReadyState({
    required Profile profile,
    required ShootingConditions conditions,
    required TablesSettings tablesSettings,
    required UnitSettings units,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) {
    final hit = result.hitResult;

    final filtered = _filterTraj(
      hit.trajectory,
      tablesSettings.distanceStartMeter,
      tablesSettings.distanceEndMeter,
      tablesSettings.distanceStepMeter,
    );

    final zeroDistM = profile.ammo.target!.zeroDistanceMeter;
    final mainTable = _buildTable(
      filtered,
      units,
      tablesSettings,
      zeroDistM: zeroDistM,
    );

    FormattedTableData? zeroCrossings;
    if (tablesSettings.showZeros) {
      final zeros = hit.zeros;
      if (zeros.isNotEmpty) {
        zeroCrossings = _buildTable(
          zeros,
          units,
          tablesSettings,
          isZeroTable: true,
        );
      }
    }

    return TrajectoryTablesUiReady(
      zeroCrossings: zeroCrossings,
      mainTable: mainTable,
      zeroCrossingEnabled: tablesSettings.showZeros,
    );
  }

  FormattedTableData _buildTable(
    List<bclibc.TrajectoryData> rows,
    UnitSettings units,
    TablesSettings tablesSettings, {
    bool isZeroTable = false,
    double? zeroDistM,
  }) {
    final hidden = tablesSettings.hiddenCols;
    final adjUnits = tablesSettings.enabledAdjUnits;

    final distUnit = units.distanceUnit;
    final velUnit = units.velocityUnit;
    final dropUnit = units.dropUnit;
    final energyUnit = units.energyUnit;

    final colDefs =
        <
          (
            String,
            String,
            String Function(Dimension?),
            double? Function(bclibc.TrajectoryData),
            int,
          )
        >[
          (
            'range',
            'Range',
            (_) => distUnit.symbol,
            (r) => r.distance.in_(distUnit),
            FC.targetDistance.accuracyFor(distUnit),
          ),
          if (!hidden.contains('time'))
            ('time', 'Time', (_) => 's', (r) => r.time, 3),
          if (!hidden.contains('velocity'))
            (
              'velocity',
              'V',
              (_) => velUnit.symbol,
              (r) => r.velocity.in_(velUnit),
              FC.velocity.accuracyFor(velUnit),
            ),
          if (!hidden.contains('height'))
            (
              'height',
              'Height',
              (_) => dropUnit.symbol,
              (r) => r.height.in_(dropUnit),
              FC.drop.accuracyFor(dropUnit),
            ),
          if (!hidden.contains('drop'))
            (
              'drop',
              'Drop',
              (_) => dropUnit.symbol,
              (r) => r.slantHeight.in_(dropUnit),
              FC.drop.accuracyFor(dropUnit),
            ),
          for (final u in adjUnits)
            (
              'adjDrop_${u.name}',
              'Drop° ${u.symbol}',
              (_) => u.symbol,
              (bclibc.TrajectoryData r) => r.dropAngle.in_(u),
              FC.adjustment.accuracyFor(u),
            ),
          if (!hidden.contains('wind'))
            (
              'wind',
              'Wind',
              (_) => dropUnit.symbol,
              (r) => r.windage.in_(dropUnit),
              FC.drop.accuracyFor(dropUnit),
            ),
          for (final u in adjUnits)
            (
              'adjWind_${u.name}',
              'Wind° ${u.symbol}',
              (_) => u.symbol,
              (bclibc.TrajectoryData r) => r.windageAngle.in_(u),
              FC.adjustment.accuracyFor(u),
            ),
          if (!hidden.contains('mach'))
            ('mach', 'Mach', (_) => '', (r) => r.mach, 2),
          if (!hidden.contains('energy'))
            (
              'energy',
              'Energy',
              (_) => energyUnit.symbol,
              (r) => r.energy.in_(energyUnit),
              FC.energy.accuracyFor(energyUnit),
            ),
        ];

    final distHeaders = <String>[];
    final tableRows = <FormattedRow>[];

    for (final row in rows) {
      final rangeVal = colDefs.first.$4(row);
      final rangeStr = rangeVal != null
          ? rangeVal.toFixedSafe(colDefs.first.$5)
          : '—';

      if (isZeroTable) {
        final arrow = (row.flag & bclibc.TrajFlag.zeroUp.value) != 0
            ? ' ↑'
            : (row.flag & bclibc.TrajFlag.zeroDown.value) != 0
            ? ' ↓'
            : '';
        distHeaders.add('$rangeStr$arrow');
      } else {
        distHeaders.add(rangeStr);
      }
    }

    final zeroDistFlags = <bool>[];
    if (zeroDistM != null) {
      for (final row in rows) {
        final distM = row.distance.in_(Unit.meter);
        zeroDistFlags.add((distM - zeroDistM).abs() < 0.5);
      }
    }

    int subsonicIndex = -1;
    if (tablesSettings.showSubsonicTransition) {
      for (var i = 0; i < rows.length; i++) {
        if (rows[i].mach < 1.0) {
          subsonicIndex = i;
          break;
        }
      }
    }

    for (var ci = 1; ci < colDefs.length; ci++) {
      final col = colDefs[ci];
      final cells = <FormattedCell>[];
      for (var pi = 0; pi < rows.length; pi++) {
        final row = rows[pi];
        final val = col.$4(row);
        final valStr = val != null ? val.toFixedSafe(col.$5) : '—';
        final isZero = (row.flag & bclibc.TrajFlag.zero.value) != 0;
        final isTarget = zeroDistFlags.isNotEmpty && zeroDistFlags[pi];
        cells.add(
          FormattedCell(
            value: valStr,
            isZeroCrossing: isZero,
            isSubsonic: pi == subsonicIndex,
            isTargetColumn: isTarget,
          ),
        );
      }
      tableRows.add(
        FormattedRow(label: col.$2, unitSymbol: col.$3(null), cells: cells),
      );
    }

    return FormattedTableData(
      distanceHeaders: distHeaders,
      rows: tableRows,
      distanceUnit: colDefs.first.$3(null),
    );
  }

  List<bclibc.TrajectoryData> _filterTraj(
    List<bclibc.TrajectoryData> traj,
    double startM,
    double endM,
    double stepM,
  ) {
    final result = <bclibc.TrajectoryData>[];
    double nextM = startM;
    for (final p in traj) {
      final d = p.distance.in_(Unit.meter);
      if (d < startM - 0.5) continue;
      if (d > endM + 0.5) break;
      if (stepM > 1.0 && d < nextM - 0.5) continue;
      result.add(p);
      if (stepM > 1.0) nextM = ((d / stepM).round() + 1) * stepM;
    }
    return result;
  }
}

final trajectoryTablesVmProvider =
    AsyncNotifierProvider<TrajectoryTablesViewModel, TrajectoryTablesUiState>(
      TrajectoryTablesViewModel.new,
    );
