import 'dart:math' show pi;

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

extension ConditionsExtension on ShootingConditions {
  // ── Distance ────────────────────────────────────────────────────────────────

  Distance get distance => Distance.meter(distanceMeter);
  set distance(Distance v) => distanceMeter = v.in_(Unit.meter);

  Distance get altitude => Distance.meter(altitudeMeter);
  set altitude(Distance v) => altitudeMeter = v.in_(Unit.meter);

  // ── Angle ───────────────────────────────────────────────────────────────────

  Angular get lookAngle => Angular.radian(lookAngleRad);
  set lookAngle(Angular v) => lookAngleRad = v.in_(Unit.radian);

  Angular get windDirection => Angular.degree(windDirectionDeg);
  set windDirection(Angular v) => windDirectionDeg = v.in_(Unit.degree);

  Angular get latitude => Angular.degree(latitudeDeg);
  set latitude(Angular v) => latitudeDeg = v.in_(Unit.degree);

  Angular get azimuth => Angular.degree(azimuthDeg);
  set azimuth(Angular v) => azimuthDeg = v.in_(Unit.degree);

  // ── Atmosphere ──────────────────────────────────────────────────────────────

  Temperature get temperature => Temperature.celsius(temperatureC);
  set temperature(Temperature v) => temperatureC = v.in_(Unit.celsius);

  Temperature get powderTemperature => Temperature.celsius(powderTemperatureC);
  set powderTemperature(Temperature v) =>
      powderTemperatureC = v.in_(Unit.celsius);

  Pressure get pressure => Pressure.hPa(pressurehPa);
  set pressure(Pressure v) => pressurehPa = v.in_(Unit.hPa);

  Ratio get humidity => Ratio.fraction(humidityFrac);
  set humidity(Ratio v) => humidityFrac = v.in_(Unit.fraction);

  // ── Wind ────────────────────────────────────────────────────────────────────

  Velocity get windSpeed => Velocity.mps(windSpeedMps);
  set windSpeed(Velocity v) => windSpeedMps = v.in_(Unit.mps);

  // ── bclibc conversion ────────────────────────────────────────────────────────

  bclibc.Atmo toCurrentAtmo() => bclibc.Atmo(
    altitude: altitude,
    pressure: pressure,
    temperature: temperature,
    humidity: humidityFrac,
    powderTemperature: useDiffPowderTemp ? powderTemperature : temperature,
  );

  bclibc.Wind toWind() => bclibc.Wind(
    velocity: windSpeed,
    // The C library's wind formula uses z = vel*sin(dir) where positive z = air
    // moves right. Our UI stores the "wind FROM" angle (clock convention), so
    // 90° = wind from right = air moves LEFT = negative z. Adding π converts
    // "from" direction to "to" direction, matching the C library expectation.
    directionFrom: Angular.radian(windDirection.in_(Unit.radian) + pi),
  );
}
