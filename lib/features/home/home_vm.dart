import 'dart:math' as math;

import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:ebalistyka/shared/models/chart_point.dart';
import 'package:ebalistyka/shared/models/formatted_row.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;

// ── State ────────────────────────────────────────────────────────────────────

sealed class HomeUiState {
  const HomeUiState();
}

class HomeUiLoading extends HomeUiState {
  const HomeUiLoading();
}

class HomeUiReady extends HomeUiState {
  // Top block
  final String rifleName;
  final String cartridgeName;
  final double windAngleDeg;

  // Info tiles
  final String tempDisplay;
  final String altDisplay;
  final String pressDisplay;
  final String humidDisplay;

  // Quick actions
  final String windSpeedDisplay;
  final double windSpeedMps;
  final String lookAngleDisplay;
  final double lookAngleDeg;
  final String targetDistanceDisplay;
  final double targetDistanceM;

  // Bottom block — Page 1 (Reticle)
  final String cartridgeInfoLine;
  final AdjustmentData adjustment;
  final AdjustmentDisplayFormat adjustmentFormat;

  // Bottom block — Page 2 (Table)
  final FormattedTableData tableData;

  // Bottom block — Page 3 (Chart)
  final ChartData chartData;
  final HomeChartPointInfo? selectedPointInfo;
  final int? selectedChartIndex;

  const HomeUiReady({
    required this.rifleName,
    required this.cartridgeName,
    required this.windAngleDeg,
    required this.tempDisplay,
    required this.altDisplay,
    required this.pressDisplay,
    required this.humidDisplay,
    required this.cartridgeInfoLine,
    required this.windSpeedDisplay,
    required this.windSpeedMps,
    required this.lookAngleDisplay,
    required this.lookAngleDeg,
    required this.targetDistanceDisplay,
    required this.targetDistanceM,
    required this.adjustment,
    this.adjustmentFormat = AdjustmentDisplayFormat.arrows,
    required this.tableData,
    required this.chartData,
    this.selectedPointInfo,
    this.selectedChartIndex,
  });
}

class HomeUiError extends HomeUiState {
  final String message;
  const HomeUiError(this.message);
}

class HomeChartPointInfo {
  final String distance;
  final String velocity;
  final String energy;
  final String time;
  final String height;
  final String drop;
  final String windage;
  final String mach;

  const HomeChartPointInfo({
    required this.distance,
    required this.velocity,
    required this.energy,
    required this.time,
    required this.height,
    required this.drop,
    required this.windage,
    required this.mach,
  });
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class HomeViewModel extends AsyncNotifier<HomeUiState> {
  @override
  Future<HomeUiState> build() async => const HomeUiLoading();

  Future<void> recalculate() async {
    final ctx = ref.read(shotContextProvider).value;
    final settings = ref.read(settingsProvider).value;
    final units = ref.read(unitSettingsProvider);
    final formatter = ref.read(unitFormatterProvider);

    if (ctx == null || settings == null) return;
    final profile = ctx.profile;
    final conditions = ctx.conditions;
    if (profile.ammo.target == null) return;

    if (state.value is! HomeUiReady) {
      state = const AsyncData(HomeUiLoading());
    }

    try {
      final opts = TargetCalcOptions(
        targetDistM: conditions.distanceMeter,
        trajectoryEndM:
            conditions.distanceMeter + 2 * settings.homeTableDistanceStep,
        stepM: math.min(
          settings.homeChartDistanceStep,
          settings.homeTableDistanceStep,
        ),
        tableStepM: settings.homeTableDistanceStep,
      );

      final result = await ref
          .read(ballisticsServiceProvider)
          .calculateForTarget(profile, conditions, opts);

      final uiState = _buildReadyState(
        profile: profile,
        conditions: conditions,
        settings: settings,
        units: units,
        formatter: formatter,
        result: result,
      );

      state = AsyncData(uiState);
    } catch (e) {
      state = AsyncData(HomeUiError(e.toString()));
    }
  }

  void selectChartPoint(int index) {
    final current = state.value;
    if (current is! HomeUiReady) return;
    final point = current.chartData.pointAt(index);
    if (point == null) return;

    final formatter = ref.read(unitFormatterProvider);
    final info = _buildPointInfo(point, formatter);
    state = AsyncData(
      HomeUiReady(
        rifleName: current.rifleName,
        cartridgeName: current.cartridgeName,
        windAngleDeg: current.windAngleDeg,
        tempDisplay: current.tempDisplay,
        altDisplay: current.altDisplay,
        pressDisplay: current.pressDisplay,
        humidDisplay: current.humidDisplay,
        cartridgeInfoLine: current.cartridgeInfoLine,
        windSpeedDisplay: current.windSpeedDisplay,
        windSpeedMps: current.windSpeedMps,
        lookAngleDisplay: current.lookAngleDisplay,
        lookAngleDeg: current.lookAngleDeg,
        targetDistanceDisplay: current.targetDistanceDisplay,
        targetDistanceM: current.targetDistanceM,
        adjustment: current.adjustment,
        adjustmentFormat: current.adjustmentFormat,
        tableData: current.tableData,
        chartData: current.chartData,
        selectedPointInfo: info,
        selectedChartIndex: index,
      ),
    );
  }

  Future<void> updateWindDirection(double degrees) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateWindDirection(degrees);
  }

  Future<void> updateWindSpeed(double rawMps) async {
    await ref.read(shotConditionsProvider.notifier).updateWindSpeed(rawMps);
  }

  Future<void> updateLookAngle(double degrees) async {
    await ref.read(shotConditionsProvider.notifier).updateLookAngle(degrees);
  }

  Future<void> updateTargetDistance(double meters) async {
    await ref.read(shotConditionsProvider.notifier).updateDistance(meters);
  }

  // ── Private builders ───────────────────────────────────────────────────────

  HomeUiReady _buildReadyState({
    required Profile profile,
    required ShootingConditions conditions,
    required GeneralSettings settings,
    required UnitSettings units,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) {
    final hit = result.hitResult;
    final targetM = conditions.distanceMeter;

    final windDirDeg = conditions.windDirectionDeg;
    final windMps = conditions.windSpeedMps;

    final tempStr = formatter.temperature(conditions.temperature);
    final altStr = formatter.distance(conditions.altitude);
    final pressStr = formatter.pressure(conditions.pressure);
    final humidStr = formatter.humidity(
      Ratio(conditions.humidityFrac, Unit.fraction),
    );

    final windSpeedDisplay = formatter.velocity(Velocity.mps(windMps));

    final lookDeg = conditions.lookAngle.in_(Unit.degree);
    final lookAngleDisplay =
        '${lookDeg.toFixedSafe(FC.lookAngle.accuracy)}°';

    final targetDistanceDisplay = formatter.distance(conditions.distance);

    final cartridgeInfoLine = _buildCartridgeInfoLine(
      profile,
      conditions,
      formatter,
    );

    final adjustment = _buildAdjustment(
      hit,
      targetM,
      result.holdRad,
      settings,
    );
    final tableData = _buildHomeTable(
      hit,
      targetM,
      result.zeroElevationRad,
      result.tableHolds,
      settings,
      units,
      formatter,
    );
    final chartData = _buildChartData(hit, targetM, settings);
    final autoIndex = _closestIndex(chartData.points, targetM);
    final autoInfo = autoIndex != null
        ? _buildPointInfo(chartData.points[autoIndex], formatter)
        : null;

    return HomeUiReady(
      rifleName: profile.weapon.target?.name ?? '',
      cartridgeName: profile.ammo.target?.name ?? '',
      windAngleDeg: windDirDeg,
      tempDisplay: tempStr,
      altDisplay: altStr,
      pressDisplay: pressStr,
      humidDisplay: humidStr,
      cartridgeInfoLine: cartridgeInfoLine,
      windSpeedDisplay: windSpeedDisplay,
      windSpeedMps: windMps,
      lookAngleDisplay: lookAngleDisplay,
      lookAngleDeg: lookDeg,
      targetDistanceDisplay: targetDistanceDisplay,
      targetDistanceM: targetM,
      adjustment: adjustment,
      adjustmentFormat: settings.adjustmentDisplayFormat,
      tableData: tableData,
      chartData: chartData,
      selectedPointInfo: autoInfo,
      selectedChartIndex: autoIndex,
    );
  }

  String _buildCartridgeInfoLine(
    Profile profile,
    ShootingConditions conditions,
    UnitFormatter fmt,
  ) {
    final ammo = profile.ammo.target!;
    final weapon = profile.weapon.target;
    final sight = profile.sight.target;

    final mvStr = fmt.velocity(ammo.mv);
    final dragStr = ammo.dragModelFormattedInfo;

    String? sgStr;
    if (weapon != null && ammo.weightGrain > 0 && ammo.caliberInch > 0) {
      final sightHeight = sight != null
          ? Distance.inch(sight.sightHeightInch)
          : Distance.inch(0);
      final bcWeapon = weapon.toWeapon(sightHeight);
      final currentShot = profile.toCurrentShot(conditions, bcWeapon);
      final sg = currentShot.calculateStabilityCoefficient();
      sgStr = 'Sg ${sg.toFixedSafe(2)}';
    }

    return '${ammo.projectileName ?? ammo.name};  $mvStr;  $dragStr${sgStr != null ? ';  $sgStr' : ''}';
  }

  AdjustmentData _buildAdjustment(
    bclibc.HitResult hit,
    double targetM,
    double holdRad,
    GeneralSettings settings,
  ) {
    final elevAngle = Angular.radian(holdRad);
    final point = hit.trajectory.isNotEmpty
        ? hit.getAtDistance(Distance.meter(targetM))
        : null;
    final windAngle = point?.windageAngle;

    final dispUnits = <(Unit, String)>[
      if (settings.homeShowMrad) (Unit.mRad, 'MRAD'),
      if (settings.homeShowMoa) (Unit.moa, 'MOA'),
      if (settings.homeShowMil) (Unit.mil, 'MIL'),
      if (settings.homeShowCmPer100m) (Unit.cmPer100m, 'cm/100m'),
      if (settings.homeShowInPer100yd) (Unit.inPer100Yd, 'in/100yd'),
    ];

    final elevValues = dispUnits.map((u) {
      final val = elevAngle.in_(u.$1);
      return AdjustmentValue(
        absValue: val.abs(),
        isPositive: val >= 0,
        symbol: u.$2,
        decimals: FC.adjustment.accuracyFor(u.$1),
      );
    }).toList();

    final windValues = windAngle != null
        ? dispUnits.map((u) {
            final corr = -(windAngle.in_(u.$1));
            return AdjustmentValue(
              absValue: corr.abs(),
              isPositive: corr >= 0,
              symbol: u.$2,
              decimals: FC.adjustment.accuracyFor(u.$1),
            );
          }).toList()
        : <AdjustmentValue>[];

    return AdjustmentData(elevation: elevValues, windage: windValues);
  }

  FormattedTableData _buildHomeTable(
    bclibc.HitResult hit,
    double targetM,
    double zeroElevRad,
    List<double> tableHolds,
    GeneralSettings settings,
    UnitSettings units,
    UnitFormatter fmt,
  ) {
    final stepM = settings.homeTableDistanceStep;
    final distUnit = units.distanceUnit;
    final dropUnit = units.dropUnit;
    final velUnit = units.velocityUnit;
    final energyUnit = units.energyUnit;
    final distAcc = FC.targetDistance.accuracyFor(distUnit);

    final dists = [
      targetM - 2 * stepM,
      targetM - stepM,
      targetM,
      targetM + stepM,
      targetM + 2 * stepM,
    ];

    final points = dists
        .map((d) => d < 0 ? null : hit.getAtDistance(Distance.meter(d)))
        .toList();

    final distHeaders = dists.map<String>((m) {
      if (m < 0) return '—';
      final disp = Distance.meter(m).in_(distUnit);
      return disp.toFixedSafe(distAcc);
    }).toList();

    const targetCol = 2;
    final milAcc = FC.adjustment.accuracyFor(Unit.mil);
    final moaAcc = FC.adjustment.accuracyFor(Unit.moa);

    // Rows derived from trajectory points (single fired trajectory).
    final trajRowDefs =
        <(String, String, double? Function(bclibc.TrajectoryData), int)>[
          (
            'Height',
            dropUnit.symbol,
            (p) => p.height.in_(dropUnit),
            FC.drop.accuracyFor(dropUnit),
          ),
          ('Elev', 'MIL', (p) => p.dropAngle.in_(Unit.mil), milAcc),
          ('Elev', 'MOA', (p) => p.dropAngle.in_(Unit.moa), moaAcc),
          (
            'Windage',
            dropUnit.symbol,
            (p) => p.windage.in_(dropUnit),
            FC.drop.accuracyFor(dropUnit),
          ),
          (
            'Velocity',
            velUnit.symbol,
            (p) => p.velocity.in_(velUnit),
            FC.velocity.accuracyFor(velUnit),
          ),
          (
            'Energy',
            energyUnit.symbol,
            (p) => p.energy.in_(energyUnit),
            FC.energy.accuracyFor(energyUnit),
          ),
          ('Time', 's', (p) => p.time, 3),
        ];

    // Drop (hold) rows — barrelElevationForTarget(d) - zeroElevRad for each
    // column, matching the hold value shown on Page 1 (reticle).
    FormattedRow buildDropRow(String unitLabel, Unit u, int acc) {
      final cells = <FormattedCell>[];
      for (var ci = 0; ci < dists.length; ci++) {
        final hold = tableHolds.length > ci ? tableHolds[ci] : double.nan;
        final valStr = (hold.isNaN || dists[ci] < 0)
            ? '—'
            : Angular.radian(hold).in_(u).toFixedSafe(acc);
        cells.add(FormattedCell(value: valStr, isTargetColumn: ci == targetCol));
      }
      return FormattedRow(label: 'Drop', unitSymbol: unitLabel, cells: cells);
    }

    FormattedRow buildTrajRow(
      (String, String, double? Function(bclibc.TrajectoryData), int) rd,
    ) {
      final cells = <FormattedCell>[];
      for (var ci = 0; ci < dists.length; ci++) {
        final p = points[ci];
        final valStr = p == null
            ? '—'
            : (rd.$3(p) ?? double.nan).toFixedSafe(rd.$4);
        cells.add(FormattedCell(value: valStr, isTargetColumn: ci == targetCol));
      }
      return FormattedRow(label: rd.$1, unitSymbol: rd.$2, cells: cells);
    }

    // Row order: Height, Elev MIL, Elev MOA, Drop MIL, Drop MOA,
    //            Windage (distance), Velocity, Energy, Time
    final rows = [
      buildTrajRow(trajRowDefs[0]), // Height
      buildTrajRow(trajRowDefs[1]), // Elev MIL
      buildTrajRow(trajRowDefs[2]), // Elev MOA
      buildDropRow('MIL', Unit.mil, milAcc),
      buildDropRow('MOA', Unit.moa, moaAcc),
      buildTrajRow(trajRowDefs[3]), // Windage (distance)
      buildTrajRow(trajRowDefs[4]), // Velocity
      buildTrajRow(trajRowDefs[5]), // Energy
      buildTrajRow(trajRowDefs[6]), // Time
    ];

    return FormattedTableData(
      distanceHeaders: distHeaders,
      rows: rows,
      distanceUnit: distUnit.symbol,
    );
  }

  int? _closestIndex(List<ChartPoint> points, double targetM) {
    if (points.isEmpty) return null;
    var best = 0;
    var bestDist = (points[0].distanceM - targetM).abs();
    for (var i = 1; i < points.length; i++) {
      final d = (points[i].distanceM - targetM).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  ChartData _buildChartData(
    bclibc.HitResult hit,
    double targetM,
    GeneralSettings settings,
  ) {
    final step = settings.homeChartDistanceStep;

    final points = List.generate((targetM / step).ceil() + 1, (i) => i * step)
        .where((d) => d <= targetM)
        .map((d) {
          final td = hit.getAtDistance(Distance.meter(d));

          final isZero = (td.flag & bclibc.TrajFlag.zero.value) != 0;
          final isMach = (td.flag & bclibc.TrajFlag.mach.value) != 0;

          return ChartPoint(
            distanceM: td.distance.in_(Unit.meter),
            heightCm: td.height.in_(Unit.centimeter),
            velocityMps: td.velocity.in_(Unit.mps),
            mach: td.mach,
            energyJ: td.energy.in_(Unit.joule),
            time: td.time,
            dropAngleMil: td.dropAngle.in_(Unit.mil),
            windageAngleMil: td.windageAngle.in_(Unit.mil),
            isZeroCrossing: isZero,
            isSubsonic: isMach || td.mach < 1.0,
          );
        })
        .whereType<ChartPoint>()
        .toList();

    return ChartData(points: points, snapDistM: step);
  }

  HomeChartPointInfo _buildPointInfo(ChartPoint point, UnitFormatter fmt) {
    return HomeChartPointInfo(
      distance: fmt.distance(Distance(point.distanceM, Unit.meter)),
      velocity: fmt.velocity(Velocity(point.velocityMps, Unit.mps)),
      energy: fmt.energy(Energy(point.energyJ, Unit.joule)),
      time: fmt.time(point.time),
      height: fmt.drop(Distance(point.heightCm / 100.0, Unit.meter)),
      drop: '${point.dropAngleMil.toFixedSafe(2)} ${fmt.adjustmentSymbol}',
      windage:
          '${point.windageAngleMil.toFixedSafe(2)} ${fmt.adjustmentSymbol}',
      mach: fmt.mach(point.mach),
    );
  }
}

final homeVmProvider = AsyncNotifierProvider<HomeViewModel, HomeUiState>(
  HomeViewModel.new,
);
