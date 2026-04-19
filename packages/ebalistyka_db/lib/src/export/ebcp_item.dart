import 'package:json_annotation/json_annotation.dart';

import 'ammo_export.dart';
import 'profile_export.dart';
import 'settings_export.dart';
import 'sight_export.dart';

part 'ebcp_item.g.dart';

const kEbcpTypeProfile = 'profile';
const kEbcpTypeAmmo = 'ammo';
const kEbcpTypeSight = 'sight';
const kEbcpTypeSettings = 'settings';

@JsonSerializable()
class EbcpItem {
  const EbcpItem({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;

  factory EbcpItem.fromJson(Map<String, dynamic> json) =>
      _$EbcpItemFromJson(json);

  Map<String, dynamic> toJson() => _$EbcpItemToJson(this);

  factory EbcpItem.fromProfile(ProfileExport p) =>
      EbcpItem(type: kEbcpTypeProfile, data: p.toJson());

  factory EbcpItem.fromAmmo(AmmoExport a) =>
      EbcpItem(type: kEbcpTypeAmmo, data: a.toJson());

  factory EbcpItem.fromSight(SightExport s) =>
      EbcpItem(type: kEbcpTypeSight, data: s.toJson());

  factory EbcpItem.fromSettings(SettingsExport s) =>
      EbcpItem(type: kEbcpTypeSettings, data: s.toJson());

  ProfileExport? asProfile() =>
      type == kEbcpTypeProfile ? ProfileExport.fromJson(data) : null;

  AmmoExport? asAmmo() =>
      type == kEbcpTypeAmmo ? AmmoExport.fromJson(data) : null;

  SightExport? asSight() =>
      type == kEbcpTypeSight ? SightExport.fromJson(data) : null;

  SettingsExport? asSettings() =>
      type == kEbcpTypeSettings ? SettingsExport.fromJson(data) : null;
}
