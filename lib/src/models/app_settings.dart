import 'package:flutter/material.dart';

import 'unit_settings.dart';

class AppSettings {
  final UnitSettings units;
  final String languageCode;
  final ThemeMode themeMode;
  final double tableDistanceStep;
  final bool enableCoriolis;
  final bool enablePowderSensitivity;
  final bool enableDerivation;
  final bool enableAerodynamicJump;
  final bool pressureDependsOnAltitude;

  const AppSettings({
    this.units                    = const UnitSettings(),
    this.languageCode             = 'en',
    this.themeMode                = ThemeMode.system,
    this.tableDistanceStep        = 100,
    this.enableCoriolis           = false,
    this.enablePowderSensitivity  = false,
    this.enableDerivation         = false,
    this.enableAerodynamicJump    = false,
    this.pressureDependsOnAltitude = false,
  });

  AppSettings copyWith({
    UnitSettings? units,
    String? languageCode,
    ThemeMode? themeMode,
    double? tableDistanceStep,
    bool? enableCoriolis,
    bool? enablePowderSensitivity,
    bool? enableDerivation,
    bool? enableAerodynamicJump,
    bool? pressureDependsOnAltitude,
  }) => AppSettings(
    units:                      units                     ?? this.units,
    languageCode:               languageCode              ?? this.languageCode,
    themeMode:                  themeMode                 ?? this.themeMode,
    tableDistanceStep:          tableDistanceStep         ?? this.tableDistanceStep,
    enableCoriolis:             enableCoriolis            ?? this.enableCoriolis,
    enablePowderSensitivity:    enablePowderSensitivity   ?? this.enablePowderSensitivity,
    enableDerivation:           enableDerivation          ?? this.enableDerivation,
    enableAerodynamicJump:      enableAerodynamicJump     ?? this.enableAerodynamicJump,
    pressureDependsOnAltitude:  pressureDependsOnAltitude ?? this.pressureDependsOnAltitude,
  );

  static const _themeModeNames = {
    ThemeMode.system: 'system',
    ThemeMode.light:  'light',
    ThemeMode.dark:   'dark',
  };
  static const _themeModeByName = {
    'system': ThemeMode.system,
    'light':  ThemeMode.light,
    'dark':   ThemeMode.dark,
  };

  Map<String, dynamic> toJson() => {
    'units':                      units.toJson(),
    'languageCode':               languageCode,
    'themeMode':                  _themeModeNames[themeMode],
    'tableDistanceStep':          tableDistanceStep,
    'enableCoriolis':             enableCoriolis,
    'enablePowderSensitivity':    enablePowderSensitivity,
    'enableDerivation':           enableDerivation,
    'enableAerodynamicJump':      enableAerodynamicJump,
    'pressureDependsOnAltitude':  pressureDependsOnAltitude,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    units:                      UnitSettings.fromJson(json['units'] as Map<String, dynamic>? ?? {}),
    languageCode:               json['languageCode'] as String? ?? 'en',
    themeMode:                  _themeModeByName[json['themeMode']] ?? ThemeMode.system,
    tableDistanceStep:          (json['tableDistanceStep'] as num?)?.toDouble() ?? 100,
    enableCoriolis:             json['enableCoriolis'] as bool? ?? false,
    enablePowderSensitivity:    json['enablePowderSensitivity'] as bool? ?? false,
    enableDerivation:           json['enableDerivation'] as bool? ?? false,
    enableAerodynamicJump:      json['enableAerodynamicJump'] as bool? ?? false,
    pressureDependsOnAltitude:  json['pressureDependsOnAltitude'] as bool? ?? false,
  );
}
