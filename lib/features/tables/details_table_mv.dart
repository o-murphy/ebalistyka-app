import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_profile_provider.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:bclibc_ffi/bclibc.dart' as bclibc;

// ── Spoiler data ─────────────────────────────────────────────────────────────

class DetailsTableData {
  final String rifleName;
  final String? caliber;
  final String? twist;
  final String? dragModel;
  final String? bc;
  final String? zeroMv;
  final String? currentMv;
  final String? zeroDist;
  final String? bulletLen;
  final String? bulletDiam;
  final String? bulletWeight;
  final String? formFactor;
  final String? sectionalDensity;
  final String? gyroStability;
  final String? temperature;
  final String? humidity;
  final String? pressure;
  final String? windSpeed;
  final String? windDir;

  const DetailsTableData({
    required this.rifleName,
    this.caliber,
    this.twist,
    this.dragModel,
    this.bc,
    this.zeroMv,
    this.currentMv,
    this.zeroDist,
    this.bulletLen,
    this.bulletDiam,
    this.bulletWeight,
    this.formFactor,
    this.sectionalDensity,
    this.gyroStability,
    this.temperature,
    this.humidity,
    this.pressure,
    this.windSpeed,
    this.windDir,
  });
}

// ── Private builder ──────────────────────────────────────────────────────────

DetailsTableData _buildDetails(
  Profile profile,
  ShootingConditions conditions,
  UnitSettings units,
) {
  final distUnit = units.distanceUnit;
  final velUnit = units.velocityUnit;
  final weapon = profile.weapon.target!;
  final ammo = profile.ammo.target!;
  final sight = profile.sight.target;

  final twistInch = weapon.twistInch;
  final weightGr = ammo.weightGrain;
  final diamInch = ammo.caliberInch;
  final lenInch = ammo.lengthInch;

  final currentPowderSensOn = conditions.usePowderSensitivity;
  final currentUseDiffTemp = currentPowderSensOn && conditions.useDiffPowderTemp;
  final zeroUseDiffTemp = ammo.zeroUseDiffPowderTemperature;

  final refMvMps = ammo.muzzleVelocityMps ?? 0.0;
  final refPowderTempC = ammo.powderTemperatureC;

  double mvAtTempC(double tCurC) => bclibc.velocityForPowderTemp(
    refMvMps,
    refPowderTempC,
    tCurC,
    ammo.powderSensitivityFrac,
  );

  // Zero MV
  final zeroPowderTempC = zeroUseDiffTemp
      ? ammo.zeroPowderTemperatureC
      : ammo.zeroTemperatureC;
  final zeroMvMps = ammo.usePowderSensitivity
      ? mvAtTempC(zeroPowderTempC)
      : refMvMps;

  // Current MV
  final currTempC = currentUseDiffTemp
      ? conditions.powderTemperatureC
      : conditions.temperatureC;
  final currentMvMps = currentPowderSensOn ? mvAtTempC(currTempC) : refMvMps;

  // Gyrostability (Miller)
  final sightHeight = Distance.inch(sight?.sightHeightInch ?? 0.0);
  final bcWeapon = weapon.toWeapon(sightHeight);
  final currentShot = profile.toCurrentShot(conditions, bcWeapon);
  final sg = currentShot.calculateStabilityCoefficient();

  // Sectional density + form factor
  final sd = (weightGr > 0 && diamInch > 0)
      ? (weightGr / 7000.0) / (diamInch * diamInch)
      : null;
  final displayBc = ammo.isMultiBC
      ? 0.0
      : (ammo.dragType == DragType.g7 ? ammo.bcG7 : ammo.bcG1);
  final ff = (sd != null && displayBc > 0) ? sd / displayBc : null;

  String fmtV(double mps) {
    final disp = Velocity.mps(mps).in_(velUnit);
    return '${disp.toStringAsFixed(FC.velocity.accuracyFor(velUnit))} ${velUnit.symbol}';
  }

  String fmtWithAcc(Dimension dim, Unit dispUnit, FieldConstraints fc) {
    return '${dim.in_(dispUnit).toStringAsFixed(fc.accuracyFor(dispUnit))} ${dispUnit.symbol}';
  }

  return DetailsTableData(
    rifleName: weapon.name,
    caliber: diamInch > 0
        ? fmtWithAcc(ammo.caliber, units.diameterUnit, FC.bulletDiameter)
        : null,
    twist: twistInch.abs() > 0
        ? () {
            final tw = Distance.inch(twistInch.abs()).in_(units.twistUnit);
            return '1:${tw.toStringAsFixed(FC.twist.accuracyFor(units.twistUnit))} ${units.twistUnit.symbol}';
          }()
        : null,
    dragModel: switch (ammo.dragType) {
      DragType.g1 => 'G1',
      DragType.g7 => 'G7',
      DragType.custom => 'Custom',
    },
    bc: displayBc > 0
        ? displayBc.toStringAsFixed(FC.ballisticCoefficient.accuracy)
        : null,
    zeroMv: fmtV(zeroMvMps),
    currentMv: fmtV(currentMvMps),
    zeroDist: fmtWithAcc(
      ammo.zeroDistance,
      distUnit,
      FC.zeroDistance,
    ),
    bulletLen: lenInch > 0
        ? fmtWithAcc(ammo.length, units.lengthUnit, FC.bulletLength)
        : null,
    bulletDiam: diamInch > 0
        ? fmtWithAcc(ammo.caliber, units.diameterUnit, FC.bulletDiameter)
        : null,
    bulletWeight: weightGr > 0
        ? () {
            final wDisp = Weight.grain(weightGr).in_(units.weightUnit);
            return '${wDisp.toStringAsFixed(FC.bulletWeight.accuracyFor(units.weightUnit))} ${units.weightUnit.symbol}';
          }()
        : null,
    formFactor: ff?.toStringAsFixed(3),
    sectionalDensity: sd?.toStringAsFixed(3),
    gyroStability: sg.toStringAsFixed(2),
    temperature: () {
      final t = conditions.temperature.in_(units.temperatureUnit);
      return '${t.toStringAsFixed(FC.temperature.accuracyFor(units.temperatureUnit))} ${units.temperatureUnit.symbol}';
    }(),
    humidity:
        '${(conditions.humidityFrac * 100.0).toStringAsFixed(0)} %',
    pressure: () {
      final p = conditions.pressure.in_(units.pressureUnit);
      return '${p.toStringAsFixed(FC.pressure.accuracyFor(units.pressureUnit))} ${units.pressureUnit.symbol}';
    }(),
    windSpeed: () {
      final ws = conditions.windSpeed.in_(velUnit);
      return '${ws.toStringAsFixed(FC.windVelocity.accuracyFor(velUnit))} ${velUnit.symbol}';
    }(),
    windDir: '${conditions.windDirectionDeg.toStringAsFixed(0)}°',
  );
}

// ── Provider ─────────────────────────────────────────────────────────────────

final detailsTableMvProvider = Provider<DetailsTableData?>((ref) {
  final profile = ref.watch(shotProfileProvider).value;
  final conditions = ref.watch(shotConditionsProvider).value;
  final units = ref.watch(unitSettingsProvider);

  if (profile == null || conditions == null) return null;
  if (profile.weapon.target == null || profile.ammo.target == null) return null;

  return _buildDetails(profile, conditions, units);
});
