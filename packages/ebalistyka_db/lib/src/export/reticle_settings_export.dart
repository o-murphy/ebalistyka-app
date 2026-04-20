import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'reticle_settings_export.g.dart';

@JsonSerializable()
class ReticleSettingsExport {
  const ReticleSettingsExport({
    required this.verticalAdjustment,
    this.verticalAdjustmentUnit = 'mil',
    required this.horizontalAdjustment,
    this.horizontalAdjustmentUnit = 'mil',
    required this.targetImage,
  });

  final double verticalAdjustment;
  final String verticalAdjustmentUnit;
  final double horizontalAdjustment;
  final String horizontalAdjustmentUnit;
  final String? targetImage;

  factory ReticleSettingsExport.fromJson(Map<String, dynamic> json) =>
      _$ReticleSettingsExportFromJson(json);

  Map<String, dynamic> toJson() => _$ReticleSettingsExportToJson(this);

  factory ReticleSettingsExport.fromEntity(ReticleSettings s) =>
      ReticleSettingsExport(
        verticalAdjustment: s.verticalAdjustment,
        verticalAdjustmentUnit: s.verticalAdjustmentUnit,
        horizontalAdjustment: s.horizontalAdjustment,
        horizontalAdjustmentUnit: s.horizontalAdjustmentUnit,
        targetImage: s.targetImage,
      );

  ReticleSettings toEntity() => ReticleSettings()
    ..verticalAdjustment = verticalAdjustment
    ..verticalAdjustmentUnit = verticalAdjustmentUnit
    ..horizontalAdjustment = horizontalAdjustment
    ..horizontalAdjustmentUnit = horizontalAdjustmentUnit
    ..targetImage = targetImage;
}
