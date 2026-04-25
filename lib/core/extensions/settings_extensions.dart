import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';

enum AdjustmentDisplayFormat { arrows, signs, letters }

extension GeneralSettingsExtension on GeneralSettings {
  // ── Enum ─────────────────────────────────────────────────────────────────────

  AdjustmentDisplayFormat get adjustmentDisplayFormat =>
      AdjustmentDisplayFormat.values.firstWhere(
        (e) => e.name == adjustmentDisplayFormatValue,
        orElse: () => AdjustmentDisplayFormat.arrows,
      );
  set adjustmentDisplayFormat(AdjustmentDisplayFormat v) =>
      adjustmentDisplayFormatValue = v.name;

  ThemeMode get flutterThemeMode => switch (themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system, // '_' replaces 'default'
  };

  set flutterThemeMode(ThemeMode v) => themeMode = switch (v) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}

extension UnitSettingsExtension on UnitSettings {
  Unit get angularUnit =>
      Unit.values.firstWhere((u) => u.name == angular, orElse: () => Unit.mil);
  set angularUnit(Unit v) => angular = v.name;

  Unit get distanceUnit => Unit.values.firstWhere(
    (u) => u.name == distance,
    orElse: () => Unit.meter,
  );
  set distanceUnit(Unit v) => distance = v.name;

  Unit get velocityUnit =>
      Unit.values.firstWhere((u) => u.name == velocity, orElse: () => Unit.mps);
  set velocityUnit(Unit v) => velocity = v.name;

  Unit get pressureUnit =>
      Unit.values.firstWhere((u) => u.name == pressure, orElse: () => Unit.hPa);
  set pressureUnit(Unit v) => pressure = v.name;

  Unit get temperatureUnit => Unit.values.firstWhere(
    (u) => u.name == temperature,
    orElse: () => Unit.celsius,
  );
  set temperatureUnit(Unit v) => temperature = v.name;

  Unit get diameterUnit => Unit.values.firstWhere(
    (u) => u.name == diameter,
    orElse: () => Unit.inch,
  );
  set diameterUnit(Unit v) => diameter = v.name;

  Unit get lengthUnit =>
      Unit.values.firstWhere((u) => u.name == length, orElse: () => Unit.inch);
  set lengthUnit(Unit v) => length = v.name;

  Unit get weightUnit =>
      Unit.values.firstWhere((u) => u.name == weight, orElse: () => Unit.grain);
  set weightUnit(Unit v) => weight = v.name;

  Unit get dropUnit => Unit.values.firstWhere(
    (u) => u.name == drop,
    orElse: () => Unit.centimeter,
  );
  set dropUnit(Unit v) => drop = v.name;

  Unit get energyUnit =>
      Unit.values.firstWhere((u) => u.name == energy, orElse: () => Unit.joule);
  set energyUnit(Unit v) => energy = v.name;

  Unit get targetSizeUnit => Unit.values.firstWhere(
    (u) => u.name == targetSize,
    orElse: () => Unit.mil,
  );
  set targetSizeUnit(Unit v) => targetSize = v.name;
}

extension TablesSettingsExtension on TablesSettings {
  List<Unit> get enabledAdjUnits => [
    if (showMil) Unit.mil,
    if (showMrad) Unit.mRad,
    if (showMoa) Unit.moa,
    if (showCmPer100m) Unit.cmPer100m,
    if (showInPer100yd) Unit.inPer100Yd,
  ];
}

extension UnitSettingsFullExtension on UnitSettings {
  Unit get adjustmentUnit => Unit.values.firstWhere(
    (u) => u.name == adjustment,
    orElse: () => Unit.mil,
  );
  set adjustmentUnit(Unit v) => adjustment = v.name;

  Unit get sightHeightUnit => Unit.values.firstWhere(
    (u) => u.name == sightHeight,
    orElse: () => Unit.millimeter,
  );
  set sightHeightUnit(Unit v) => sightHeight = v.name;

  Unit get twistUnit =>
      Unit.values.firstWhere((u) => u.name == twist, orElse: () => Unit.inch);
  set twistUnit(Unit v) => twist = v.name;

  Unit get barrelLengthUnit => Unit.values.firstWhere(
    (u) => u.name == barrelLength,
    orElse: () => Unit.inch,
  );
  set barrelLengthUnit(Unit v) => barrelLength = v.name;

  Unit get torqueUnit => Unit.values.firstWhere(
    (u) => u.name == torque,
    orElse: () => Unit.newtonMeter,
  );
  set torqueUnit(Unit v) => torque = v.name;
}

extension ReticleSettingsExtension on ReticleSettings {
  Unit get verticalAdjustmentUnitValue => Unit.values.firstWhere(
    (u) => u.name == verticalAdjustmentUnit,
    orElse: () => Unit.mil,
  );
  set verticalAdjustmentUnitValue(Unit v) => verticalAdjustmentUnit = v.name;

  Unit get horizontalAdjustmentUnitValue => Unit.values.firstWhere(
    (u) => u.name == horizontalAdjustmentUnit,
    orElse: () => Unit.mil,
  );
  set horizontalAdjustmentUnitValue(Unit v) =>
      horizontalAdjustmentUnit = v.name;

  bool get verticalAdjInClicks => verticalAdjustmentUnit == 'clicks';
  bool get horizontalAdjInClicks => horizontalAdjustmentUnit == 'clicks';
}
