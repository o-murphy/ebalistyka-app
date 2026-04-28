import 'dart:math';
import 'package:bclibc_ffi/unit.dart';

abstract interface class Constraints {
  Unit get rawUnit;
  double get minRaw;
  double get maxRaw;
  double get stepRaw;
  int get accuracy;
  int accuracyFor(Unit displayUnit);
}

/// Constraints for a physical quantity role — used by [UnitValueField]
/// and for display formatting in tables, charts, and widgets.
///
/// All values are in [rawUnit] (the storage/base unit).
/// The UI converts to the selected display unit before showing.
class FieldConstraints implements Constraints {
  const FieldConstraints({
    required this.rawUnit,
    required this.minRaw,
    required this.maxRaw,
    required this.stepRaw,
    required this.accuracy,
  });

  @override
  final Unit rawUnit;
  @override
  final double minRaw;
  @override
  final double maxRaw;
  @override
  final double stepRaw;

  /// Decimal places when displayed in [rawUnit]. Used as fallback.
  @override
  final int accuracy;

  /// Returns the number of decimal places appropriate for [displayUnit].
  ///
  /// Mirrors the logic used internally by [UnitValueField]: converts
  /// [stepRaw] to [displayUnit] and infers the required precision from it.
  @override
  int accuracyFor(Unit displayUnit) {
    if (rawUnit == displayUnit) return accuracy;
    final lo = minRaw.convert(rawUnit, displayUnit);
    final hi = (minRaw + stepRaw).convert(rawUnit, displayUnit);
    final step = (hi - lo).abs();
    if (step <= 0) return accuracy;
    final d = (-log(step) / ln10).ceil();
    return d < 0 ? 0 : d;
  }
}

/// Extension of [FieldConstraints] with ruler/graph tick configuration.
class RulerConstraints implements Constraints {
  RulerConstraints({required this.fc, double? tick, double? smallTick})
    : tick = tick ?? fc.stepRaw,
      smallTick =
          smallTick ?? _defaultSmallTick(tick ?? fc.stepRaw, fc.accuracy);

  final Constraints fc;
  final double tick;
  final double smallTick;

  static double _defaultSmallTick(double tick, int accuracy) {
    final minStep = pow(10, -accuracy).toDouble();
    final calculated = tick / 5;
    return calculated > minStep ? calculated : minStep;
  }

  @override
  Unit get rawUnit => fc.rawUnit;
  @override
  double get minRaw => fc.minRaw;
  @override
  double get maxRaw => fc.maxRaw;
  @override
  double get stepRaw => fc.stepRaw;
  @override
  int get accuracy => fc.accuracy;

  @override
  int accuracyFor(Unit displayUnit) => fc.accuracyFor(displayUnit);
}

// ─── Role definitions ─────────────────────────────────────────────────────────

abstract final class FC {
  // Environmental
  static const temperature = FieldConstraints(
    rawUnit: Unit.celsius,
    minRaw: -100.0,
    maxRaw: 100.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const altitude = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: -500.0,
    maxRaw: 15000.0,
    stepRaw: 10.0,
    accuracy: 0,
  );

  static const pressure = FieldConstraints(
    rawUnit: Unit.hPa,
    minRaw: 300.0,
    maxRaw: 1500.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  /// Humidity in percent (0–100). rawUnit == displayUnit so toDisplay is identity.
  static const humidity = FieldConstraints(
    rawUnit: Unit.fraction,
    minRaw: 0.0,
    maxRaw: 1.0,
    stepRaw: 0.01,
    accuracy: 0,
  );

  // Ballistic inputs
  static const windSpeed = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 0.0,
    maxRaw: 30.0,
    stepRaw: 0.5,
    accuracy: 1,
  );

  static const lookAngle = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: -90.0,
    maxRaw: 90.0,
    stepRaw: 0.1,
    accuracy: 1,
  );

  static const latitude = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: -90.0,
    maxRaw: 90.0,
    stepRaw: 1.0,
    accuracy: 1,
  );

  static const azimuth = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: 0.0,
    maxRaw: 360.0,
    stepRaw: 1.0,
    accuracy: 1,
  );

  static const windDirection = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: 0.0,
    maxRaw: 360.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const targetDistance = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 10.0,
    maxRaw: 3000.0,
    stepRaw: 10.0,
    accuracy: 0,
  );

  // Weapon / optics
  static const sightHeight = FieldConstraints(
    rawUnit: Unit.millimeter,
    minRaw: 0.0,
    maxRaw: 200.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const twist = FieldConstraints(
    rawUnit: Unit.inch,
    minRaw: 0.0,
    maxRaw: 30.0,
    stepRaw: 0.25,
    accuracy: 2,
  );

  static const zeroDistance = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 10.0,
    maxRaw: 1000.0,
    stepRaw: 10.0,
    accuracy: 0,
  );

  // Projectile
  static const muzzleVelocity = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 100.0,
    maxRaw: 1800.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const projectileWeight = FieldConstraints(
    rawUnit: Unit.grain,
    minRaw: 1.0,
    maxRaw: 800.0,
    stepRaw: 0.1,
    accuracy: 1,
  );

  static const projectileLength = FieldConstraints(
    rawUnit: Unit.millimeter,
    minRaw: 1.0,
    maxRaw: 100.0,
    stepRaw: 0.1,
    accuracy: 1,
  );

  static const projectileDiameter = FieldConstraints(
    rawUnit: Unit.millimeter,
    minRaw: 1.0,
    maxRaw: 30.0,
    stepRaw: 0.1,
    accuracy: 2,
  );

  /// Optical magnification (dimensionless scalar, displayed as "x").
  static const magnification = FieldConstraints(
    rawUnit: Unit.scalar,
    minRaw: 0.5,
    maxRaw: 100.0,
    stepRaw: 0.5,
    accuracy: 1,
  );

  static const ballisticCoefficient = FieldConstraints(
    rawUnit: Unit.scalar, // sentinel — dimensionless, no conversion
    minRaw: 0.001,
    maxRaw: 2.000,
    stepRaw: 0.001,
    accuracy: 3,
  );

  static const powderSensitivity = FieldConstraints(
    rawUnit: Unit.fraction, // sentinel — no conversion used for sensitivity
    minRaw: 0.0,
    maxRaw: 5.0, // c_t_coeff max = 5000 ÷ 1000
    stepRaw: 0.001,
    accuracy: 3,
  );

  static const barrelLength = FieldConstraints(
    rawUnit: Unit.inch,
    minRaw: 1.0,
    maxRaw: 36.0,
    stepRaw: 0.5,
    accuracy: 1,
  );

  // Display-only — trajectory output

  /// Bullet height / windage offset (linear). Raw stored in feet.
  static const drop = FieldConstraints(
    rawUnit: Unit.inch,
    minRaw: -1500.0,
    maxRaw: 1500.0,
    stepRaw: 0.1,
    accuracy: 1, // suitable for cm (default unit)
  );

  static const windage = drop;

  /// Scope adjustment angle. Raw stored in radians.
  static const adjustment = FieldConstraints(
    rawUnit: Unit.mil,
    minRaw: -30,
    maxRaw: 30,
    stepRaw: 0.001,
    accuracy: 2, // suitable for MIL / MOA / MRAD (default unit)
  );

  static const velocity = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 0.0,
    maxRaw: 3000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const energy = FieldConstraints(
    rawUnit: Unit.footPound,
    minRaw: 0.0,
    maxRaw: 20000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const tableRange = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 0.0,
    maxRaw: 5000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const distanceStep = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 1.0,
    maxRaw: 1000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const convertorLength = FieldConstraints(
    rawUnit: Unit.inch,
    minRaw: 0.0,
    maxRaw: 9999.0,
    stepRaw: 0.1,
    accuracy: 3,
  );

  static const convertorWeight = FieldConstraints(
    rawUnit: Unit.grain,
    minRaw: 0.0,
    maxRaw: 9999.0,
    stepRaw: 0.1,
    accuracy: 1,
  );

  static const convertorPressure = FieldConstraints(
    rawUnit: Unit.hPa,
    minRaw: 300.0,
    maxRaw: 1500.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const torque = FieldConstraints(
    rawUnit: Unit.newtonMeter,
    minRaw: 300.0,
    maxRaw: 1500.0,
    stepRaw: 1.0,
    accuracy: 0,
  );

  static const convertorDistance = FieldConstraints(
    rawUnit: Unit.meter,
    minRaw: 0.0,
    maxRaw: 5000.0,
    stepRaw: 1.0,
    accuracy: 0,
  );
  static const convertorVelocity = FieldConstraints(
    rawUnit: Unit.mps,
    minRaw: 0.0,
    maxRaw: 3000.0,
    stepRaw: 1.0,
    accuracy: 1,
  );

  static const convertorTorque = torque;
  static const convertorAngular = FieldConstraints(
    rawUnit: Unit.degree,
    minRaw: 0,
    maxRaw: 360,
    stepRaw: 1.0,
    accuracy: 1,
  );

  static const targetSize = FieldConstraints(
    rawUnit: Unit.mil,
    minRaw: 0.001,
    maxRaw: 100,
    stepRaw: 0.1,
    accuracy: 3,
  );

  static const convertorTargetPhysicalSize = FieldConstraints(
    rawUnit: Unit.inch,
    minRaw: 0.0,
    maxRaw: 9999.0,
    stepRaw: 0.1,
    accuracy: 2,
  );
}

abstract final class RC {
  static final targetDistance = RulerConstraints(
    fc: FC.targetDistance,
    tick: 50,
    smallTick: 10,
  );

  static final windSpeed = RulerConstraints(
    fc: FC.windSpeed,
    tick: 0.5,
    smallTick: 0.1,
  );

  static final lookAngle = RulerConstraints(
    fc: FC.lookAngle,
    tick: 5,
    smallTick: 1,
  );

  static final temperature = RulerConstraints(
    fc: FC.temperature,
    tick: 1,
    smallTick: 1,
  );

  static final altitude = RulerConstraints(
    fc: FC.altitude,
    tick: 100,
    smallTick: 20,
  );

  static final pressure = RulerConstraints(
    fc: FC.pressure,
    tick: 1,
    smallTick: 1,
  );

  static final humidity = RulerConstraints(
    fc: FC.humidity,
    tick: 0.01,
    smallTick: 0.01,
  );
}
