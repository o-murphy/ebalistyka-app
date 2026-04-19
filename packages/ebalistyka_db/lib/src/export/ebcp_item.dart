import 'package:json_annotation/json_annotation.dart';

import 'ammo_export.dart';
import 'conditions_export.dart';
import 'general_settings_export.dart';
import 'profile_export.dart';
import 'sight_export.dart';
import 'tables_settings_export.dart';
import 'unit_settings_export.dart';

part 'ebcp_item.g.dart';

const kEbcpTypeProfile = 'profile';
const kEbcpTypeAmmo = 'ammo';
const kEbcpTypeSight = 'sight';
const kEbcpTypeGeneralSettings = 'general_settings';
const kEbcpTypeUnitSettings = 'unit_settings';
const kEbcpTypeTablesSettings = 'tables_settings';
const kEbcpTypeConditions = 'conditions';

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

  factory EbcpItem.fromGeneralSettings(GeneralSettingsExport s) =>
      EbcpItem(type: kEbcpTypeGeneralSettings, data: s.toJson());

  factory EbcpItem.fromUnitSettings(UnitSettingsExport s) =>
      EbcpItem(type: kEbcpTypeUnitSettings, data: s.toJson());

  factory EbcpItem.fromTablesSettings(TablesSettingsExport s) =>
      EbcpItem(type: kEbcpTypeTablesSettings, data: s.toJson());

  factory EbcpItem.fromConditions(ConditionsExport c) =>
      EbcpItem(type: kEbcpTypeConditions, data: c.toJson());

  ProfileExport? asProfile() =>
      type == kEbcpTypeProfile ? ProfileExport.fromJson(data) : null;

  AmmoExport? asAmmo() =>
      type == kEbcpTypeAmmo ? AmmoExport.fromJson(data) : null;

  SightExport? asSight() =>
      type == kEbcpTypeSight ? SightExport.fromJson(data) : null;

  GeneralSettingsExport? asGeneralSettings() => type == kEbcpTypeGeneralSettings
      ? GeneralSettingsExport.fromJson(data)
      : null;

  UnitSettingsExport? asUnitSettings() =>
      type == kEbcpTypeUnitSettings ? UnitSettingsExport.fromJson(data) : null;

  TablesSettingsExport? asTablesSettings() => type == kEbcpTypeTablesSettings
      ? TablesSettingsExport.fromJson(data)
      : null;

  ConditionsExport? asConditions() =>
      type == kEbcpTypeConditions ? ConditionsExport.fromJson(data) : null;
}
