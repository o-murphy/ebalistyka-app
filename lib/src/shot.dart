import 'dart:math' as math;
import 'package:test_app/src/unit.dart';
import 'package:test_app/src/conditions.dart';
import 'package:test_app/src/munition.dart';

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
    Object? lookAngle,
    Object? relativeAngle,
    Object? cantAngle,
    Atmo? atmo,
    List<Wind>? winds,
    double? azimuthDeg,
    double? latitudeDeg,
  }) : lookAngle = PreferredUnits.angular(lookAngle ?? 0),
       cantAngle = PreferredUnits.angular(cantAngle ?? 0),
       atmo = atmo ?? Atmo.icao() {
    this.relativeAngle = PreferredUnits.angular(relativeAngle ?? 0);
    this.winds = winds;
    this.azimuthDeg = azimuthDeg;
    this.latitudeDeg = latitudeDeg;
  }

  // --- Coriolis Getters/Setters ---

  double? get azimuthDeg => _azimuthDeg;
  set azimuthDeg(double? value) {
    if (value != null && (value < 0.0 || value >= 360.0)) {
      throw ArgumentError("Azimuth must be in range [0, 360).");
    }
    _azimuthDeg = value;
  }

  double? get latitudeDeg => _latitudeDeg;
  set latitudeDeg(double? value) {
    if (value != null && (value < -90.0 || value > 90.0)) {
      throw ArgumentError("Latitude must be in range [-90, 90].");
    }
    _latitudeDeg = value;
  }

  // --- Wind logic ---

  List<Wind> get winds {
    final list = _winds ?? [];
    return List.from(list)..sort(
      (a, b) => a.untilDistance.rawValue.compareTo(b.untilDistance.rawValue),
    );
  }

  set winds(List<Wind>? value) => _winds = value;

  // --- Ballistic Geometry ---

  Angular get barrelAzimuth {
    return Unit.radian(
      math.sin(cantAngle.in_(Unit.radian)) *
          (weapon.zeroElevation.in_(Unit.radian) +
              relativeAngle.in_(Unit.radian)),
    );
  }

  Angular get barrelElevation {
    return Unit.radian(
      lookAngle.in_(Unit.radian) +
          math.cos(cantAngle.in_(Unit.radian)) *
              (weapon.zeroElevation.in_(Unit.radian) +
                  relativeAngle.in_(Unit.radian)),
    );
  }

  set barrelElevation(Object value) {
    final target = PreferredUnits.angular(value);
    relativeAngle = Unit.radian(
      target.in_(Unit.radian) -
          lookAngle.in_(Unit.radian) -
          math.cos(cantAngle.in_(Unit.radian)) *
              weapon.zeroElevation.in_(Unit.radian),
    );
  }

  Angular get slantAngle => lookAngle;
}
