import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'reticle_settings_export.g.dart';

@JsonSerializable()
class ReticleSettingsExport {
  const ReticleSettingsExport({
    required this.verticalAdjustmentRad,
    required this.horizontalAdjustmentRad,
    required this.targetImage,
    required this.targetSizeMm,
  });

  final double verticalAdjustmentRad;
  final double horizontalAdjustmentRad;
  final String? targetImage;
  final double targetSizeMm;

  factory ReticleSettingsExport.fromJson(Map<String, dynamic> json) =>
      _$ReticleSettingsExportFromJson(json);

  Map<String, dynamic> toJson() => _$ReticleSettingsExportToJson(this);

  factory ReticleSettingsExport.fromEntity(ReticleSettings s) =>
      ReticleSettingsExport(
        verticalAdjustmentRad: s.verticalAdjustmentRad,
        horizontalAdjustmentRad: s.horizontalAdjustmentRad,
        targetImage: s.targetImage,
        targetSizeMm: s.targetSizeMm,
      );

  ReticleSettings toEntity() => ReticleSettings()
    ..verticalAdjustmentRad = verticalAdjustmentRad
    ..horizontalAdjustmentRad = horizontalAdjustmentRad
    ..targetImage = targetImage
    ..targetSizeMm = targetSizeMm;
}
