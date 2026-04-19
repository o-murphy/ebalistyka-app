// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileExport _$ProfileExportFromJson(Map<String, dynamic> json) =>
    ProfileExport(
      name: json['name'] as String,
      weapon: WeaponExport.fromJson(json['weapon'] as Map<String, dynamic>),
      ammo: json['ammo'] == null
          ? null
          : AmmoExport.fromJson(json['ammo'] as Map<String, dynamic>),
      sight: json['sight'] == null
          ? null
          : SightExport.fromJson(json['sight'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProfileExportToJson(ProfileExport instance) =>
    <String, dynamic>{
      'name': instance.name,
      'weapon': instance.weapon,
      'ammo': ?instance.ammo,
      'sight': ?instance.sight,
    };
