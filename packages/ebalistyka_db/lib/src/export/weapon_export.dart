import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'weapon_export.g.dart';

@JsonSerializable(includeIfNull: false)
class WeaponExport {
  const WeaponExport({
    required this.name,
    required this.caliberInch,
    required this.caliberName,
    required this.twistInch,
    required this.barrelLengthInch,
    required this.zeroElevationRad,
    this.vendor,
    this.notes,
    this.image,
  });

  final String name;
  final double caliberInch;
  final String caliberName;
  final double twistInch;
  final double barrelLengthInch;
  final double zeroElevationRad;
  final String? vendor;
  final String? notes;
  final String? image;

  factory WeaponExport.fromJson(Map<String, dynamic> json) =>
      _$WeaponExportFromJson(json);

  Map<String, dynamic> toJson() => _$WeaponExportToJson(this);

  factory WeaponExport.fromEntity(Weapon w) => WeaponExport(
    name: w.name,
    caliberInch: w.caliberInch,
    caliberName: w.caliberName,
    twistInch: w.twistInch,
    barrelLengthInch: w.barrelLengthInch,
    zeroElevationRad: w.zeroElevationRad,
    vendor: w.vendor,
    notes: w.notes,
    image: w.image,
  );

  Weapon toEntity() => Weapon()
    ..name = name
    ..caliberInch = caliberInch
    ..caliberName = caliberName
    ..twistInch = twistInch
    ..barrelLengthInch = barrelLengthInch
    ..zeroElevationRad = zeroElevationRad
    ..vendor = vendor
    ..notes = notes
    ..image = image;
}
