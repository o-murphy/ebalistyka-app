// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weapon_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeaponExport _$WeaponExportFromJson(Map<String, dynamic> json) => WeaponExport(
  name: json['name'] as String,
  caliberInch: (json['caliberInch'] as num).toDouble(),
  caliberName: json['caliberName'] as String,
  twistInch: (json['twistInch'] as num).toDouble(),
  barrelLengthInch: (json['barrelLengthInch'] as num).toDouble(),
  zeroElevationRad: (json['zeroElevationRad'] as num).toDouble(),
  vendor: json['vendor'] as String?,
  notes: json['notes'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$WeaponExportToJson(WeaponExport instance) =>
    <String, dynamic>{
      'name': instance.name,
      'caliberInch': instance.caliberInch,
      'caliberName': instance.caliberName,
      'twistInch': instance.twistInch,
      'barrelLengthInch': instance.barrelLengthInch,
      'zeroElevationRad': instance.zeroElevationRad,
      'vendor': ?instance.vendor,
      'notes': ?instance.notes,
      'image': ?instance.image,
    };
