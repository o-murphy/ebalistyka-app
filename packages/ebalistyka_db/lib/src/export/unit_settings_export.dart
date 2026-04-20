import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'unit_settings_export.g.dart';

@JsonSerializable()
class UnitSettingsExport {
  const UnitSettingsExport({
    required this.angular,
    required this.distance,
    required this.velocity,
    required this.pressure,
    required this.temperature,
    required this.diameter,
    required this.length,
    required this.weight,
    required this.adjustment,
    required this.drop,
    required this.energy,
    required this.sightHeight,
    required this.twist,
    required this.barrelLength,
    required this.time,
    required this.torque,
    required this.targetSize,
  });

  final String angular;
  final String distance;
  final String velocity;
  final String pressure;
  final String temperature;
  final String diameter;
  final String length;
  final String weight;
  final String adjustment;
  final String drop;
  final String energy;
  final String sightHeight;
  final String twist;
  final String barrelLength;
  final String time;
  final String torque;
  final String targetSize;

  factory UnitSettingsExport.fromJson(Map<String, dynamic> json) =>
      _$UnitSettingsExportFromJson(json);

  Map<String, dynamic> toJson() => _$UnitSettingsExportToJson(this);

  factory UnitSettingsExport.fromEntity(UnitSettings s) => UnitSettingsExport(
    angular: s.angular,
    distance: s.distance,
    velocity: s.velocity,
    pressure: s.pressure,
    temperature: s.temperature,
    diameter: s.diameter,
    length: s.length,
    weight: s.weight,
    adjustment: s.adjustment,
    drop: s.drop,
    energy: s.energy,
    sightHeight: s.sightHeight,
    twist: s.twist,
    barrelLength: s.barrelLength,
    time: s.time,
    torque: s.torque,
    targetSize: s.targetSize,
  );

  UnitSettings toEntity() => UnitSettings()
    ..angular = angular
    ..distance = distance
    ..velocity = velocity
    ..pressure = pressure
    ..temperature = temperature
    ..diameter = diameter
    ..length = length
    ..weight = weight
    ..adjustment = adjustment
    ..drop = drop
    ..energy = energy
    ..sightHeight = sightHeight
    ..twist = twist
    ..barrelLength = barrelLength
    ..time = time
    ..torque = torque
    ..targetSize = targetSize;
}
