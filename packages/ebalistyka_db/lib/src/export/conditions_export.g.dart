// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conditions_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConditionsExport _$ConditionsExportFromJson(Map<String, dynamic> json) =>
    ConditionsExport(
      distanceMeter: (json['distanceMeter'] as num).toDouble(),
      lookAngleRad: (json['lookAngleRad'] as num).toDouble(),
      altitudeMeter: (json['altitudeMeter'] as num).toDouble(),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      pressurehPa: (json['pressurehPa'] as num).toDouble(),
      humidityFrac: (json['humidityFrac'] as num).toDouble(),
      powderTemperatureC: (json['powderTemperatureC'] as num).toDouble(),
      usePowderSensitivity: json['usePowderSensitivity'] as bool,
      useDiffPowderTemp: json['useDiffPowderTemp'] as bool,
      useCoriolis: json['useCoriolis'] as bool,
      latitudeDeg: (json['latitudeDeg'] as num).toDouble(),
      azimuthDeg: (json['azimuthDeg'] as num).toDouble(),
      windDirectionDeg: (json['windDirectionDeg'] as num).toDouble(),
      windSpeedMps: (json['windSpeedMps'] as num).toDouble(),
    );

Map<String, dynamic> _$ConditionsExportToJson(ConditionsExport instance) =>
    <String, dynamic>{
      'distanceMeter': instance.distanceMeter,
      'lookAngleRad': instance.lookAngleRad,
      'altitudeMeter': instance.altitudeMeter,
      'temperatureC': instance.temperatureC,
      'pressurehPa': instance.pressurehPa,
      'humidityFrac': instance.humidityFrac,
      'powderTemperatureC': instance.powderTemperatureC,
      'usePowderSensitivity': instance.usePowderSensitivity,
      'useDiffPowderTemp': instance.useDiffPowderTemp,
      'useCoriolis': instance.useCoriolis,
      'latitudeDeg': instance.latitudeDeg,
      'azimuthDeg': instance.azimuthDeg,
      'windDirectionDeg': instance.windDirectionDeg,
      'windSpeedMps': instance.windSpeedMps,
    };
