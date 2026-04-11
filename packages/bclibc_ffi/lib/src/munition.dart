import 'package:bclibc_ffi/src/drag_model.dart';
import 'package:bclibc_ffi/src/unit.dart';

class Weapon {
  final Distance sightHeight;
  final Distance twist;
  Angular zeroElevation;

  Weapon({Distance? sightHeight, Distance? twist, Angular? zeroElevation})
    : sightHeight = sightHeight ?? Distance.inch(0),
      twist = twist ?? Distance.inch(0),
      zeroElevation = zeroElevation ?? Angular.radian(0);

  @override
  String toString() =>
      'Weapon(sightHeight: $sightHeight, twist: $twist, zeroElevation: $zeroElevation)';
}

class Ammo {
  final DragModel dm;
  final Velocity mv;
  final Temperature powderTemp;
  double tempModifier;
  bool usePowderSensitivity;

  Ammo({
    required this.dm,
    Velocity? mv,
    Temperature? powderTemp,
    this.tempModifier = 0.0,
    this.usePowderSensitivity = false,
  }) : mv = mv ?? Velocity.mps(0),
       powderTemp = powderTemp ?? Temperature.celsius(15);

  double calcPowderSens(Velocity otherVelocity, Temperature otherTemperature) {
    final double v0 = mv.in_(Unit.mps);
    final double t0 = powderTemp.in_(Unit.celsius);
    final double v1 = otherVelocity.in_(Unit.mps);
    final double t1 = otherTemperature.in_(Unit.celsius);

    if (v0 <= 0 || v1 <= 0) {
      throw ArgumentError('calcPowderSens requires positive muzzle velocities');
    }

    final double vDelta = (v0 - v1).abs();
    final double tDelta = (t0 - t1).abs();
    final double vLower = v1 < v0 ? v1 : v0;

    if (vDelta == 0 || tDelta == 0) {
      throw ArgumentError(
        "otherVelocity and temperature can't be same as default",
      );
    }

    tempModifier = (vDelta / tDelta) * (15 / vLower) * 100.0;
    return tempModifier;
  }

  Velocity getVelocityForTemp(Temperature currentTemp) {
    if (!usePowderSensitivity) return mv;

    double adjustedMv = velocityForPowderTemp(
      mv.in_(Unit.mps),
      powderTemp.in_(Unit.celsius),
      currentTemp.in_(Unit.celsius),
      tempModifier,
    );

    return Velocity.mps(adjustedMv);
  }

  @override
  String toString() =>
      'Ammo(mv: $mv, powderTemp: $powderTemp, mod: ${tempModifier.toStringAsFixed(4)})';
}

double velocityForPowderTemp(
  double vMps,
  double tC,
  double tCurC,
  double tempModifier,
) {
  final double tDelta = tCurC - tC;
  double adjustedMv;
  try {
    adjustedMv = (tempModifier / (15 / vMps)) * tDelta + vMps;
  } catch (_) {
    adjustedMv = 0;
  }
  return adjustedMv;
}
