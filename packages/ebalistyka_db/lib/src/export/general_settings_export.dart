import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'general_settings_export.g.dart';

@JsonSerializable()
class GeneralSettingsExport {
  const GeneralSettingsExport({
    required this.languageCode,
    required this.themeMode,
    required this.adjustmentDisplayFormatValue,
    required this.homeShowMil,
    required this.homeShowMrad,
    required this.homeShowMoa,
    required this.homeShowCmPer100m,
    required this.homeShowInPer100yd,
    required this.homeShowInClicks,
    required this.homeChartDistanceStep,
    required this.homeTableDistanceStep,
    required this.homeShowSubsonicTransition,
  });

  final String languageCode;
  final String themeMode;
  final String adjustmentDisplayFormatValue;
  final bool homeShowMil;
  final bool homeShowMrad;
  final bool homeShowMoa;
  final bool homeShowCmPer100m;
  final bool homeShowInPer100yd;
  final bool homeShowInClicks;
  final double homeChartDistanceStep;
  final double homeTableDistanceStep;
  final bool homeShowSubsonicTransition;

  factory GeneralSettingsExport.fromJson(Map<String, dynamic> json) =>
      _$GeneralSettingsExportFromJson(json);

  Map<String, dynamic> toJson() => _$GeneralSettingsExportToJson(this);

  factory GeneralSettingsExport.fromEntity(GeneralSettings s) =>
      GeneralSettingsExport(
        languageCode: s.languageCode,
        themeMode: s.themeMode,
        adjustmentDisplayFormatValue: s.adjustmentDisplayFormatValue,
        homeShowMil: s.homeShowMil,
        homeShowMrad: s.homeShowMrad,
        homeShowMoa: s.homeShowMoa,
        homeShowCmPer100m: s.homeShowCmPer100m,
        homeShowInPer100yd: s.homeShowInPer100yd,
        homeShowInClicks: s.homeShowInClicks,
        homeChartDistanceStep: s.homeChartDistanceStep,
        homeTableDistanceStep: s.homeTableDistanceStep,
        homeShowSubsonicTransition: s.homeShowSubsonicTransition,
      );

  GeneralSettings toEntity() => GeneralSettings()
    ..languageCode = languageCode
    ..themeMode = themeMode
    ..adjustmentDisplayFormatValue = adjustmentDisplayFormatValue
    ..homeShowMil = homeShowMil
    ..homeShowMrad = homeShowMrad
    ..homeShowMoa = homeShowMoa
    ..homeShowCmPer100m = homeShowCmPer100m
    ..homeShowInClicks = homeShowInClicks
    ..homeShowInPer100yd = homeShowInPer100yd
    ..homeChartDistanceStep = homeChartDistanceStep
    ..homeTableDistanceStep = homeTableDistanceStep
    ..homeShowSubsonicTransition = homeShowSubsonicTransition;
}
