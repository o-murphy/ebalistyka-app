import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'conditions_export.g.dart';

@JsonSerializable()
class ConditionsExport {
  const ConditionsExport({
    required this.distanceMeter,
    required this.lookAngleRad,
    required this.altitudeMeter,
    required this.temperatureC,
    required this.pressurehPa,
    required this.humidityFrac,
    required this.powderTemperatureC,
    required this.usePowderSensitivity,
    required this.useDiffPowderTemp,
    required this.useCoriolis,
    required this.latitudeDeg,
    required this.azimuthDeg,
    required this.windDirectionDeg,
    required this.windSpeedMps,
  });

  final double distanceMeter;
  final double lookAngleRad;
  final double altitudeMeter;
  final double temperatureC;
  final double pressurehPa;
  final double humidityFrac;
  final double powderTemperatureC;
  final bool usePowderSensitivity;
  final bool useDiffPowderTemp;
  final bool useCoriolis;
  final double latitudeDeg;
  final double azimuthDeg;
  final double windDirectionDeg;
  final double windSpeedMps;

  factory ConditionsExport.fromJson(Map<String, dynamic> json) =>
      _$ConditionsExportFromJson(json);

  Map<String, dynamic> toJson() => _$ConditionsExportToJson(this);

  factory ConditionsExport.fromEntity(ShootingConditions c) => ConditionsExport(
    distanceMeter: c.distanceMeter,
    lookAngleRad: c.lookAngleRad,
    altitudeMeter: c.altitudeMeter,
    temperatureC: c.temperatureC,
    pressurehPa: c.pressurehPa,
    humidityFrac: c.humidityFrac,
    powderTemperatureC: c.powderTemperatureC,
    usePowderSensitivity: c.usePowderSensitivity,
    useDiffPowderTemp: c.useDiffPowderTemp,
    useCoriolis: c.useCoriolis,
    latitudeDeg: c.latitudeDeg,
    azimuthDeg: c.azimuthDeg,
    windDirectionDeg: c.windDirectionDeg,
    windSpeedMps: c.windSpeedMps,
  );

  ShootingConditions toEntity() => ShootingConditions()
    ..distanceMeter = distanceMeter
    ..lookAngleRad = lookAngleRad
    ..altitudeMeter = altitudeMeter
    ..temperatureC = temperatureC
    ..pressurehPa = pressurehPa
    ..humidityFrac = humidityFrac
    ..powderTemperatureC = powderTemperatureC
    ..usePowderSensitivity = usePowderSensitivity
    ..useDiffPowderTemp = useDiffPowderTemp
    ..useCoriolis = useCoriolis
    ..latitudeDeg = latitudeDeg
    ..azimuthDeg = azimuthDeg
    ..windDirectionDeg = windDirectionDeg
    ..windSpeedMps = windSpeedMps;
}
