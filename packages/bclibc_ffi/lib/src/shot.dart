import 'dart:math' as math;
import 'package:bclibc_ffi/src/unit.dart';
import 'package:bclibc_ffi/src/conditions.dart';
import 'package:bclibc_ffi/src/munition.dart';

class Shot {
  final Ammo ammo;
  final Atmo atmo;
  final Weapon weapon;

  final Angular lookAngle;
  late Angular relativeAngle;
  final Angular cantAngle;

  List<Wind>? _winds;
  double? _azimuthDeg;
  double? _latitudeDeg;

  Shot({
    required this.weapon,
    required this.ammo,
    Angular? lookAngle,
    Angular? relativeAngle,
    Angular? cantAngle,
    Atmo? atmo,
    List<Wind>? winds,
    double? azimuthDeg,
    double? latitudeDeg,
  }) : lookAngle = lookAngle ?? Angular.radian(0),
       cantAngle = cantAngle ?? Angular.radian(0),
       atmo = atmo ?? Atmo.icao() {
    this.relativeAngle = relativeAngle ?? Angular.radian(0);
    this.winds = winds;
    this.azimuthDeg = azimuthDeg;
    this.latitudeDeg = latitudeDeg;
  }

  // --- Coriolis getters/setters ---

  double? get azimuthDeg => _azimuthDeg;
  set azimuthDeg(double? value) {
    if (value != null && (value < 0.0 || value >= 360.0)) {
      throw ArgumentError('Azimuth must be in range [0, 360).');
    }
    _azimuthDeg = value;
  }

  double? get latitudeDeg => _latitudeDeg;
  set latitudeDeg(double? value) {
    if (value != null && (value < -90.0 || value > 90.0)) {
      throw ArgumentError('Latitude must be in range [-90, 90].');
    }
    _latitudeDeg = value;
  }

  // --- Wind ---

  List<Wind> get winds {
    final list = _winds ?? [];
    return List.from(list)
      ..sort((a, b) => a.untilDistance.raw.compareTo(b.untilDistance.raw));
  }

  set winds(List<Wind>? value) => _winds = value;

  // --- Ballistic geometry ---

  Angular get barrelAzimuth => Angular(
    math.sin(cantAngle.in_(Unit.radian)) *
        (weapon.zeroElevation.in_(Unit.radian) +
            relativeAngle.in_(Unit.radian)),
    Unit.radian,
  );

  Angular get barrelElevation => Angular(
    lookAngle.in_(Unit.radian) +
        math.cos(cantAngle.in_(Unit.radian)) *
            (weapon.zeroElevation.in_(Unit.radian) +
                relativeAngle.in_(Unit.radian)),
    Unit.radian,
  );

  set barrelElevation(Angular value) {
    relativeAngle = Angular(
      value.in_(Unit.radian) -
          lookAngle.in_(Unit.radian) -
          math.cos(cantAngle.in_(Unit.radian)) *
              weapon.zeroElevation.in_(Unit.radian),
      Unit.radian,
    );
  }

  Angular get slantAngle => lookAngle;

  /// Calculate the Miller stability coefficient.
  ///
  /// Returns:
  ///   double: The Miller stability coefficient, or 0.0 if insufficient data.
  double calculateStabilityCoefficient() {
    return calculateMillerStability(
      twistInch: weapon.twist.in_(Unit.inch),
      bulletLenInch: ammo.dm.length.in_(Unit.inch),
      bulletDiamInch: ammo.dm.diameter.in_(Unit.inch),
      bulletWghtGrains: ammo.dm.weight.in_(Unit.grain),
      muzzleVelocityFps: ammo.mv.in_(Unit.fps),
      tempF: atmo.temperature.in_(Unit.fahrenheit),
      pressureInHg: atmo.pressure.in_(Unit.inHg),
    );
  }
}

double calculateMillerStability({
  required double twistInch,
  bulletLenInch,
  bulletDiamInch,
  bulletWghtGrains,
  muzzleVelocityFps,
  tempF,
  pressureInHg,
}) {
  twistInch = twistInch.abs();

  // Check for zero values (Python equivalent: if value)
  if (twistInch == 0.0 ||
      bulletLenInch == 0.0 ||
      bulletDiamInch == 0.0 ||
      bulletWghtGrains == 0.0 ||
      pressureInHg == 0.0) {
    return 0.0;
  }

  // Calculate twist rate and length ratios
  final twistRate = twistInch / bulletDiamInch;
  final length = bulletLenInch / bulletDiamInch;

  // Base Miller stability formula
  final sd =
      30.0 *
      bulletWghtGrains /
      (math.pow(twistRate, 2) *
          math.pow(bulletDiamInch, 3) *
          length *
          (1 + math.pow(length, 2)));

  // Velocity correction factor
  final fv = math.pow(muzzleVelocityFps / 2800.0, 1.0 / 3.0);

  // Atmospheric correction
  final ftp = ((tempF + 460.0) / (59.0 + 460.0)) * (29.92 / pressureInHg);

  return sd * fv * ftp;
}
