// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sight_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SightExport _$SightExportFromJson(Map<String, dynamic> json) => SightExport(
  name: json['name'] as String,
  focalPlaneValue: json['focalPlaneValue'] as String,
  sightHeightInch: (json['sightHeightInch'] as num).toDouble(),
  sightHorizontalOffsetInch: (json['sightHorizontalOffsetInch'] as num)
      .toDouble(),
  verticalClick: (json['verticalClick'] as num).toDouble(),
  horizontalClick: (json['horizontalClick'] as num).toDouble(),
  verticalClickUnit: json['verticalClickUnit'] as String,
  horizontalClickUnit: json['horizontalClickUnit'] as String,
  minMagnification: (json['minMagnification'] as num).toDouble(),
  maxMagnification: (json['maxMagnification'] as num).toDouble(),
  calibratedMagnification: (json['calibratedMagnification'] as num).toDouble(),
  reticleImage: json['reticleImage'] as String?,
  vendor: json['vendor'] as String?,
  notes: json['notes'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$SightExportToJson(SightExport instance) =>
    <String, dynamic>{
      'name': instance.name,
      'focalPlaneValue': instance.focalPlaneValue,
      'sightHeightInch': instance.sightHeightInch,
      'sightHorizontalOffsetInch': instance.sightHorizontalOffsetInch,
      'verticalClick': instance.verticalClick,
      'horizontalClick': instance.horizontalClick,
      'verticalClickUnit': instance.verticalClickUnit,
      'horizontalClickUnit': instance.horizontalClickUnit,
      'minMagnification': instance.minMagnification,
      'maxMagnification': instance.maxMagnification,
      'calibratedMagnification': instance.calibratedMagnification,
      'reticleImage': ?instance.reticleImage,
      'vendor': ?instance.vendor,
      'notes': ?instance.notes,
      'image': ?instance.image,
    };
