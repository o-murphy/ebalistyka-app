import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';

part 'tables_settings_export.g.dart';

@JsonSerializable()
class TablesSettingsExport {
  const TablesSettingsExport({
    required this.distanceStartMeter,
    required this.distanceEndMeter,
    required this.distanceStepMeter,
    required this.showZeros,
    required this.showSubsonicTransition,
    required this.hiddenCols,
    required this.showMil,
    required this.showMrad,
    required this.showMoa,
    required this.showCmPer100m,
    required this.showInPer100yd,
    required this.showInClicks,
  });

  final double distanceStartMeter;
  final double distanceEndMeter;
  final double distanceStepMeter;
  final bool showZeros;
  final bool showSubsonicTransition;
  final List<String> hiddenCols;
  final bool showMil;
  final bool showMrad;
  final bool showMoa;
  final bool showCmPer100m;
  final bool showInPer100yd;
  final bool showInClicks;

  factory TablesSettingsExport.fromJson(Map<String, dynamic> json) =>
      _$TablesSettingsExportFromJson(json);

  Map<String, dynamic> toJson() => _$TablesSettingsExportToJson(this);

  factory TablesSettingsExport.fromEntity(TablesSettings s) =>
      TablesSettingsExport(
        distanceStartMeter: s.distanceStartMeter,
        distanceEndMeter: s.distanceEndMeter,
        distanceStepMeter: s.distanceStepMeter,
        showZeros: s.showZeros,
        showSubsonicTransition: s.showSubsonicTransition,
        hiddenCols: List.unmodifiable(s.hiddenCols),
        showMil: s.showMil,
        showMrad: s.showMrad,
        showMoa: s.showMoa,
        showCmPer100m: s.showCmPer100m,
        showInPer100yd: s.showInPer100yd,
        showInClicks: s.showInClicks,
      );

  TablesSettings toEntity() => TablesSettings()
    ..distanceStartMeter = distanceStartMeter
    ..distanceEndMeter = distanceEndMeter
    ..distanceStepMeter = distanceStepMeter
    ..showZeros = showZeros
    ..showSubsonicTransition = showSubsonicTransition
    ..hiddenCols = List.of(hiddenCols)
    ..showMil = showMil
    ..showMrad = showMrad
    ..showMoa = showMoa
    ..showCmPer100m = showCmPer100m
    ..showInPer100yd = showInPer100yd
    ..showInClicks = showInClicks;
}
