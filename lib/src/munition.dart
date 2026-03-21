import 'package:test_app/src/drag_model.dart';
import 'package:test_app/src/unit.dart';

class Weapon {
  final Distance sightHeight;
  final Distance twist;
  final Angular zeroElevation;

  Weapon({Object? sightHeight, Object? twist, Object? zeroElevation})
    : sightHeight = PreferredUnits.sightHeight(sightHeight ?? 0),
      twist = PreferredUnits.twist(twist ?? 0),
      zeroElevation = PreferredUnits.angular(zeroElevation ?? 0);

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
    Object? mv,
    Object? powderTemp,
    this.tempModifier = 0.0,
    this.usePowderSensitivity = false,
  }) : mv = PreferredUnits.velocity(mv ?? 0),
       powderTemp = PreferredUnits.temperature(
         powderTemp ?? Unit.celsius(15.0),
       );

  double calcPowderSens(Object otherVelocity, Object otherTemperature) {
    final double v0 = mv.in_(Unit.mps);
    final double t0 = powderTemp.in_(Unit.celsius);
    final double v1 = PreferredUnits.velocity(otherVelocity).in_(Unit.mps);
    final double t1 = PreferredUnits.temperature(
      otherTemperature,
    ).in_(Unit.celsius);

    if (v0 <= 0 || v1 <= 0) {
      throw ArgumentError("calcPowderSens requires positive muzzle velocities");
    }

    final double vDelta = (v0 - v1).abs();
    final double tDelta = (t0 - t1).abs();
    final double vLower = v1 < v0 ? v1 : v0;

    if (vDelta == 0 || tDelta == 0) {
      throw ArgumentError(
        "otherVelocity and temperature can't be same as default",
      );
    }

    tempModifier = (vDelta / tDelta) * (15 / vLower);
    return tempModifier;
  }

  Velocity getVelocityForTemp(Object currentTemp) {
    if (!usePowderSensitivity) {
      return mv;
    }

    final double v0 = mv.in_(Unit.mps);
    final double t0 = powderTemp.in_(Unit.celsius);
    final double t1 = PreferredUnits.temperature(currentTemp).in_(Unit.celsius);

    final double tDelta = t1 - t0;
    double adjustedMv;

    try {
      // adjusted_velocity = baseline_velocity + (temp_modifier / (15 / baseline_velocity)) * temp_delta
      adjustedMv = (tempModifier / (15 / v0)) * tDelta + v0;
    } catch (e) {
      adjustedMv = 0;
    }

    return Unit.mps(adjustedMv);
  }

  @override
  String toString() =>
      'Ammo(mv: $mv, powderTemp: $powderTemp, mod: ${tempModifier.toStringAsFixed(4)})';
}
