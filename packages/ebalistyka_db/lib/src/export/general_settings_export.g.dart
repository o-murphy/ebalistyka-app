// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'general_settings_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneralSettingsExport _$GeneralSettingsExportFromJson(
  Map<String, dynamic> json,
) => GeneralSettingsExport(
  languageCode: json['languageCode'] as String,
  themeMode: json['themeMode'] as String,
  adjustmentDisplayFormatValue: json['adjustmentDisplayFormatValue'] as String,
  homeShowMil: json['homeShowMil'] as bool,
  homeShowMrad: json['homeShowMrad'] as bool,
  homeShowMoa: json['homeShowMoa'] as bool,
  homeShowCmPer100m: json['homeShowCmPer100m'] as bool,
  homeShowInPer100yd: json['homeShowInPer100yd'] as bool,
  homeShowInClicks: json['homeShowInClicks'] as bool,
  homeChartDistanceStep: (json['homeChartDistanceStep'] as num).toDouble(),
  homeTableDistanceStep: (json['homeTableDistanceStep'] as num).toDouble(),
  homeShowSubsonicTransition: json['homeShowSubsonicTransition'] as bool,
);

Map<String, dynamic> _$GeneralSettingsExportToJson(
  GeneralSettingsExport instance,
) => <String, dynamic>{
  'languageCode': instance.languageCode,
  'themeMode': instance.themeMode,
  'adjustmentDisplayFormatValue': instance.adjustmentDisplayFormatValue,
  'homeShowMil': instance.homeShowMil,
  'homeShowMrad': instance.homeShowMrad,
  'homeShowMoa': instance.homeShowMoa,
  'homeShowCmPer100m': instance.homeShowCmPer100m,
  'homeShowInPer100yd': instance.homeShowInPer100yd,
  'homeShowInClicks': instance.homeShowInClicks,
  'homeChartDistanceStep': instance.homeChartDistanceStep,
  'homeTableDistanceStep': instance.homeTableDistanceStep,
  'homeShowSubsonicTransition': instance.homeShowSubsonicTransition,
};
