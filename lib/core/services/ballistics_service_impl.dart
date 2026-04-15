import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:flutter/foundation.dart' show compute, listEquals;
import 'package:ebalistyka/core/extensions/ammo_extensions.dart'
    show DragType, AmmoExtension;
import 'package:bclibc_ffi/unit.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;

// ── Isolate top-level functions ──────────────────────────────────────────────

// (zeroShot, currentShot, zeroDistance, stepM, cachedZeroElevationRad?)
typedef _TableCalcArgs = (bclibc.Shot, bclibc.Shot, Distance, double, double?);
// (hitResult, freshZeroElevationRad?)
typedef _TableCalcResult = (bclibc.HitResult?, double?);

_TableCalcResult _runTableCalculation(_TableCalcArgs args) {
  final (zeroShot, currentShot, zeroDistance, stepM, cachedZeroElevRad) = args;
  try {
    final calc = bclibc.Calculator();
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      currentShot.weapon.zeroElevation = Angular.radian(cachedZeroElevRad);
      zeroShot.weapon.zeroElevation = Angular.radian(cachedZeroElevRad);
    } else {
      try {
        calc.setWeaponZero(zeroShot, zeroDistance);
      } catch (_) {
        final flatShot = bclibc.Shot(
          weapon: zeroShot.weapon,
          ammo: zeroShot.ammo,
          lookAngle: Angular.radian(0.0),
          atmo: zeroShot.atmo,
          winds: zeroShot.winds,
        );
        calc.setWeaponZero(flatShot, zeroDistance);
        zeroShot.weapon.zeroElevation = flatShot.weapon.zeroElevation;
      }
      freshZeroElevRad = zeroShot.weapon.zeroElevation.in_(Unit.radian);
      currentShot.weapon.zeroElevation = zeroShot.weapon.zeroElevation;
    }

    final result = calc.fire(
      shot: currentShot,
      trajectoryRange: Distance(FC.targetDistance.maxRaw, Unit.meter),
      trajectoryStep: Distance.meter(stepM),
      filterFlags:
          bclibc.BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          bclibc.BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
    );
    return (result, freshZeroElevRad);
  } catch (e, st) {
    throw CalculationException('Table calculation failed', e, st);
  }
}

// (zeroShot, currentShot, zeroDistance, targetDistM, trajectoryEndM, chartStepM, tableStepM, cachedZeroElevationRad?)
typedef _HomeCalcArgs = (
  bclibc.Shot,
  bclibc.Shot,
  Distance,
  double,
  double,
  double,
  double,
  double?,
);
// (hitResult, freshZeroElevationRad?, holdRad, tableHolds)
typedef _HomeCalcResult = (bclibc.HitResult?, double?, double, List<double>);

_HomeCalcResult _runHomeCalculation(_HomeCalcArgs args) {
  final (
    zeroShot,
    currentShot,
    zeroDistance,
    targetDistM,
    trajectoryEndM,
    stepM,
    tableStepM,
    cachedZeroElevRad,
  ) = args;
  final internalStepM = stepM < 0.1524
      ? stepM
      : 0.1524; // max 1/2 ft for dense interpolation
  try {
    final calc = bclibc.Calculator();
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      currentShot.weapon.zeroElevation = Angular.radian(cachedZeroElevRad);
      zeroShot.weapon.zeroElevation = Angular.radian(cachedZeroElevRad);
    } else {
      try {
        calc.setWeaponZero(zeroShot, zeroDistance);
      } catch (_) {
        final flatShot = bclibc.Shot(
          weapon: zeroShot.weapon,
          ammo: zeroShot.ammo,
          lookAngle: Angular.radian(0.0),
          atmo: zeroShot.atmo,
          winds: zeroShot.winds,
        );
        calc.setWeaponZero(flatShot, zeroDistance);
        zeroShot.weapon.zeroElevation = flatShot.weapon.zeroElevation;
      }
      freshZeroElevRad = zeroShot.weapon.zeroElevation.in_(Unit.radian);
      currentShot.weapon.zeroElevation = zeroShot.weapon.zeroElevation;
    }

    final zeroElevRad = currentShot.weapon.zeroElevation.in_(Unit.radian);

    // Compute hold = barrelElevationForTarget(d) - zeroElevation for each
    // table column. This gives exact drop corrections matching Page 1.
    final tableDists = [
      targetDistM - 2 * tableStepM,
      targetDistM - tableStepM,
      targetDistM,
      targetDistM + tableStepM,
      targetDistM + 2 * tableStepM,
    ];
    final tableHolds = tableDists.map((d) {
      if (d <= 0) return double.nan;
      return calc
              .barrelElevationForTarget(currentShot, Distance.meter(d))
              .in_(Unit.radian) -
          zeroElevRad;
    }).toList();

    // Hold for the target (center column) — same as tableHolds[2].
    final holdRad = tableHolds[2].isNaN ? 0.0 : tableHolds[2];
    currentShot.relativeAngle = Angular.radian(holdRad);

    final result = calc.fire(
      shot: currentShot,
      trajectoryRange: Distance.meter(trajectoryEndM),
      trajectoryStep: Distance.meter(internalStepM),
      filterFlags:
          bclibc.BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          bclibc.BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
    );
    return (result, freshZeroElevRad, holdRad, tableHolds);
  } catch (e, st) {
    throw CalculationException('Home calculation failed', e, st);
  }
}

// ── Exception ────────────────────────────────────────────────────────────────

class CalculationException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  CalculationException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() =>
      'CalculationException: $message${originalError != null ? ' (${originalError.runtimeType}: $originalError)' : ''}';
}

// ── Implementation ───────────────────────────────────────────────────────────

class BallisticsServiceImpl implements BallisticsService {
  List<double>? _lastZeroKey;
  double? _cachedZeroElevRad;

  List<double> _buildZeroKey(Profile profile, ShootingConditions conditions) {
    final ammo = profile.ammo.target!;
    final weapon = profile.weapon.target;
    final sight = profile.sight.target;

    final bcCount = switch (ammo.dragType) {
      DragType.g7 =>
        ammo.isMultiBC ? (ammo.multiBcTableG7VMps?.length ?? 1) : 1,
      DragType.g1 =>
        ammo.isMultiBC ? (ammo.multiBcTableG1VMps?.length ?? 1) : 1,
      DragType.custom => ammo.customDragTableMach?.length ?? 0,
    };
    final firstBc = switch (ammo.dragType) {
      DragType.g7 => ammo.bcG7,
      DragType.g1 => ammo.bcG1,
      DragType.custom => 0.0,
    };

    return [
      sight?.sightHeightInch ?? 0.0,
      weapon?.twistInch ?? 0.0,
      ammo.muzzleVelocityMps,
      ammo.powderSensitivityFrac,
      firstBc,
      ammo.weightGrain,
      ammo.caliberInch,
      ammo.lengthInch,
      bcCount.toDouble(),
      ammo.zeroAltitudeMeter,
      ammo.zeroPressurehPa,
      ammo.zeroTemperatureC,
      ammo.zeroHumidityFrac,
      ammo.zeroPowderTemperatureC,
      ammo.zeroDistanceMeter,
      conditions.lookAngleRad,
      ammo.usePowderSensitivity ? 1.0 : 0.0,
      ammo.zeroUseDiffPowderTemperature ? 1.0 : 0.0,
    ];
  }

  double? _resolveZeroCache(Profile profile, ShootingConditions conditions) {
    final key = _buildZeroKey(profile, conditions);
    if (_cachedZeroElevRad != null && listEquals(key, _lastZeroKey)) {
      return _cachedZeroElevRad;
    }
    return null;
  }

  void _updateZeroCache(
    Profile profile,
    ShootingConditions conditions,
    double zeroElevRad,
  ) {
    _lastZeroKey = _buildZeroKey(profile, conditions);
    _cachedZeroElevRad = zeroElevRad;
  }

  /// Builds bclibc.Weapon from OB entities.
  bclibc.Weapon _buildWeapon(Profile profile) {
    final weapon = profile.weapon.target!;
    final sight = profile.sight.target;
    final sightHeight = sight?.sightHeight ?? Distance.inch(0);
    return weapon.toWeapon(sightHeight);
  }

  @override
  Future<BallisticsResult> calculateTable(
    Profile profile,
    ShootingConditions conditions,
    TableCalcOptions opts,
  ) async {
    final cached = _resolveZeroCache(profile, conditions);
    final bcWeapon = _buildWeapon(profile);
    final zeroShot = profile.toZeroShot(bcWeapon, conditions.lookAngle);
    final currentShot = profile.toCurrentShot(conditions, bcWeapon);
    final zeroDistance = Distance.meter(profile.ammo.target!.zeroDistanceMeter);

    final (hit, freshZero) = await compute(_runTableCalculation, (
      zeroShot,
      currentShot,
      zeroDistance,
      opts.stepM,
      cached,
    ));
    if (hit == null) throw StateError('Table calculation returned null');
    final zeroElevRad = freshZero ?? cached ?? 0.0;
    if (freshZero != null) _updateZeroCache(profile, conditions, freshZero);
    return BallisticsResult(hitResult: hit, zeroElevationRad: zeroElevRad);
  }

  @override
  Future<BallisticsResult> calculateForTarget(
    Profile profile,
    ShootingConditions conditions,
    TargetCalcOptions opts,
  ) async {
    final cached = _resolveZeroCache(profile, conditions);
    final bcWeapon = _buildWeapon(profile);
    final zeroShot = profile.toZeroShot(bcWeapon, conditions.lookAngle);
    final currentShot = profile.toCurrentShot(conditions, bcWeapon);
    final zeroDistance = Distance.meter(profile.ammo.target!.zeroDistanceMeter);

    final (
      hit,
      freshZero,
      holdRad,
      tableHolds,
    ) = await compute<_HomeCalcArgs, _HomeCalcResult>(_runHomeCalculation, (
      zeroShot,
      currentShot,
      zeroDistance,
      opts.targetDistM,
      opts.trajectoryEndM ?? opts.targetDistM,
      opts.stepM,
      opts.tableStepM ?? 0.0,
      cached,
    ));
    if (hit == null) throw StateError('Target calculation returned null');
    final zeroElevRad = freshZero ?? cached ?? 0.0;
    if (freshZero != null) _updateZeroCache(profile, conditions, freshZero);
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: zeroElevRad,
      holdRad: holdRad,
      tableHolds: tableHolds,
    );
  }
}
