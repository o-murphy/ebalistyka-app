import 'dart:typed_data';

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

enum DragType { g1, g7, custom }

extension AmmoExtension on Ammo {
  // ── Enum ─────────────────────────────────────────────────────────────────────

  DragType get dragType => DragType.values.firstWhere(
    (e) => e.name == dragTypeValue,
    orElse: () => DragType.g1,
  );
  set dragType(DragType v) => dragTypeValue = v.name;

  // ── Physical unit getters/setters ────────────────────────────────────────────

  Distance get caliber => Distance.inch(caliberInch);
  set caliber(Distance v) => caliberInch = v.in_(Unit.inch);

  Distance get length => Distance.inch(lengthInch);
  set length(Distance v) => lengthInch = v.in_(Unit.inch);

  Weight get weight => Weight.grain(weightGrain);
  set weight(Weight v) => weightGrain = v.in_(Unit.grain);

  Velocity? get mv =>
      muzzleVelocityMps != null ? Velocity.mps(muzzleVelocityMps!) : null;
  set mv(Velocity v) => muzzleVelocityMps = v.in_(Unit.mps);

  Temperature get mvTemperature =>
      Temperature.celsius(muzzleVelocityTemperatureC);
  set mvTemperature(Temperature t) =>
      muzzleVelocityTemperatureC = t.in_(Unit.celsius);

  Ratio get powderSensitivity => Ratio.fraction(powderSensitivityFrac);
  set powderSensitivity(Ratio v) =>
      powderSensitivityFrac = v.in_(Unit.fraction);

  // ── Zero conditions ──────────────────────────────────────────────────────────

  Distance get zeroDistance => Distance.meter(zeroDistanceMeter);
  set zeroDistance(Distance v) => zeroDistanceMeter = v.in_(Unit.meter);

  Angular get zeroLookAngle => Angular.radian(zeroLookAngleRad);
  set zeroLookAngle(Angular v) => zeroLookAngleRad = v.in_(Unit.radian);

  Distance get zeroAltitude => Distance.meter(zeroAltitudeMeter);
  set zeroAltitude(Distance v) => zeroAltitudeMeter = v.in_(Unit.meter);

  Temperature get zeroTemperature => Temperature.celsius(zeroTemperatureC);
  set zeroTemperature(Temperature v) => zeroTemperatureC = v.in_(Unit.celsius);

  Pressure get zeroPressure => Pressure.hPa(zeroPressurehPa);
  set zeroPressure(Pressure v) => zeroPressurehPa = v.in_(Unit.hPa);

  Temperature get zeroPowderTemp => Temperature.celsius(zeroPowderTemperatureC);
  set zeroPowderTemp(Temperature v) =>
      zeroPowderTemperatureC = v.in_(Unit.celsius);

  Angular get zeroLatitude => Angular.degree(zeroLatitudeDeg);
  set zeroLatitude(Angular v) => zeroLatitudeDeg = v.in_(Unit.degree);

  Angular get zeroAzimuth => Angular.degree(zeroAzimuthDeg);
  set zeroAzimuth(Angular v) => zeroAzimuthDeg = v.in_(Unit.degree);

  // ── Drag model helpers ────────────────────────────────────────────────────────

  /// True when G1/G7 with multiple BC breakpoints (velocity-dependent BC).
  bool get isMultiBC => switch (dragType) {
    DragType.g1 => useMultiBcG1 && (multiBcTableG1VMps?.isNotEmpty ?? false),
    DragType.g7 => useMultiBcG7 && (multiBcTableG7VMps?.isNotEmpty ?? false),
    DragType.custom => false,
  };

  bool get isReadyForCalculation =>
      muzzleVelocityMps != null && muzzleVelocityMps! > 0;

  bclibc.DragModel toDragModel() {
    switch (dragType) {
      case DragType.g1:
      case DragType.g7:
        final baseTable = dragType == DragType.g7
            ? bclibc.tableG7
            : bclibc.tableG1;
        final bc = dragType == DragType.g7 ? bcG7 : bcG1;

        if (isMultiBC) {
          final vMps = dragType == DragType.g7
              ? multiBcTableG7VMps!
              : multiBcTableG1VMps!;
          final bcs = dragType == DragType.g7
              ? multiBcTableG7Bc!
              : multiBcTableG1Bc!;
          final bcPoints = List.generate(
            vMps.length,
            (i) => bclibc.BCPoint(bc: bcs[i], v: Velocity(vMps[i], Unit.mps)),
          );
          return bclibc.createDragModelMultiBC(
            bcPoints: bcPoints,
            dragTable: baseTable,
            weight: weight,
            diameter: caliber,
            length: length,
          );
        }

        return bclibc.DragModel(
          bc: bc > 0 ? bc : 1.0,
          dragTable: baseTable,
          weight: weight,
          diameter: caliber,
          length: length,
        );

      case DragType.custom:
        final mach = cusomDragTableMach ?? Float64List(0);
        final cd = cusomDragTableCd ?? Float64List(0);
        final table = List.generate(
          mach.length,
          (i) => (mach: mach[i], cd: cd[i]),
        );
        final sd = (weightGrain > 0 && caliberInch > 0)
            ? bclibc.calculateSectionalDensity(weightGrain, caliberInch)
            : 0.0;
        return bclibc.DragModel(
          bc: sd > 0 ? sd : 1.0,
          dragTable: table.isNotEmpty ? table : bclibc.tableG1,
          weight: weight,
          diameter: caliber,
          length: length,
        );
    }
  }

  bclibc.Ammo toZeroAmmo() => bclibc.Ammo(
    dm: toDragModel(),
    mv: mv,
    powderTemp: mvTemperature,
    tempModifier: powderSensitivityFrac,
    usePowderSensitivity: usePowderSensitivity,
  );

  bclibc.Ammo toCurrentAmmo(ShootingConditions cond) => bclibc.Ammo(
    dm: toDragModel(),
    mv: mv,
    powderTemp: mvTemperature,
    tempModifier: powderSensitivityFrac,
    usePowderSensitivity: cond.usePowderSensitivity,
  );

  bclibc.Atmo toZeroAtmo() => bclibc.Atmo(
    altitude: zeroAltitude,
    pressure: zeroPressure,
    temperature: zeroTemperature,
    humidity: zeroHumidityFrac,
    powderTemperature: zeroUseDiffPowderTemperature
        ? zeroPowderTemp
        : zeroTemperature,
  );
}
