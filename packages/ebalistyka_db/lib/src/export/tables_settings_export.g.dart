// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tables_settings_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TablesSettingsExport _$TablesSettingsExportFromJson(
  Map<String, dynamic> json,
) => TablesSettingsExport(
  distanceStartMeter: (json['distanceStartMeter'] as num).toDouble(),
  distanceEndMeter: (json['distanceEndMeter'] as num).toDouble(),
  distanceStepMeter: (json['distanceStepMeter'] as num).toDouble(),
  showZeros: json['showZeros'] as bool,
  showSubsonicTransition: json['showSubsonicTransition'] as bool,
  hiddenCols: (json['hiddenCols'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  showMil: json['showMil'] as bool,
  showMrad: json['showMrad'] as bool,
  showMoa: json['showMoa'] as bool,
  showCmPer100m: json['showCmPer100m'] as bool,
  showInPer100yd: json['showInPer100yd'] as bool,
  showInClicks: json['showInClicks'] as bool,
);

Map<String, dynamic> _$TablesSettingsExportToJson(
  TablesSettingsExport instance,
) => <String, dynamic>{
  'distanceStartMeter': instance.distanceStartMeter,
  'distanceEndMeter': instance.distanceEndMeter,
  'distanceStepMeter': instance.distanceStepMeter,
  'showZeros': instance.showZeros,
  'showSubsonicTransition': instance.showSubsonicTransition,
  'hiddenCols': instance.hiddenCols,
  'showMil': instance.showMil,
  'showMrad': instance.showMrad,
  'showMoa': instance.showMoa,
  'showCmPer100m': instance.showCmPer100m,
  'showInPer100yd': instance.showInPer100yd,
  'showInClicks': instance.showInClicks,
};
