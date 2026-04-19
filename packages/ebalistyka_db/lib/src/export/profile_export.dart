import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';
import 'ammo_export.dart';
import 'sight_export.dart';
import 'weapon_export.dart';

part 'profile_export.g.dart';

@JsonSerializable(includeIfNull: false)
class ProfileExport {
  const ProfileExport({
    required this.name,
    required this.weapon,
    this.ammo,
    this.sight,
  });

  final String name;
  final WeaponExport weapon;
  final AmmoExport? ammo;
  final SightExport? sight;

  factory ProfileExport.fromJson(Map<String, dynamic> json) =>
      _$ProfileExportFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileExportToJson(this);

  factory ProfileExport.fromEntities(
    Profile profile,
    Weapon weapon,
    Ammo? ammo,
    Sight? sight,
  ) => ProfileExport(
    name: profile.name,
    weapon: WeaponExport.fromEntity(weapon),
    ammo: ammo != null ? AmmoExport.fromEntity(ammo) : null,
    sight: sight != null ? SightExport.fromEntity(sight) : null,
  );

  (Profile, Weapon, Ammo?, Sight?) toEntities() => (
    Profile()..name = name,
    weapon.toEntity(),
    ammo?.toEntity(),
    sight?.toEntity(),
  );
}
