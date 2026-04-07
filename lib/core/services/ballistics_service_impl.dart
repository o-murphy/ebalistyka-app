import 'package:ebalistyka/core/models/conditions_data.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:flutter/foundation.dart' show compute;

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/models/shot_profile.dart';
import 'package:bclibc_ffi/bclibc.dart';

// ── Isolate top-level functions ──────────────────────────────────────────────

// (profile, conditions, stepM, cachedZeroElevationRad?)
typedef _TableCalcArgs = (ShotProfile, Conditions, double, double?);
// (hitResult, freshZeroElevationRad?)
typedef _TableCalcResult = (HitResult?, double?);

_TableCalcResult _runTableCalculation(_TableCalcArgs args) {
  final (profile, conditions, stepM, cachedZeroElevRad) = args;
  try {
    final calc = Calculator();
    final cartridge = profile.cartridge!;

    // Отримуємо дистанцію обнулення з умов картриджа
    final zeroDistance = cartridge.zeroConditions.distance;

    final weapon = profile.rifle.toWeapon();
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      weapon.zeroElevation = Angular.radian(cachedZeroElevRad);
    } else {
      Shot zeroShot;
      try {
        zeroShot = profile.toZeroShot(conditions.lookAngle, weapon);
        calc.setWeaponZero(zeroShot, zeroDistance);
      } catch (_) {
        zeroShot = profile.toZeroShot(Angular.radian(0.0), weapon);
        calc.setWeaponZero(zeroShot, zeroDistance);
      }
      freshZeroElevRad = weapon.zeroElevation.in_(Unit.radian);
    }

    final result = calc.fire(
      shot: profile.toCurrentShot(conditions, weapon),
      trajectoryRange: Distance(FC.targetDistance.maxRaw, Unit.meter),
      trajectoryStep: Distance.meter(stepM),
      filterFlags:
          BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
    );
    return (result, freshZeroElevRad);
  } catch (e, st) {
    throw CalculationException('Table calculation failed', e, st);
  }
}

// (profile, conditions, targetDistM, chartStepM, cachedZeroElevationRad?)
typedef _HomeCalcArgs = (ShotProfile, Conditions, double, double, double?);
// (hitResult, freshZeroElevationRad?)
typedef _HomeCalcResult = (HitResult?, double?);

_HomeCalcResult _runHomeCalculation(_HomeCalcArgs args) {
  final (profile, conditions, targetDistM, stepM, cachedZeroElevRad) = args;
  final internalStepM = stepM < 1.0 ? stepM : 1.0;
  try {
    final calc = Calculator();
    final cartridge = profile.cartridge!;

    // Отримуємо дистанцію обнулення з умов картриджа
    final zeroDistance = cartridge.zeroConditions.distance;

    final weapon = profile.rifle.toWeapon();
    double? freshZeroElevRad;

    if (cachedZeroElevRad != null) {
      weapon.zeroElevation = Angular.radian(cachedZeroElevRad);
    } else {
      Shot zeroShot;
      try {
        zeroShot = profile.toZeroShot(conditions.lookAngle, weapon);
        calc.setWeaponZero(zeroShot, zeroDistance);
      } catch (_) {
        zeroShot = profile.toZeroShot(Angular.radian(0.0), weapon);
        calc.setWeaponZero(zeroShot, zeroDistance);
      }
      freshZeroElevRad = weapon.zeroElevation.in_(Unit.radian);
    }
    final shot = profile.toCurrentShot(conditions, weapon);

    final targetElev = calc.barrelElevationForTarget(
      shot,
      Distance.meter(targetDistM),
    );
    final holdRad =
        targetElev.in_(Unit.radian) -
        shot.weapon.zeroElevation.in_(Unit.radian);
    shot.relativeAngle = Angular.radian(holdRad);

    final result = calc.fire(
      shot: shot,
      trajectoryRange: Distance.meter(targetDistM),
      trajectoryStep: Distance.meter(internalStepM),
      filterFlags:
          BCTrajFlag.BC_TRAJ_FLAG_RANGE.value |
          BCTrajFlag.BC_TRAJ_FLAG_ZERO.value,
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
  @override
  Future<BallisticsResult> calculateTable(
    ShotProfile profile,
    Conditions conditions,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final (hit, freshZero) = await compute(_runTableCalculation, (
      profile,
      conditions,
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
    ShotProfile profile,
    Conditions conditions,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    final (hit, freshZero) = await compute(_runHomeCalculation, (
      profile,
      conditions,
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
