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

  // ── Atmosphere ──────────────────────────────────────────────────────────────

  Temperature get temperature => Temperature.celsius(temperatureC);
  set temperature(Temperature v) => temperatureC = v.in_(Unit.celsius);

  Temperature get powderTemperature => Temperature.celsius(powderTemperatureC);
  set powderTemperature(Temperature v) =>
      powderTemperatureC = v.in_(Unit.celsius);

  Pressure get pressure => Pressure.hPa(pressurehPa);
  set pressure(Pressure v) => pressurehPa = v.in_(Unit.hPa);

  // humidity stored as fraction 0.0–1.0, no typed wrapper needed

  // ── Wind ────────────────────────────────────────────────────────────────────

  Velocity get windSpeed => Velocity.mps(windSpeedMps);
  set windSpeed(Velocity v) => windSpeedMps = v.in_(Unit.mps);

  // ── bclibc conversion ────────────────────────────────────────────────────────

  bclibc.Atmo toAtmo() => bclibc.Atmo(
    altitude: altitude,
    pressure: pressure,
    temperature: temperature,
    humidity: humidityFrac,
    powderTemperature: useDiffPowderTemp ? powderTemperature : temperature,
  );

  bclibc.Wind toWind() =>
      bclibc.Wind(velocity: windSpeed, directionFrom: windDirection);
}
