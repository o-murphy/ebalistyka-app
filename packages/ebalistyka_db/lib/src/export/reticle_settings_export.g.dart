// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reticle_settings_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReticleSettingsExport _$ReticleSettingsExportFromJson(
  Map<String, dynamic> json,
) => ReticleSettingsExport(
  verticalAdjustment: (json['verticalAdjustment'] as num).toDouble(),
  verticalAdjustmentUnit: json['verticalAdjustmentUnit'] as String? ?? 'mil',
  horizontalAdjustment: (json['horizontalAdjustment'] as num).toDouble(),
  horizontalAdjustmentUnit:
      json['horizontalAdjustmentUnit'] as String? ?? 'mil',
  targetImage: json['targetImage'] as String?,
);

Map<String, dynamic> _$ReticleSettingsExportToJson(
  ReticleSettingsExport instance,
) => <String, dynamic>{
  'verticalAdjustment': instance.verticalAdjustment,
  'verticalAdjustmentUnit': instance.verticalAdjustmentUnit,
  'horizontalAdjustment': instance.horizontalAdjustment,
  'horizontalAdjustmentUnit': instance.horizontalAdjustmentUnit,
  'targetImage': instance.targetImage,
};
