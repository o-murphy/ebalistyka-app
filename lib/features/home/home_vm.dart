import 'dart:math' as math;

import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/shared/consts.dart';
import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
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

class HomeUiReady extends HomeUiState {
  // Top block
  final String profileName;
  final String weaponName;
  final String ammoName;
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
  final String? adjustedMessageLine;
  final String cartridgeInfoLine;
  final String? reticleId;
  final String? targetId;
  final AdjustmentData adjustment;
  final AdjustmentDisplayFormat adjustmentFormat;
  final double adjustmentElevMil;
  final double adjustmentWindMil;

  // Bottom block — Page 2 (Table)
  final FormattedTableData tableData;

  // Bottom block — Page 3 (Chart)
  final ChartData chartData;
  final HomeChartPointInfo? selectedPointInfo;
  final int? selectedChartIndex;

  const HomeUiReady({
    required this.profileName,
    required this.weaponName,
    required this.ammoName,
    required this.windAngleDeg,
    required this.tempDisplay,
    required this.altDisplay,
    required this.pressDisplay,
    required this.humidDisplay,
    this.adjustedMessageLine,
    required this.cartridgeInfoLine,
    this.reticleId,
    this.targetId,
    required this.windSpeedDisplay,
    required this.windSpeedMps,
    required this.lookAngleDisplay,
    required this.lookAngleDeg,
    required this.targetDistanceDisplay,
    required this.targetDistanceM,
    required this.adjustment,
    this.adjustmentFormat = AdjustmentDisplayFormat.arrows,
    this.adjustmentElevMil = 0.0,
    this.adjustmentWindMil = 0.0,
    required this.tableData,
    required this.chartData,
    this.selectedPointInfo,
    this.selectedChartIndex,
  });
}

class HomeUiNoData extends HomeUiState {
  final String? message;
  final EmptyStateType type;
  const HomeUiNoData({this.message, this.type = EmptyStateType.noData});
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
  Future<HomeUiState> build() async {
    ref.listen<AsyncValue<ShotContext?>>(shotContextProvider, (_, next) {
      if (next.hasValue && next.value == null) {
        state = const AsyncData(HomeUiNoData(type: EmptyStateType.noProfile));
      }
    });
    return const HomeUiNoData(type: EmptyStateType.noProfile);
  }

  Future<void> recalculate() async {
    final ctx = ref.read(shotContextProvider).value;
    final settings = ref.read(settingsProvider).value;
    final units = ref.read(unitSettingsProvider);
    final reticle = ref.read(reticleSettingsProvider);
    final formatter = ref.read(unitFormatterProvider);

    if (ctx == null || settings == null) {
      state = const AsyncData(HomeUiNoData(type: EmptyStateType.noProfile));
      return;
    }
    final profile = ctx.profile;
    final conditions = ctx.conditions;
    if (profile.ammo.target == null) {
      state = const AsyncData(HomeUiNoData(type: EmptyStateType.noAmmo));
      return;
    }

    if (!profile.isReadyForCalculation) {
      state = const AsyncData(
        HomeUiNoData(type: EmptyStateType.incompleteAmmo),
      );
      return;
    }

    if (state.value is! HomeUiReady) {
      state = const AsyncLoading<HomeUiState>();
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
        reticle: reticle,
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
        profileName: current.profileName,
        weaponName: current.weaponName,
        ammoName: current.ammoName,
        windAngleDeg: current.windAngleDeg,
        tempDisplay: current.tempDisplay,
        altDisplay: current.altDisplay,
        pressDisplay: current.pressDisplay,
        humidDisplay: current.humidDisplay,
        adjustedMessageLine: current.adjustedMessageLine,
        cartridgeInfoLine: current.cartridgeInfoLine,
        reticleId: current.reticleId,
        targetId: current.targetId,
        windSpeedDisplay: current.windSpeedDisplay,
        windSpeedMps: current.windSpeedMps,
        lookAngleDisplay: current.lookAngleDisplay,
        lookAngleDeg: current.lookAngleDeg,
        targetDistanceDisplay: current.targetDistanceDisplay,
        targetDistanceM: current.targetDistanceM,
        adjustment: current.adjustment,
        adjustmentFormat: current.adjustmentFormat,
        adjustmentElevMil: current.adjustmentElevMil,
        adjustmentWindMil: current.adjustmentWindMil,
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

  Future<void> updateReticleAdjustments({
    required double vRaw,
    required Unit vUnit,
    required double hRaw,
    required Unit hUnit,
  }) async {
    final s = ref.read(reticleSettingsNotifierProvider).value;
    if (s == null) return;
    s.verticalAdjustmentUnitValue = vUnit;
    s.verticalAdjustment = Angular(vRaw, FC.adjustment.rawUnit).in_(vUnit);
    s.horizontalAdjustmentUnitValue = hUnit;
    s.horizontalAdjustment = Angular(hRaw, FC.adjustment.rawUnit).in_(hUnit);
    await ref.read(reticleSettingsNotifierProvider.notifier).save(s);
  }

  Future<void> updateTargetImage(String? imageId) async {
    await ref
        .read(reticleSettingsNotifierProvider.notifier)
        .setTargetImage(imageId);
  }

  Future<void> updateSightReticleImage(String? imageId) async {
    final ctx = ref.read(shotContextProvider).value;
    final sight = ctx?.profile.sight.target;
    if (sight == null) return;
    sight.reticleImage = imageId;
    await ref.read(appStateProvider.notifier).saveSight(sight);
  }

  Future<void> updateSightClicks({
    required double vRaw,
    required Unit vUnit,
    required double hRaw,
    required Unit hUnit,
  }) async {
    final ctx = ref.read(shotContextProvider).value;
    final sight = ctx?.profile.sight.target;
    if (sight == null) return;
    sight.verticalClickUnitValue = vUnit;
    sight.verticalClick = Angular(vRaw, FC.adjustment.rawUnit).in_(vUnit);
    sight.horizontalClickUnitValue = hUnit;
    sight.horizontalClick = Angular(hRaw, FC.adjustment.rawUnit).in_(hUnit);
    await ref.read(appStateProvider.notifier).saveSight(sight);
  }

  // ── Private builders ───────────────────────────────────────────────────────

  HomeUiReady _buildReadyState({
    required Profile profile,
    required ShootingConditions conditions,
    required GeneralSettings settings,
    required ReticleSettings reticle,
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
    final lookAngleDisplay = '${lookDeg.toFixedSafe(FC.lookAngle.accuracy)}°';

    final targetDistanceDisplay = formatter.distance(conditions.distance);

    final adjustedMessageLine = _buildAdjustedMessageLine(reticle);
    final cartridgeInfoLine = _buildCartridgeInfoLine(
      profile,
      conditions,
      formatter,
    );

    final vAdjMil = reticle.verticalAdjustment.convert(
      reticle.verticalAdjustmentUnitValue,
      Unit.mil,
    );
    final hAdjMil = reticle.horizontalAdjustment.convert(
      reticle.horizontalAdjustmentUnitValue,
      Unit.mil,
    );

    final adjustment = _buildAdjustment(
      hit,
      targetM,
      result.holdRad,
      settings,
      elevOffsetMil: vAdjMil,
      windOffsetMil: hAdjMil,
    );
    final elevMil = Angular.radian(result.holdRad).in_(Unit.mil) + vAdjMil;
    final targetPoint = hit.trajectory.isNotEmpty
        ? hit.getAtDistance(Distance.meter(targetM))
        : null;
    final windMil =
        (targetPoint != null ? targetPoint.windageAngle.in_(Unit.mil) : 0.0) +
        hAdjMil;

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
      profileName: profile.name,
      weaponName: profile.weapon.target?.name ?? '',
      ammoName: profile.ammo.target?.name ?? '',
      windAngleDeg: windDirDeg,
      tempDisplay: tempStr,
      altDisplay: altStr,
      pressDisplay: pressStr,
      humidDisplay: humidStr,
      adjustedMessageLine: adjustedMessageLine,
      cartridgeInfoLine: cartridgeInfoLine,
      reticleId: profile.sight.target?.reticleImage,
      targetId: reticle.targetImage,
      windSpeedDisplay: windSpeedDisplay,
      windSpeedMps: windMps,
      lookAngleDisplay: lookAngleDisplay,
      lookAngleDeg: lookDeg,
      targetDistanceDisplay: targetDistanceDisplay,
      targetDistanceM: targetM,
      adjustment: adjustment,
      adjustmentFormat: settings.adjustmentDisplayFormat,
      adjustmentElevMil: elevMil,
      adjustmentWindMil: windMil,
      tableData: tableData,
      chartData: chartData,
      selectedPointInfo: autoInfo,
      selectedChartIndex: autoIndex,
    );
  }

  String? _buildAdjustedMessageLine(ReticleSettings reticle) {
    final vAdj = reticle.verticalAdjustment;
    final hAdj = reticle.horizontalAdjustment;
    if (vAdj == 0.0 && hAdj == 0.0) return null;

    final vUnit = reticle.verticalAdjustmentUnitValue;
    final hUnit = reticle.horizontalAdjustmentUnitValue;
    final parts = <String>[];

    if (vAdj != 0.0) {
      final acc = FC.adjustment.accuracyFor(vUnit);
      parts.add(
        '${vAdj > 0 ? '+' : ''}${vAdj.toFixedSafe(acc)} ${_unitLabel(vUnit)} vertical',
      );
    }
    if (hAdj != 0.0) {
      final acc = FC.adjustment.accuracyFor(hUnit);
      parts.add(
        '${hAdj > 0 ? '+' : ''}${hAdj.toFixedSafe(acc)} ${_unitLabel(hUnit)} horizontal',
      );
    }
    return 'Drum adjustment: ${parts.join(' / ')}';
  }

  static String _unitLabel(Unit u) => switch (u) {
    Unit.mRad => 'MRAD',
    Unit.moa => 'MOA',
    Unit.mil => 'MIL',
    Unit.cmPer100m => 'cm/100m',
    Unit.inPer100Yd => 'in/100yd',
    _ => u.name.toUpperCase(),
  };

  String _buildCartridgeInfoLine(
    Profile profile,
    ShootingConditions conditions,
    UnitFormatter fmt,
  ) {
    final ammo = profile.ammo.target!;
    final weapon = profile.weapon.target;
    final sight = profile.sight.target;

    final mvStr = ammo.mv != null ? fmt.velocity(ammo.mv!) : nullStr;
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
    GeneralSettings settings, {
    double elevOffsetMil = 0.0,
    double windOffsetMil = 0.0,
  }) {
    final elevAngle = Angular(
      Angular.radian(holdRad).in_(Unit.mil) + elevOffsetMil,
      Unit.mil,
    );
    final point = hit.trajectory.isNotEmpty
        ? hit.getAtDistance(Distance.meter(targetM))
        : null;
    final windAngle = point != null
        ? Angular(point.windageAngle.in_(Unit.mil) + windOffsetMil, Unit.mil)
        : null;

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
            final corr = windAngle.in_(u.$1);
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
      if (m < 0) return nullStr;
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
            ? nullStr
            : Angular.radian(hold).in_(u).toFixedSafe(acc);
        cells.add(
          FormattedCell(value: valStr, isTargetColumn: ci == targetCol),
        );
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
            ? nullStr
            : (rd.$3(p) ?? double.nan).toFixedSafe(rd.$4);
        cells.add(
          FormattedCell(value: valStr, isTargetColumn: ci == targetCol),
        );
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
