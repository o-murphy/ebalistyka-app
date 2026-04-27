import 'dart:async';
import 'dart:math' as math;

import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/helpers/drag_model_info_formatter.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:riverpod/riverpod.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

import 'package:ebalistyka/core/services/ballistics_service.dart';
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

class HomeConditionsUiState {
  final double windAngleDeg;
  final String tempDisplay;
  final String altDisplay;
  final String pressDisplay;
  final String humidDisplay;
  final double targetDistanceM;

  const HomeConditionsUiState({
    this.windAngleDeg = 0.0,
    this.tempDisplay = '',
    this.altDisplay = '',
    this.pressDisplay = '',
    this.humidDisplay = '',
    this.targetDistanceM = 0.0,
  });
}

class ReticleUiState {
  final String? reticleId;
  final String? targetId;
  final double targetSizeMilAtDistance;
  final String? adjustedMessageLine;
  final String? zeroOffsetMessageLine;
  final String cartridgeInfoLine;
  final AdjustmentData adjustment;
  final AdjustmentDisplayFormat adjustmentFormat;
  final double adjustmentElevMil;
  final double adjustmentWindMil;

  const ReticleUiState({
    this.reticleId,
    this.targetId,
    this.targetSizeMilAtDistance = 0.0,
    this.adjustedMessageLine,
    this.zeroOffsetMessageLine,
    this.cartridgeInfoLine = '',
    required this.adjustment,
    this.adjustmentFormat = AdjustmentDisplayFormat.arrows,
    this.adjustmentElevMil = 0.0,
    this.adjustmentWindMil = 0.0,
  });
}

sealed class HomeUiState {
  const HomeUiState();
}

class HomeChartUiState {
  final ChartData chartData;
  final HomeChartPointInfo? selectedPointInfo;
  final int? selectedChartIndex;

  const HomeChartUiState({
    required this.chartData,
    this.selectedPointInfo,
    this.selectedChartIndex,
  });

  HomeChartUiState withSelection(HomeChartPointInfo info, int index) =>
      HomeChartUiState(
        chartData: chartData,
        selectedPointInfo: info,
        selectedChartIndex: index,
      );
}

class HomeUiReady extends HomeUiState {
  final String profileName;
  final String weaponName;
  final String ammoName;

  final HomeConditionsUiState conditionsState;
  final ReticleUiState reticleState;
  final FormattedTableData tableData;
  final HomeChartUiState chartState;

  const HomeUiReady({
    required this.profileName,
    required this.weaponName,
    required this.ammoName,
    required this.conditionsState,
    required this.reticleState,
    required this.tableData,
    required this.chartState,
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
      if (next.hasValue) unawaited(_recalculate());
    }, fireImmediately: true);
    ref.listen<AsyncValue<GeneralSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (_generalNeedsRecalc(prev?.value, next.value!)) {
        unawaited(_recalculate());
      }
    }, fireImmediately: true);
    ref.listen<UnitSettings>(unitSettingsProvider, (prev, next) {
      if (prev != null) unawaited(_recalculate());
    }, fireImmediately: true);
    ref.listen<ReticleSettings>(reticleSettingsProvider, (prev, next) {
      if (prev != null) unawaited(_recalculate());
    }, fireImmediately: true);
    return const HomeUiNoData(type: EmptyStateType.noProfile);
  }

  Future<void> _recalculate() async {
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
      if (!ref.mounted) return;

      final uiState = await _buildReadyState(
        profile: profile,
        conditions: conditions,
        settings: settings,
        reticle: reticle,
        units: units,
        formatter: formatter,
        result: result,
      );
      if (!ref.mounted) return;

      state = AsyncData(uiState);
    } catch (e) {
      if (ref.mounted) {
        state = AsyncData(HomeUiError(e.toString()));
      }
    }
  }

  static bool _generalNeedsRecalc(GeneralSettings? prev, GeneralSettings next) {
    if (prev == null) return true;
    return prev.homeChartDistanceStep != next.homeChartDistanceStep ||
        prev.homeTableDistanceStep != next.homeTableDistanceStep ||
        prev.homeShowMrad != next.homeShowMrad ||
        prev.homeShowMoa != next.homeShowMoa ||
        prev.homeShowMil != next.homeShowMil ||
        prev.homeShowCmPer100m != next.homeShowCmPer100m ||
        prev.homeShowInPer100yd != next.homeShowInPer100yd ||
        prev.homeShowInClicks != next.homeShowInClicks ||
        prev.homeShowSubsonicTransition != next.homeShowSubsonicTransition;
  }

  void selectChartPoint(int index) {
    final current = state.value;
    if (current is! HomeUiReady) return;
    final point = current.chartState.chartData.pointAt(index);
    if (point == null) return;

    final info = _buildPointInfo(point, ref.read(unitFormatterProvider));

    state = AsyncData(
      HomeUiReady(
        profileName: current.profileName,
        weaponName: current.weaponName,
        ammoName: current.ammoName,
        conditionsState: current.conditionsState,
        reticleState: current.reticleState,
        tableData: current.tableData,
        chartState: current.chartState.withSelection(info, index),
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
    required Unit? vUnit,
    required double hRaw,
    required Unit? hUnit,
  }) async {
    final notifier = ref.read(reticleSettingsNotifierProvider.notifier);
    if (vUnit == null) {
      notifier.setVerticalAdjustmentUnitRaw('clicks');
      notifier.setVerticalAdjustment(vRaw);
    } else {
      notifier.setVerticalAdjustmentUnit(vUnit);
      notifier.setVerticalAdjustment(
        Angular(vRaw, FC.adjustment.rawUnit).in_(vUnit),
      );
    }
    if (hUnit == null) {
      notifier.setHorizontalAdjustmentUnitRaw('clicks');
      notifier.setHorizontalAdjustment(hRaw);
    } else {
      notifier.setHorizontalAdjustmentUnit(hUnit);
      notifier.setHorizontalAdjustment(
        Angular(hRaw, FC.adjustment.rawUnit).in_(hUnit),
      );
    }
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

  Future<HomeUiReady> _buildReadyState({
    required Profile profile,
    required ShootingConditions conditions,
    required GeneralSettings settings,
    required ReticleSettings reticle,
    required UnitSettings units,
    required UnitFormatter formatter,
    required BallisticsResult result,
  }) async {
    final hit = result.hitResult;
    final targetM = conditions.distanceMeter;

    final windDirDeg = conditions.windDirectionDeg;

    final conditionsState = HomeConditionsUiState(
      windAngleDeg: windDirDeg,
      tempDisplay: formatter.temperature(conditions.temperature),
      altDisplay: formatter.distance(conditions.altitude),
      pressDisplay: formatter.pressure(conditions.pressure),
      humidDisplay: formatter.humidity(
        Ratio(conditions.humidityFrac, Unit.fraction),
      ),
      targetDistanceM: targetM,
    );

    final cartridgeInfoLine = _buildCartridgeInfoLine(
      profile,
      conditions,
      formatter,
    );

    final vAdjMil = reticle.verticalAdjInClicks
        ? reticle.verticalAdjustment
        : reticle.verticalAdjustment.convert(
            reticle.verticalAdjustmentUnitValue,
            Unit.mil,
          );
    final hAdjMil = reticle.horizontalAdjInClicks
        ? reticle.horizontalAdjustment
        : reticle.horizontalAdjustment.convert(
            reticle.horizontalAdjustmentUnitValue,
            Unit.mil,
          );

    double horizontalClickSizeMil = 0.0;
    double verticalClickSizeMil = 0.0;
    String? adjustedMessageLine;

    final sight = profile.sight.target;
    if (sight != null) {
      horizontalClickSizeMil = Angular(
        sight.horizontalClick,
        sight.horizontalClickUnitValue,
      ).in_(Unit.mil);
      verticalClickSizeMil = Angular(
        sight.verticalClick,
        sight.verticalClickUnitValue,
      ).in_(Unit.mil);
      adjustedMessageLine = _buildAdjustedMessageLine(
        reticle,
        vClickSizeMil: verticalClickSizeMil,
        hClickSizeMil: horizontalClickSizeMil,
      );
    }

    double zeroOffsetYMil = 0.0;
    double zeroOffsetXMil = 0.0;
    String? zeroOffsetMessageLine;

    final ammo = profile.ammo.target;
    if (ammo != null) {
      zeroOffsetYMil = Angular(
        ammo.zeroOffsetY,
        ammo.zeroOffsetYUnitValue,
      ).in_(Unit.mil);
      zeroOffsetXMil = Angular(
        ammo.zeroOffsetX,
        ammo.zeroOffsetXUnitValue,
      ).in_(Unit.mil);
      zeroOffsetMessageLine = _buildZeroOffsetMessageLine(
        zeroOffsetYMil: zeroOffsetYMil,
        zeroOffsetXMil: zeroOffsetXMil,
        zeroOffsetYUnit: ammo.zeroOffsetYUnitValue,
        zeroOffsetXUnit: ammo.zeroOffsetXUnitValue,
      );
    }

    final elevMil =
        Angular.radian(result.holdRad).in_(Unit.mil) + vAdjMil + zeroOffsetYMil;
    final targetPoint = hit.trajectory.isNotEmpty
        ? hit.getAtDistance(Distance.meter(targetM))
        : null;
    final windMil =
        (targetPoint?.windageAngle.in_(Unit.mil) ?? 0.0) +
        hAdjMil +
        zeroOffsetXMil;

    final adjustmentData = _buildAdjustment(
      hit,
      targetM,
      Angular(elevMil, Unit.mil),
      Angular(windMil, Unit.mil),
      horizontalClickSizeMil,
      verticalClickSizeMil,
      settings,
    );

    final targetSvg = await ref
        .read(targetSvgProvider(reticle.targetImage).future)
        .catchError((_) => '');
    final targetSizeMil = _parseMilWidth(targetSvg);
    final targetSizeMilAtDistance = targetM > 0
        ? targetSizeMil * 100 / targetM
        : 0.0;

    final reticleState = ReticleUiState(
      reticleId: profile.sight.target?.reticleImage,
      targetId: reticle.targetImage,
      targetSizeMilAtDistance: targetSizeMilAtDistance,
      adjustedMessageLine: adjustedMessageLine,
      zeroOffsetMessageLine: zeroOffsetMessageLine,
      cartridgeInfoLine: cartridgeInfoLine,
      adjustment: adjustmentData,
      adjustmentFormat: settings.adjustmentDisplayFormat,
      adjustmentElevMil: elevMil,
      adjustmentWindMil: windMil,
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
    final autoInfo = autoIndex == null
        ? null
        : _buildPointInfo(chartData.points[autoIndex], formatter);

    return HomeUiReady(
      profileName: profile.name,
      weaponName: profile.weapon.target?.name ?? '',
      ammoName: profile.ammo.target?.name ?? '',
      conditionsState: conditionsState,
      reticleState: reticleState,
      tableData: tableData,
      chartState: HomeChartUiState(
        chartData: chartData,
        selectedPointInfo: autoInfo,
        selectedChartIndex: autoIndex,
      ),
    );
  }

  static double _parseMilWidth(String svg) {
    final m = RegExp(
      r'viewBox="[^"]*?\s+[^"]*?\s+([^"]*?)\s+[^"]*?"',
    ).firstMatch(svg);
    return m != null ? double.tryParse(m.group(1)!) ?? 0.5 : 0.0;
  }

  String? _buildZeroOffsetMessageLine({
    required Unit zeroOffsetYUnit,
    required Unit zeroOffsetXUnit,
    required double zeroOffsetYMil,
    required double zeroOffsetXMil,
  }) {
    if (zeroOffsetYMil == 0.0 && zeroOffsetXMil == 0.0) return null;

    final parts = <String>[];

    if (zeroOffsetYMil != 0.0) {
      parts.add(_angularPart(zeroOffsetYMil, zeroOffsetYUnit, 'vertical'));
    }

    if (zeroOffsetXMil != 0.0) {
      parts.add(_angularPart(zeroOffsetXMil, zeroOffsetXUnit, 'horizontal'));
    }

    return 'Zero offset: ${parts.join(' / ')}';
  }

  String? _buildAdjustedMessageLine(
    ReticleSettings reticle, {
    required double vClickSizeMil,
    required double hClickSizeMil,
  }) {
    final vAdj = reticle.verticalAdjustment;
    final hAdj = reticle.horizontalAdjustment;

    if (vAdj == 0.0 && hAdj == 0.0) return null;

    final parts = <String>[];

    if (vAdj != 0.0) {
      final part = reticle.verticalAdjInClicks && vClickSizeMil > 0
          ? _clicksPart(vAdj, vClickSizeMil, 'vertical')
          : _angularPart(vAdj, reticle.verticalAdjustmentUnitValue, 'vertical');
      parts.add(part);
    }
    if (hAdj != 0.0) {
      final part = reticle.horizontalAdjInClicks && hClickSizeMil > 0
          ? _clicksPart(hAdj, hClickSizeMil, 'horizontal')
          : _angularPart(
              hAdj,
              reticle.horizontalAdjustmentUnitValue,
              'horizontal',
            );
      parts.add(part);
    }
    return 'Drum adjustment: ${parts.join(' / ')}';
  }

  static String _clicksPart(double rawMil, double clickSizeMil, String dir) {
    final clicks = rawMil / clickSizeMil;
    final v = clicks.toStringAsFixed(0);
    return '${clicks > 0 ? '+' : ''}$v click $dir';
  }

  static String _angularPart(double adjInUnit, Unit unit, String dir) {
    final acc = FC.adjustment.accuracyFor(unit);
    return '${adjInUnit > 0 ? '+' : ''}${adjInUnit.toFixedSafe(acc)} ${_unitLabel(unit)} $dir';
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
    UnitFormatter formatter,
  ) {
    final ammo = profile.ammo.target!;
    final weapon = profile.weapon.target;
    final sight = profile.sight.target;

    final mvStr = formatter.velocity(ammo.mv);
    final dragStr = ammo.dragModelFormattedInfo;

    String? sgStr;
    if (weapon != null && ammo.weightGrain > 0 && ammo.caliberInch > 0) {
      final sightHeight = Distance.inch(sight?.sightHeightInch ?? 0.0);
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
    Angular elevAngle,
    Angular windAngle,
    double horizontalClickSizeMil,
    double verticalClickSizeMil,
    GeneralSettings settings,
  ) {
    final dispUnits = <(Unit, String)>[
      if (settings.homeShowMrad) (Unit.mRad, 'MRAD'),
      if (settings.homeShowMoa) (Unit.moa, 'MOA'),
      if (settings.homeShowMil) (Unit.mil, 'MIL'),
      if (settings.homeShowCmPer100m) (Unit.cmPer100m, 'cm/100m'),
      if (settings.homeShowInPer100yd) (Unit.inPer100Yd, 'in/100yd'),
    ];

    List<AdjustmentValue> elevValues = dispUnits.map((u) {
      final val = elevAngle.in_(u.$1);
      return AdjustmentValue(
        absValue: val.abs(),
        isPositive: val >= 0,
        symbol: u.$2,
        decimals: FC.adjustment.accuracyFor(u.$1),
      );
    }).toList();

    if (settings.homeShowInClicks) {
      final val = elevAngle.in_(Unit.mil);
      final clicks = verticalClickSizeMil > 0.0
          ? val / verticalClickSizeMil
          : 0.0;
      elevValues.add(
        AdjustmentValue(
          absValue: clicks.abs(),
          isPositive: clicks >= 0,
          symbol: "Clicks",
          decimals: 0,
        ),
      );
    }

    final windValues = dispUnits.map((u) {
      final corr = windAngle.in_(u.$1);
      return AdjustmentValue(
        absValue: corr.abs(),
        isPositive: corr >= 0,
        symbol: u.$2,
        decimals: FC.adjustment.accuracyFor(u.$1),
      );
    }).toList();

    if (settings.homeShowInClicks) {
      final val = windAngle.in_(Unit.mil);
      final clicks = horizontalClickSizeMil > 0.0
          ? val / horizontalClickSizeMil
          : 0.0;
      windValues.add(
        AdjustmentValue(
          absValue: clicks.abs(),
          isPositive: clicks >= 0,
          symbol: "Clicks",
          decimals: 0,
        ),
      );
    }

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

  HomeChartPointInfo _buildPointInfo(
    ChartPoint point,
    UnitFormatter formatter,
  ) {
    return HomeChartPointInfo(
      distance: formatter.distance(Distance(point.distanceM, Unit.meter)),
      velocity: formatter.velocity(Velocity(point.velocityMps, Unit.mps)),
      energy: formatter.energy(Energy(point.energyJ, Unit.joule)),
      time: formatter.time(point.time),
      height: formatter.drop(Distance(point.heightCm / 100.0, Unit.meter)),
      drop:
          '${point.dropAngleMil.toFixedSafe(2)} ${formatter.adjustmentSymbol}',
      windage:
          '${point.windageAngleMil.toFixedSafe(2)} ${formatter.adjustmentSymbol}',
      mach: formatter.mach(point.mach),
    );
  }
}

final homeVmProvider = AsyncNotifierProvider<HomeViewModel, HomeUiState>(
  HomeViewModel.new,
);
