// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsExport _$SettingsExportFromJson(Map<String, dynamic> json) =>
    SettingsExport(
      general: GeneralSettingsExport.fromJson(
        json['general'] as Map<String, dynamic>,
      ),
      units: UnitSettingsExport.fromJson(json['units'] as Map<String, dynamic>),
      tables: TablesSettingsExport.fromJson(
        json['tables'] as Map<String, dynamic>,
      ),
      conditions: ConditionsExport.fromJson(
        json['conditions'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SettingsExportToJson(SettingsExport instance) =>
    <String, dynamic>{
      'general': instance.general,
      'units': instance.units,
      'tables': instance.tables,
      'conditions': instance.conditions,
    };
