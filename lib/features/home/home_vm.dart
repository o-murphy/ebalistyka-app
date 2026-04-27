import 'dart:async';
import 'dart:math' as math;

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/core/services/ballistics_service.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

import 'home_builders.dart';
import 'home_ui_state.dart';

export 'home_ui_state.dart';

// ── ViewModel ─────────────────────────────────────────────────────────────────

class HomeViewModel extends AsyncNotifier<HomeUiState> {
  @override
  Future<HomeUiState> build() async {
    ref.listen<AsyncValue<ShotContext?>>(shotContextProvider, (_, next) {
      if (next.hasValue) unawaited(_recalculate());
    }, fireImmediately: true);
    ref.listen<AsyncValue<GeneralSettings>>(settingsProvider, (prev, next) {
      if (!next.hasValue) return;
      if (generalNeedsRecalc(prev?.value, next.value!)) {
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

  void selectChartPoint(int index) {
    final current = state.value;
    if (current is! HomeUiReady) return;
    final point = current.chartState.chartData.pointAt(index);
    if (point == null) return;

    final info = buildPointInfo(point, ref.read(unitFormatterProvider));

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

  // ── Ready state builder ────────────────────────────────────────────────────

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

    final conditionsState = HomeConditionsUiState(
      windAngleDeg: conditions.windDirectionDeg,
      tempDisplay: formatter.temperature(conditions.temperature),
      altDisplay: formatter.distance(conditions.altitude),
      pressDisplay: formatter.pressure(conditions.pressure),
      humidDisplay: formatter.humidity(
        Ratio(conditions.humidityFrac, Unit.fraction),
      ),
      targetDistanceM: targetM,
    );

    final cartridgeInfoLine = buildCartridgeInfoLine(
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
      adjustedMessageLine = buildAdjustedMessageLine(
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
      zeroOffsetMessageLine = buildZeroOffsetMessageLine(
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

    final adjustmentData = buildAdjustment(
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
    final targetSizeMil = parseMilWidth(targetSvg);
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

    final tableData = buildHomeTable(
      hit,
      targetM,
      result.zeroElevationRad,
      result.tableHolds,
      settings,
      units,
      formatter,
    );
    final chartData = buildChartData(hit, targetM, settings);
    final autoIndex = closestIndex(chartData.points, targetM);
    final autoInfo = autoIndex == null
        ? null
        : buildPointInfo(chartData.points[autoIndex], formatter);

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
}

final homeVmProvider = AsyncNotifierProvider<HomeViewModel, HomeUiState>(
  HomeViewModel.new,
);
