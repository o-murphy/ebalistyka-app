import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:flutter/foundation.dart' show compute;
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

// (zeroShot, currentShot, zeroDistance, targetDistM, chartStepM, cachedZeroElevationRad?)
typedef _HomeCalcArgs = (
  bclibc.Shot,
  bclibc.Shot,
  Distance,
  double,
  double,
  double?,
);
typedef _HomeCalcResult = (bclibc.HitResult?, double?);

_HomeCalcResult _runHomeCalculation(_HomeCalcArgs args) {
  final (
    zeroShot,
    currentShot,
    zeroDistance,
    targetDistM,
    stepM,
    cachedZeroElevRad,
  ) = args;
  final internalStepM = stepM < 1.0 ? stepM : 1.0;
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

    final targetElev = calc.barrelElevationForTarget(
      currentShot,
      Distance.meter(targetDistM),
    );
    final holdRad =
        targetElev.in_(Unit.radian) -
        currentShot.weapon.zeroElevation.in_(Unit.radian);
    currentShot.relativeAngle = Angular.radian(holdRad);

    final result = calc.fire(
      shot: currentShot,
      trajectoryRange: Distance.meter(targetDistM),
      trajectoryStep: Distance.meter(internalStepM),
      filterFlags:
          bclibc.BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          bclibc.BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
    );
    return (result, freshZeroElevRad);
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
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final bcWeapon = _buildWeapon(profile);
    final zeroShot = profile.toZeroShot(bcWeapon, conditions.lookAngle);
    final currentShot = profile.toCurrentShot(conditions, bcWeapon);
    final zeroDistance = Distance.meter(profile.ammo.target!.zeroDistanceMeter);

    final (hit, freshZero) = await compute(_runTableCalculation, (
      zeroShot,
      currentShot,
      zeroDistance,
      opts.stepM,
      cachedZeroElevRad,
    ));
    if (hit == null) throw StateError('Table calculation returned null');
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: freshZero ?? cachedZeroElevRad ?? 0.0,
    );
  }

  @override
  Future<BallisticsResult> calculateForTarget(
    Profile profile,
    ShootingConditions conditions,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final bcWeapon = _buildWeapon(profile);
    final zeroShot = profile.toZeroShot(bcWeapon, conditions.lookAngle);
    final currentShot = profile.toCurrentShot(conditions, bcWeapon);
    final zeroDistance = Distance.meter(profile.ammo.target!.zeroDistanceMeter);

    final (hit, freshZero) = await compute(_runHomeCalculation, (
      zeroShot,
      currentShot,
      zeroDistance,
      opts.targetDistM,
      opts.stepM,
      cachedZeroElevRad,
    ));
    if (hit == null) throw StateError('Target calculation returned null');
    return BallisticsResult(
      hitResult: hit,
      zeroElevationRad: freshZero ?? cachedZeroElevRad ?? 0.0,
    );
  }
}
