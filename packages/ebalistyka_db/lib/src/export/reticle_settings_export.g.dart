// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reticle_settings_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReticleSettingsExport _$ReticleSettingsExportFromJson(
  Map<String, dynamic> json,
) => ReticleSettingsExport(
  verticalAdjustmentRad: (json['verticalAdjustmentRad'] as num).toDouble(),
  horizontalAdjustmentRad: (json['horizontalAdjustmentRad'] as num).toDouble(),
  targetImage: json['targetImage'] as String?,
);

Map<String, dynamic> _$ReticleSettingsExportToJson(
  ReticleSettingsExport instance,
) => <String, dynamic>{
  'verticalAdjustmentRad': instance.verticalAdjustmentRad,
  'horizontalAdjustmentRad': instance.horizontalAdjustmentRad,
  'targetImage': instance.targetImage,
};
