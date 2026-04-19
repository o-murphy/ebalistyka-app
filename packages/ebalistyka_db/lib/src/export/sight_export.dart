import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'sight_export.g.dart';

@JsonSerializable(includeIfNull: false)
class SightExport {
  const SightExport({
    required this.name,
    required this.focalPlaneValue,
    required this.sightHeightInch,
    required this.sightHorizontalOffsetInch,
    required this.verticalClick,
    required this.horizontalClick,
    required this.verticalClickUnit,
    required this.horizontalClickUnit,
    required this.minMagnification,
    required this.maxMagnification,
    required this.calibratedMagnification,
    this.reticleImage,
    this.vendor,
    this.notes,
    this.image,
  });

  final String name;
  final String focalPlaneValue;
  final double sightHeightInch;
  final double sightHorizontalOffsetInch;
  final double verticalClick;
  final double horizontalClick;
  final String verticalClickUnit;
  final String horizontalClickUnit;
  final double minMagnification;
  final double maxMagnification;
  final double calibratedMagnification;
  final String? reticleImage;
  final String? vendor;
  final String? notes;
  final String? image;

  factory SightExport.fromJson(Map<String, dynamic> json) =>
      _$SightExportFromJson(json);

  Map<String, dynamic> toJson() => _$SightExportToJson(this);

  factory SightExport.fromEntity(Sight s) => SightExport(
    name: s.name,
    focalPlaneValue: s.focalPlaneValue,
    sightHeightInch: s.sightHeightInch,
    sightHorizontalOffsetInch: s.sightHorizontalOffsetInch,
    verticalClick: s.verticalClick,
    horizontalClick: s.horizontalClick,
    verticalClickUnit: s.verticalClickUnit,
    horizontalClickUnit: s.horizontalClickUnit,
    minMagnification: s.minMagnification,
    maxMagnification: s.maxMagnification,
    calibratedMagnification: s.calibratedMagnification,
    reticleImage: s.reticleImage,
    vendor: s.vendor,
    notes: s.notes,
    image: s.image,
  );

  Sight toEntity() => Sight()
    ..name = name
    ..focalPlaneValue = focalPlaneValue
    ..sightHeightInch = sightHeightInch
    ..sightHorizontalOffsetInch = sightHorizontalOffsetInch
    ..verticalClick = verticalClick
    ..horizontalClick = horizontalClick
    ..verticalClickUnit = verticalClickUnit
    ..horizontalClickUnit = horizontalClickUnit
    ..minMagnification = minMagnification
    ..maxMagnification = maxMagnification
    ..calibratedMagnification = calibratedMagnification
    ..reticleImage = reticleImage
    ..vendor = vendor
    ..notes = notes
    ..image = image;
}
