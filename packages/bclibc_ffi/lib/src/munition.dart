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
    final coeff = calcPowderSensCoeff(
      mv.in_(Unit.mps),
      powderTemp.in_(Unit.celsius),
      otherVelocity.in_(Unit.mps),
      otherTemperature.in_(Unit.celsius),
    );
    if (coeff == null) {
      throw ArgumentError(
        'calcPowderSens: velocities must be positive and '
        'pairs must differ in both velocity and temperature',
      );
    }
    tempModifier = coeff;
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

/// Calculates powder sensitivity coefficient (fractional velocity change per 15°C)/// from two raw measurement pairs without requiring an [Ammo] object.
/// from two raw measurement pairs without requiring an [Ammo] object.
///
/// - [v0Mps] / [t0C] — reference muzzle velocity and powder temperature
/// - [v1Mps] / [t1C] — secondary measured velocity and temperature
///
/// Returns `null` when the pair is degenerate:
///   - either velocity is non-positive
///   - velocities are equal (no Δv)
///   - temperatures are equal (no Δt)
double? calcPowderSensCoeff(
  double v0Mps,
  double t0C,
  double v1Mps,
  double t1C,
) {
  if (v0Mps <= 0 || v1Mps <= 0) return null;
  final double vDelta = (v0Mps - v1Mps).abs();
  final double tDelta = (t0C - t1C).abs();
  if (vDelta == 0 || tDelta == 0) return null;
  final double vLower = v1Mps < v0Mps ? v1Mps : v0Mps;
  return (vDelta / tDelta) * (15.0 / vLower);
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
