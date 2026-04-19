import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';
import 'conditions_export.dart';
import 'general_settings_export.dart';
import 'tables_settings_export.dart';
import 'unit_settings_export.dart';

part 'settings_export.g.dart';

@JsonSerializable()
class SettingsExport {
  const SettingsExport({
    required this.general,
    required this.units,
    required this.tables,
    required this.conditions,
  });

  final GeneralSettingsExport general;
  final UnitSettingsExport units;
  final TablesSettingsExport tables;
  final ConditionsExport conditions;

  factory SettingsExport.fromJson(Map<String, dynamic> json) =>
      _$SettingsExportFromJson(json);

  Map<String, dynamic> toJson() => _$SettingsExportToJson(this);

  factory SettingsExport.fromEntities(
    GeneralSettings g,
    UnitSettings u,
    TablesSettings t,
    ShootingConditions c,
  ) => SettingsExport(
    general: GeneralSettingsExport.fromEntity(g),
    units: UnitSettingsExport.fromEntity(u),
    tables: TablesSettingsExport.fromEntity(t),
    conditions: ConditionsExport.fromEntity(c),
  );
}
