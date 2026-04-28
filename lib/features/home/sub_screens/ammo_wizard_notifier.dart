import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_parsers.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AmmoWizardState {
  const AmmoWizardState({
    this.name = '',
    this.vendor = '',
    this.projectileName = '',
    required this.caliberRaw,
    this.weightRaw,
    this.lengthRaw,
    this.dragType = DragType.g1,
    this.useMultiBcG1 = false,
    this.useMultiBcG7 = false,
    this.bcG1,
    this.bcG7,
    this.multiBcG1Table,
    this.multiBcG7Table,
    this.customDragTable,
    this.powderSensTable,
    this.mvRaw,
    this.mvTempRaw = 15.0,
    this.zeroDistRaw = 100.0,
    this.zeroLookAngleRaw = 0.0,
    this.zeroTempRaw = 15.0,
    this.zeroAltRaw = 0.0,
    this.zeroPressureRaw = 1013.0,
    this.zeroHumidityRaw = 0.0,
    this.usePowderSensitivity = false,
    this.powderSensRaw = 0.0,
    this.zeroUseDiffPowderTemp = false,
    this.zeroPowderTempRaw = 15.0,
    this.zeroUseCoriolis = false,
    this.zeroLatitudeRaw = 0.0,
    this.zeroAzimuthRaw = 0.0,
    this.offsetXRaw = 0.1,
    this.offsetXUnit = Unit.mil,
    this.offsetYRaw = 0.1,
    this.offsetYUnit = Unit.mil,
    this.initial,
  });

  final String name;
  final String vendor;
  final String projectileName;
  final double caliberRaw; // FC.projectileDiameter.rawUnit = mm
  final double? weightRaw; // FC.projectileWeight.rawUnit = grain
  final double? lengthRaw; // FC.projectileLength.rawUnit = mm
  final DragType dragType;
  final bool useMultiBcG1;
  final bool useMultiBcG7;
  final double? bcG1;
  final double? bcG7;
  final List<({double vMps, double bc})>? multiBcG1Table;
  final List<({double vMps, double bc})>? multiBcG7Table;
  final List<({double mach, double cd})>? customDragTable;
  final List<({double tempC, double vMps})>? powderSensTable;
  final double? mvRaw; // FC.muzzleVelocity.rawUnit = mps
  final double mvTempRaw; // celsius
  final double zeroDistRaw; // meters
  final double zeroLookAngleRaw; // degrees
  final double zeroTempRaw; // celsius
  final double zeroAltRaw; // meters
  final double zeroPressureRaw; // hPa
  final double zeroHumidityRaw; // fraction
  final bool usePowderSensitivity;
  final double powderSensRaw; // fraction
  final bool zeroUseDiffPowderTemp;
  final double zeroPowderTempRaw; // celsius
  final bool zeroUseCoriolis;
  final double zeroLatitudeRaw; // degrees
  final double zeroAzimuthRaw; // degrees
  final double offsetXRaw; // FC.adjustment.rawUnit = mil
  final Unit offsetXUnit;
  final double offsetYRaw; // mil
  final Unit offsetYUnit;
  final Ammo?
  initial; // non-null in edit mode; buildAmmo() mutates and returns it

  // ── Factory ────────────────────────────────────────────────────────────────

  factory AmmoWizardState.fromAmmo(Ammo? a, double? caliberInch) {
    final defaultCaliberRaw = Distance.inch(
      caliberInch ?? FC.projectileDiameter.minRaw,
    ).in_(FC.projectileDiameter.rawUnit);

    if (a == null) {
      return AmmoWizardState(caliberRaw: defaultCaliberRaw);
    }

    final caliberMm = a.caliber.in_(FC.projectileDiameter.rawUnit);
    final weightGrain = a.weight.in_(FC.projectileWeight.rawUnit);
    final lengthMm = a.length.in_(FC.projectileLength.rawUnit);

    return AmmoWizardState(
      name: a.name,
      vendor: a.vendor ?? '',
      projectileName: a.projectileName ?? '',
      caliberRaw: caliberMm > 0 ? caliberMm : defaultCaliberRaw,
      weightRaw: weightGrain > 0 ? weightGrain : null,
      lengthRaw: lengthMm > 0 ? lengthMm : null,
      dragType: a.dragType,
      useMultiBcG1: a.useMultiBcG1,
      useMultiBcG7: a.useMultiBcG7,
      bcG1: a.bcG1 > 0 ? a.bcG1 : null,
      bcG7: a.bcG7 > 0 ? a.bcG7 : null,
      multiBcG1Table: decodeBcTable(a.multiBcTableG1VMps, a.multiBcTableG1Bc),
      multiBcG7Table: decodeBcTable(a.multiBcTableG7VMps, a.multiBcTableG7Bc),
      customDragTable: decodeCustomDragTable(
        a.customDragTableMach,
        a.customDragTableCd,
      ),
      powderSensTable: decodePowderSensTable(
        a.powderSensitivityTC,
        a.powderSensitivityVMps,
      ),
      mvRaw: a.mv?.in_(FC.muzzleVelocity.rawUnit),
      mvTempRaw: a.mvTemperature.in_(FC.temperature.rawUnit),
      zeroDistRaw: a.zeroDistance.in_(FC.zeroDistance.rawUnit),
      zeroLookAngleRaw: a.zeroLookAngle.in_(FC.lookAngle.rawUnit),
      zeroTempRaw: a.zeroTemperature.in_(FC.temperature.rawUnit),
      zeroAltRaw: a.zeroAltitude.in_(FC.altitude.rawUnit),
      zeroPressureRaw: a.zeroPressure.in_(FC.pressure.rawUnit),
      zeroHumidityRaw: a.zeroHumidityFrac,
      usePowderSensitivity: a.usePowderSensitivity,
      powderSensRaw: a.powderSensitivityFrac,
      zeroUseDiffPowderTemp: a.zeroUseDiffPowderTemperature,
      zeroPowderTempRaw: a.zeroPowderTemp.in_(FC.temperature.rawUnit),
      zeroUseCoriolis: a.zeroUseCoriolis,
      zeroLatitudeRaw: a.zeroLatitude.in_(Unit.degree),
      zeroAzimuthRaw: a.zeroAzimuth.in_(Unit.degree),
      offsetXRaw: Angular(
        a.zeroOffsetX,
        a.zeroOffsetXUnitValue,
      ).in_(FC.adjustment.rawUnit),
      offsetXUnit: a.zeroOffsetXUnitValue,
      offsetYRaw: Angular(
        a.zeroOffsetY,
        a.zeroOffsetYUnitValue,
      ).in_(FC.adjustment.rawUnit),
      offsetYUnit: a.zeroOffsetYUnitValue,
      initial: a,
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

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

  // ── Build entity ───────────────────────────────────────────────────────────

  Ammo buildAmmo() {
    final ammo = initial ?? Ammo();
    ammo.name = name.trim();
    ammo.vendor = vendor.trim().isEmpty ? null : vendor.trim();
    ammo.projectileName = projectileName.trim().isEmpty
        ? null
        : projectileName.trim();
    ammo.caliber = Distance(caliberRaw, FC.projectileDiameter.rawUnit);
    if (weightRaw != null) {
      ammo.weight = Weight(weightRaw!, FC.projectileWeight.rawUnit);
    } else {
      ammo.weightGrain = -1.0;
    }
    if (lengthRaw != null) {
      ammo.length = Distance(lengthRaw!, FC.projectileLength.rawUnit);
    } else {
      ammo.lengthInch = -1.0;
    }
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

    if (mvRaw != null) {
      ammo.mv = Velocity(mvRaw!, FC.muzzleVelocity.rawUnit);
    } else {
      ammo.muzzleVelocityMps = -1.0;
    }
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

  // ── copyWith ───────────────────────────────────────────────────────────────

  static const _absent = Object();

  AmmoWizardState copyWith({
    String? name,
    String? vendor,
    String? projectileName,
    double? caliberRaw,
    Object? weightRaw = _absent,
    Object? lengthRaw = _absent,
    DragType? dragType,
    bool? useMultiBcG1,
    bool? useMultiBcG7,
    Object? bcG1 = _absent,
    Object? bcG7 = _absent,
    Object? multiBcG1Table = _absent,
    Object? multiBcG7Table = _absent,
    Object? customDragTable = _absent,
    Object? powderSensTable = _absent,
    Object? mvRaw = _absent,
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
  }) => AmmoWizardState(
    name: name ?? this.name,
    vendor: vendor ?? this.vendor,
    projectileName: projectileName ?? this.projectileName,
    caliberRaw: caliberRaw ?? this.caliberRaw,
    weightRaw: weightRaw == _absent ? this.weightRaw : weightRaw as double?,
    lengthRaw: lengthRaw == _absent ? this.lengthRaw : lengthRaw as double?,
    dragType: dragType ?? this.dragType,
    useMultiBcG1: useMultiBcG1 ?? this.useMultiBcG1,
    useMultiBcG7: useMultiBcG7 ?? this.useMultiBcG7,
    bcG1: bcG1 == _absent ? this.bcG1 : bcG1 as double?,
    bcG7: bcG7 == _absent ? this.bcG7 : bcG7 as double?,
    multiBcG1Table: multiBcG1Table == _absent
        ? this.multiBcG1Table
        : multiBcG1Table as List<({double vMps, double bc})>?,
    multiBcG7Table: multiBcG7Table == _absent
        ? this.multiBcG7Table
        : multiBcG7Table as List<({double vMps, double bc})>?,
    customDragTable: customDragTable == _absent
        ? this.customDragTable
        : customDragTable as List<({double mach, double cd})>?,
    powderSensTable: powderSensTable == _absent
        ? this.powderSensTable
        : powderSensTable as List<({double tempC, double vMps})>?,
    mvRaw: mvRaw == _absent ? this.mvRaw : mvRaw as double?,
    mvTempRaw: mvTempRaw ?? this.mvTempRaw,
    zeroDistRaw: zeroDistRaw ?? this.zeroDistRaw,
    zeroLookAngleRaw: zeroLookAngleRaw ?? this.zeroLookAngleRaw,
    zeroTempRaw: zeroTempRaw ?? this.zeroTempRaw,
    zeroAltRaw: zeroAltRaw ?? this.zeroAltRaw,
    zeroPressureRaw: zeroPressureRaw ?? this.zeroPressureRaw,
    zeroHumidityRaw: zeroHumidityRaw ?? this.zeroHumidityRaw,
    usePowderSensitivity: usePowderSensitivity ?? this.usePowderSensitivity,
    powderSensRaw: powderSensRaw ?? this.powderSensRaw,
    zeroUseDiffPowderTemp: zeroUseDiffPowderTemp ?? this.zeroUseDiffPowderTemp,
    zeroPowderTempRaw: zeroPowderTempRaw ?? this.zeroPowderTempRaw,
    zeroUseCoriolis: zeroUseCoriolis ?? this.zeroUseCoriolis,
    zeroLatitudeRaw: zeroLatitudeRaw ?? this.zeroLatitudeRaw,
    zeroAzimuthRaw: zeroAzimuthRaw ?? this.zeroAzimuthRaw,
    offsetXRaw: offsetXRaw ?? this.offsetXRaw,
    offsetXUnit: offsetXUnit ?? this.offsetXUnit,
    offsetYRaw: offsetYRaw ?? this.offsetYRaw,
    offsetYUnit: offsetYUnit ?? this.offsetYUnit,
    initial: initial,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

typedef AmmoWizardArg = ({Ammo? initial, double? caliberInch});

final ammoWizardProvider =
    NotifierProvider.family<AmmoWizardNotifier, AmmoWizardState, AmmoWizardArg>(
      (arg) => AmmoWizardNotifier(arg),
    );

class AmmoWizardNotifier extends Notifier<AmmoWizardState> {
  AmmoWizardNotifier(this._arg);
  final AmmoWizardArg _arg;

  @override
  AmmoWizardState build() =>
      AmmoWizardState.fromAmmo(_arg.initial, _arg.caliberInch);

  void updateName(String v) => state = state.copyWith(name: v);
  void updateVendor(String v) => state = state.copyWith(vendor: v);
  void updateProjectileName(String v) =>
      state = state.copyWith(projectileName: v);
  void updateCaliberRaw(double v) => state = state.copyWith(caliberRaw: v);
  void updateWeightRaw(double? v) => state = state.copyWith(weightRaw: v);
  void updateLengthRaw(double? v) => state = state.copyWith(lengthRaw: v);
  void updateDragType(DragType v) => state = state.copyWith(dragType: v);
  void updateUseMultiBcG1(bool v) => state = state.copyWith(useMultiBcG1: v);
  void updateUseMultiBcG7(bool v) => state = state.copyWith(useMultiBcG7: v);
  void updateBcG1(double? v) => state = state.copyWith(bcG1: v);
  void updateBcG7(double? v) => state = state.copyWith(bcG7: v);
  void updateMultiBcG1Table(List<({double vMps, double bc})>? v) =>
      state = state.copyWith(multiBcG1Table: v);
  void updateMultiBcG7Table(List<({double vMps, double bc})>? v) =>
      state = state.copyWith(multiBcG7Table: v);
  void updateCustomDragTable(List<({double mach, double cd})>? v) =>
      state = state.copyWith(customDragTable: v);
  void updatePowderSensTable(
    List<({double tempC, double vMps})>? v, {
    double? sensitivityFrac,
  }) => state = state.copyWith(
    powderSensTable: v,
    powderSensRaw: sensitivityFrac ?? state.powderSensRaw,
  );
  void updateMvRaw(double? v) => state = state.copyWith(mvRaw: v);
  void updateMvTempRaw(double v) => state = state.copyWith(mvTempRaw: v);
  void updateZeroDistRaw(double v) => state = state.copyWith(zeroDistRaw: v);
  void updateZeroLookAngleRaw(double v) =>
      state = state.copyWith(zeroLookAngleRaw: v);
  void updateZeroTempRaw(double v) => state = state.copyWith(zeroTempRaw: v);
  void updateZeroAltRaw(double v) => state = state.copyWith(zeroAltRaw: v);
  void updateZeroPressureRaw(double v) =>
      state = state.copyWith(zeroPressureRaw: v);
  void updateZeroHumidityRaw(double v) =>
      state = state.copyWith(zeroHumidityRaw: v);
  void updateUsePowderSensitivity(bool v) =>
      state = state.copyWith(usePowderSensitivity: v);
  void updatePowderSensRaw(double v) =>
      state = state.copyWith(powderSensRaw: v);
  void updateZeroUseDiffPowderTemp(bool v) =>
      state = state.copyWith(zeroUseDiffPowderTemp: v);
  void updateZeroPowderTempRaw(double v) =>
      state = state.copyWith(zeroPowderTempRaw: v);
  void updateZeroUseCoriolis(bool v) =>
      state = state.copyWith(zeroUseCoriolis: v);
  void updateZeroLatitudeRaw(double v) =>
      state = state.copyWith(zeroLatitudeRaw: v);
  void updateZeroAzimuthRaw(double v) =>
      state = state.copyWith(zeroAzimuthRaw: v);
  void updateOffsetXRaw(double v) => state = state.copyWith(offsetXRaw: v);
  void updateOffsetXUnit(Unit v) => state = state.copyWith(offsetXUnit: v);
  void updateOffsetYRaw(double v) => state = state.copyWith(offsetYRaw: v);
  void updateOffsetYUnit(Unit v) => state = state.copyWith(offsetYUnit: v);
}
