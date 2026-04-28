import 'dart:typed_data';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_parsers.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

class AmmoWizardFormState {
  const AmmoWizardFormState({
    required this.name,
    required this.vendor,
    required this.projectileName,
    required this.caliberRaw,
    required this.weightRaw,
    required this.lengthRaw,
    required this.dragType,
    required this.useMultiBcG1,
    required this.useMultiBcG7,
    required this.bcG1,
    required this.bcG7,
    required this.multiBcG1Table,
    required this.multiBcG7Table,
    required this.customDragTable,
    required this.powderSensTable,
    required this.mvRaw,
    required this.mvTempRaw,
    required this.zeroDistRaw,
    required this.zeroLookAngleRaw,
    required this.zeroTempRaw,
    required this.zeroAltRaw,
    required this.zeroPressureRaw,
    required this.zeroHumidityRaw,
    required this.usePowderSensitivity,
    required this.powderSensRaw,
    required this.zeroUseDiffPowderTemp,
    required this.zeroPowderTempRaw,
    required this.zeroUseCoriolis,
    required this.zeroLatitudeRaw,
    required this.zeroAzimuthRaw,
    required this.offsetXRaw,
    required this.offsetXUnit,
    required this.offsetYRaw,
    required this.offsetYUnit,
  });

  factory AmmoWizardFormState.fromAmmo({
    required Ammo? initial,
    required double? caliberInch,
  }) {
    final a = initial;
    final caliberRaw = (a != null && a.caliberInch > 0)
        ? a.caliber.in_(FC.projectileDiameter.rawUnit)
        : Distance.inch(
            caliberInch ?? FC.projectileDiameter.minRaw,
          ).in_(FC.projectileDiameter.rawUnit);

    return AmmoWizardFormState(
      name: a?.name ?? '',
      vendor: a?.vendor ?? '',
      projectileName: a?.projectileName ?? '',
      caliberRaw: caliberRaw,
      weightRaw: (a != null && a.weightGrain > 0)
          ? a.weight.in_(FC.projectileWeight.rawUnit)
          : null,
      lengthRaw: (a != null && a.lengthInch > 0)
          ? a.length.in_(FC.projectileLength.rawUnit)
          : null,
      dragType: a?.dragType ?? DragType.g1,
      useMultiBcG1: a?.useMultiBcG1 ?? false,
      useMultiBcG7: a?.useMultiBcG7 ?? false,
      bcG1: (a != null && a.bcG1 > 0) ? a.bcG1 : null,
      bcG7: (a != null && a.bcG7 > 0) ? a.bcG7 : null,
      multiBcG1Table: decodeBcTable(a?.multiBcTableG1VMps, a?.multiBcTableG1Bc),
      multiBcG7Table: decodeBcTable(a?.multiBcTableG7VMps, a?.multiBcTableG7Bc),
      customDragTable: decodeCustomDragTable(
        a?.customDragTableMach,
        a?.customDragTableCd,
      ),
      powderSensTable: decodePowderSensTable(
        a?.powderSensitivityTC,
        a?.powderSensitivityVMps,
      ),
      mvRaw: a?.mv?.in_(FC.muzzleVelocity.rawUnit),
      mvTempRaw: a?.mvTemperature.in_(FC.temperature.rawUnit) ?? 15.0,
      zeroDistRaw: a?.zeroDistance.in_(FC.zeroDistance.rawUnit) ?? 100.0,
      zeroLookAngleRaw: a?.zeroLookAngle.in_(FC.lookAngle.rawUnit) ?? 0.0,
      zeroTempRaw: a?.zeroTemperature.in_(FC.temperature.rawUnit) ?? 15.0,
      zeroAltRaw: a?.zeroAltitude.in_(FC.altitude.rawUnit) ?? 0.0,
      zeroPressureRaw: a?.zeroPressure.in_(FC.pressure.rawUnit) ?? 1013.0,
      zeroHumidityRaw: a?.zeroHumidityFrac ?? 0.0,
      usePowderSensitivity: a?.usePowderSensitivity ?? false,
      powderSensRaw: a?.powderSensitivityFrac ?? 0.0,
      zeroUseDiffPowderTemp: a?.zeroUseDiffPowderTemperature ?? false,
      zeroPowderTempRaw: a?.zeroPowderTemp.in_(FC.temperature.rawUnit) ?? 15.0,
      zeroUseCoriolis: a?.zeroUseCoriolis ?? false,
      zeroLatitudeRaw: a?.zeroLatitudeDeg ?? 0.0,
      zeroAzimuthRaw: a?.zeroAzimuthDeg ?? 0.0,
      offsetYUnit: a?.zeroOffsetYUnitValue ?? Unit.mil,
      offsetYRaw: a == null
          ? Angular.mil(0.1).in_(FC.adjustment.rawUnit)
          : Angular(
              a.zeroOffsetY,
              a.zeroOffsetYUnitValue,
            ).in_(FC.adjustment.rawUnit),
      offsetXUnit: a?.zeroOffsetXUnitValue ?? Unit.mil,
      offsetXRaw: a == null
          ? Angular.mil(0.1).in_(FC.adjustment.rawUnit)
          : Angular(
              a.zeroOffsetX,
              a.zeroOffsetXUnitValue,
            ).in_(FC.adjustment.rawUnit),
    );
  }

  // ── Fields ────────────────────────────────────────────────────────────────

  final String name;
  final String vendor;
  final String projectileName;
  final double caliberRaw;
  final double? weightRaw;
  final double? lengthRaw;
  final DragType dragType;
  final bool useMultiBcG1;
  final bool useMultiBcG7;
  final double? bcG1;
  final double? bcG7;
  final List<({double vMps, double bc})>? multiBcG1Table;
  final List<({double vMps, double bc})>? multiBcG7Table;
  final List<({double mach, double cd})>? customDragTable;
  final List<({double tempC, double vMps})>? powderSensTable;
  final double? mvRaw;
  final double mvTempRaw;
  final double zeroDistRaw;
  final double zeroLookAngleRaw;
  final double zeroTempRaw;
  final double zeroAltRaw;
  final double zeroPressureRaw;
  final double zeroHumidityRaw;
  final bool usePowderSensitivity;
  final double powderSensRaw;
  final bool zeroUseDiffPowderTemp;
  final double zeroPowderTempRaw;
  final bool zeroUseCoriolis;
  final double zeroLatitudeRaw;
  final double zeroAzimuthRaw;
  final double offsetXRaw;
  final Unit offsetXUnit;
  final double offsetYRaw;
  final Unit offsetYUnit;

  // ── Validation ────────────────────────────────────────────────────────────

  bool get isValid {
    if (name.trim().isEmpty) return false;
    if (caliberRaw <= 0) return false;
    if ((weightRaw ?? 0) <= 0) return false;
    if ((lengthRaw ?? 0) <= 0) return false;
    if ((mvRaw ?? 0) <= 0) return false;
    if (dragType == DragType.g1) {
      if (useMultiBcG1) {
        if (multiBcG1Table == null || multiBcG1Table!.isEmpty) return false;
      } else if ((bcG1 ?? 0) <= 0) {
        return false;
      }
    }
    if (dragType == DragType.g7) {
      if (useMultiBcG7) {
        if (multiBcG7Table == null || multiBcG7Table!.isEmpty) return false;
      } else if ((bcG7 ?? 0) <= 0) {
        return false;
      }
    }
    if (dragType == DragType.custom) {
      if (customDragTable == null || customDragTable!.isEmpty) return false;
    }
    return true;
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Ammo buildAmmo(Ammo? initial) {
    final ammo = initial ?? Ammo();
    ammo.name = name.trim();
    ammo.vendor = vendor.trim().isEmpty ? null : vendor.trim();
    ammo.projectileName = projectileName.trim().isEmpty
        ? null
        : projectileName.trim();

    ammo.caliber = Distance(caliberRaw, FC.projectileDiameter.rawUnit);
    ammo.weightGrain = weightRaw != null
        ? Weight(weightRaw!, FC.projectileWeight.rawUnit).in_(Unit.grain)
        : -1.0;
    ammo.lengthInch = lengthRaw != null
        ? Distance(lengthRaw!, FC.projectileLength.rawUnit).in_(Unit.inch)
        : -1.0;

    ammo.dragType = dragType;
    ammo.useMultiBcG1 = useMultiBcG1;
    ammo.useMultiBcG7 = useMultiBcG7;
    ammo.bcG1 = bcG1 ?? -1.0;
    ammo.bcG7 = bcG7 ?? -1.0;

    final g1 = multiBcG1Table;
    if (g1 != null && g1.isNotEmpty) {
      ammo.multiBcTableG1VMps = Float64List.fromList(
        g1.map((r) => r.vMps).toList(),
      );
      ammo.multiBcTableG1Bc = Float64List.fromList(
        g1.map((r) => r.bc).toList(),
      );
    } else {
      ammo.multiBcTableG1VMps = null;
      ammo.multiBcTableG1Bc = null;
    }

    final g7 = multiBcG7Table;
    if (g7 != null && g7.isNotEmpty) {
      ammo.multiBcTableG7VMps = Float64List.fromList(
        g7.map((r) => r.vMps).toList(),
      );
      ammo.multiBcTableG7Bc = Float64List.fromList(
        g7.map((r) => r.bc).toList(),
      );
    } else {
      ammo.multiBcTableG7VMps = null;
      ammo.multiBcTableG7Bc = null;
    }

    final custom = customDragTable;
    if (custom != null && custom.isNotEmpty) {
      ammo.customDragTableMach = Float64List.fromList(
        custom.map((r) => r.mach).toList(),
      );
      ammo.customDragTableCd = Float64List.fromList(
        custom.map((r) => r.cd).toList(),
      );
    } else {
      ammo.customDragTableMach = null;
      ammo.customDragTableCd = null;
    }

    ammo.muzzleVelocityMps = mvRaw != null
        ? Velocity(mvRaw!, FC.muzzleVelocity.rawUnit).in_(Unit.mps)
        : -1.0;
    ammo.mvTemperature = Temperature(mvTempRaw, FC.temperature.rawUnit);

    ammo.zeroDistance = Distance(zeroDistRaw, FC.zeroDistance.rawUnit);
    ammo.zeroLookAngle = Angular(zeroLookAngleRaw, FC.lookAngle.rawUnit);
    ammo.zeroTemperature = Temperature(zeroTempRaw, FC.temperature.rawUnit);
    ammo.zeroPressure = Pressure(zeroPressureRaw, FC.pressure.rawUnit);
    ammo.zeroHumidityFrac = zeroHumidityRaw;
    ammo.zeroAltitude = Distance(zeroAltRaw, FC.altitude.rawUnit);

    ammo.usePowderSensitivity = usePowderSensitivity;
    ammo.powderSensitivity = Ratio.fraction(powderSensRaw);

    final psTable = powderSensTable;
    if (psTable != null && psTable.isNotEmpty) {
      ammo.powderSensitivityTC = Float64List.fromList(
        psTable.map((r) => r.tempC).toList(),
      );
      ammo.powderSensitivityVMps = Float64List.fromList(
        psTable.map((r) => r.vMps).toList(),
      );
    } else {
      ammo.powderSensitivityTC = null;
      ammo.powderSensitivityVMps = null;
    }

    ammo.zeroUseDiffPowderTemperature = zeroUseDiffPowderTemp;
    ammo.zeroPowderTemp = Temperature(
      zeroPowderTempRaw,
      FC.temperature.rawUnit,
    );

    ammo.zeroUseCoriolis = zeroUseCoriolis;
    ammo.zeroLatitudeDeg = zeroLatitudeRaw;
    ammo.zeroAzimuthDeg = zeroAzimuthRaw;

    ammo.zeroOffsetYUnitValue = offsetYUnit;
    ammo.zeroOffsetY = Angular(
      offsetYRaw,
      FC.adjustment.rawUnit,
    ).in_(offsetYUnit);
    ammo.zeroOffsetXUnitValue = offsetXUnit;
    ammo.zeroOffsetX = Angular(
      offsetXRaw,
      FC.adjustment.rawUnit,
    ).in_(offsetXUnit);

    return ammo;
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  AmmoWizardFormState copyWith({
    String? name,
    String? vendor,
    String? projectileName,
    double? caliberRaw,
    double? weightRaw,
    double? lengthRaw,
    DragType? dragType,
    bool? useMultiBcG1,
    bool? useMultiBcG7,
    double? bcG1,
    double? bcG7,
    List<({double vMps, double bc})>? multiBcG1Table,
    List<({double vMps, double bc})>? multiBcG7Table,
    List<({double mach, double cd})>? customDragTable,
    List<({double tempC, double vMps})>? powderSensTable,
    double? mvRaw,
    double? mvTempRaw,
    double? zeroDistRaw,
    double? zeroLookAngleRaw,
    double? zeroTempRaw,
    double? zeroAltRaw,
    double? zeroPressureRaw,
    double? zeroHumidityRaw,
    bool? usePowderSensitivity,
    double? powderSensRaw,
    bool? zeroUseDiffPowderTemp,
    double? zeroPowderTempRaw,
    bool? zeroUseCoriolis,
    double? zeroLatitudeRaw,
    double? zeroAzimuthRaw,
    double? offsetXRaw,
    Unit? offsetXUnit,
    double? offsetYRaw,
    Unit? offsetYUnit,
    // Flags to explicitly null out optional fields
    bool clearWeight = false,
    bool clearLength = false,
    bool clearMv = false,
    bool clearBcG1 = false,
    bool clearBcG7 = false,
    bool clearMultiBcG1Table = false,
    bool clearMultiBcG7Table = false,
    bool clearCustomDragTable = false,
    bool clearPowderSensTable = false,
  }) {
    return AmmoWizardFormState(
      name: name ?? this.name,
      vendor: vendor ?? this.vendor,
      projectileName: projectileName ?? this.projectileName,
      caliberRaw: caliberRaw ?? this.caliberRaw,
      weightRaw: clearWeight ? null : (weightRaw ?? this.weightRaw),
      lengthRaw: clearLength ? null : (lengthRaw ?? this.lengthRaw),
      dragType: dragType ?? this.dragType,
      useMultiBcG1: useMultiBcG1 ?? this.useMultiBcG1,
      useMultiBcG7: useMultiBcG7 ?? this.useMultiBcG7,
      bcG1: clearBcG1 ? null : (bcG1 ?? this.bcG1),
      bcG7: clearBcG7 ? null : (bcG7 ?? this.bcG7),
      multiBcG1Table: clearMultiBcG1Table
          ? null
          : (multiBcG1Table ?? this.multiBcG1Table),
      multiBcG7Table: clearMultiBcG7Table
          ? null
          : (multiBcG7Table ?? this.multiBcG7Table),
      customDragTable: clearCustomDragTable
          ? null
          : (customDragTable ?? this.customDragTable),
      powderSensTable: clearPowderSensTable
          ? null
          : (powderSensTable ?? this.powderSensTable),
      mvRaw: clearMv ? null : (mvRaw ?? this.mvRaw),
      mvTempRaw: mvTempRaw ?? this.mvTempRaw,
      zeroDistRaw: zeroDistRaw ?? this.zeroDistRaw,
      zeroLookAngleRaw: zeroLookAngleRaw ?? this.zeroLookAngleRaw,
      zeroTempRaw: zeroTempRaw ?? this.zeroTempRaw,
      zeroAltRaw: zeroAltRaw ?? this.zeroAltRaw,
      zeroPressureRaw: zeroPressureRaw ?? this.zeroPressureRaw,
      zeroHumidityRaw: zeroHumidityRaw ?? this.zeroHumidityRaw,
      usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
      powderSensRaw: powderSensRaw ?? this.powderSensRaw,
      zeroUseDiffPowderTemp:
          zeroUseDiffPowderTemp ?? this.zeroUseDiffPowderTemp,
      zeroPowderTempRaw: zeroPowderTempRaw ?? this.zeroPowderTempRaw,
      zeroUseCoriolis: zeroUseCoriolis ?? this.zeroUseCoriolis,
      zeroLatitudeRaw: zeroLatitudeRaw ?? this.zeroLatitudeRaw,
      zeroAzimuthRaw: zeroAzimuthRaw ?? this.zeroAzimuthRaw,
      offsetXRaw: offsetXRaw ?? this.offsetXRaw,
      offsetXUnit: offsetXUnit ?? this.offsetXUnit,
      offsetYRaw: offsetYRaw ?? this.offsetYRaw,
      offsetYUnit: offsetYUnit ?? this.offsetYUnit,
    );
  }
}
