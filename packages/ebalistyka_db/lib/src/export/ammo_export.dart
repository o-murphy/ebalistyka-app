import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import '../entities.dart';
import 'float64list_converter.dart';

part 'ammo_export.g.dart';

@JsonSerializable(includeIfNull: false)
@Float64ListConverter()
class AmmoExport {
  const AmmoExport({
    required this.name,
    required this.caliberInch,
    required this.weightGrain,
    required this.lengthInch,
    required this.dragTypeValue,
    required this.bcG1,
    required this.bcG7,
    required this.useMultiBcG1,
    required this.useMultiBcG7,
    required this.muzzleVelocityMps,
    required this.muzzleVelocityTemperatureC,
    required this.usePowderSensitivity,
    required this.powderSensitivityFrac,
    required this.zeroDistanceMeter,
    required this.zeroLookAngleRad,
    required this.zeroAltitudeMeter,
    required this.zeroTemperatureC,
    required this.zeroPressurehPa,
    required this.zeroHumidityFrac,
    required this.zeroUseDiffPowderTemperature,
    required this.zeroUseCoriolis,
    required this.zeroPowderTemperatureC,
    required this.zeroLatitudeDeg,
    required this.zeroAzimuthDeg,
    required this.zeroOffsetXRad,
    required this.zeroOffsetYRad,
    this.powderSensitivityTC,
    this.powderSensitivityVMps,
    this.multiBcTableG1VMps,
    this.multiBcTableG1Bc,
    this.multiBcTableG7VMps,
    this.multiBcTableG7Bc,
    this.customDragTableMach,
    this.customDragTableCd,
    this.projectileName,
    this.vendor,
    this.image,
  });

  final String name;
  final double caliberInch;
  final double weightGrain;
  final double lengthInch;
  final String dragTypeValue;
  final double bcG1;
  final double bcG7;
  final bool useMultiBcG1;
  final bool useMultiBcG7;
  final double muzzleVelocityMps;
  final double muzzleVelocityTemperatureC;
  final bool usePowderSensitivity;
  final double powderSensitivityFrac;
  final double zeroDistanceMeter;
  final double zeroLookAngleRad;
  final double zeroAltitudeMeter;
  final double zeroTemperatureC;
  final double zeroPressurehPa;
  final double zeroHumidityFrac;
  final bool zeroUseDiffPowderTemperature;
  final bool zeroUseCoriolis;
  final double zeroPowderTemperatureC;
  final double zeroLatitudeDeg;
  final double zeroAzimuthDeg;
  final double zeroOffsetXRad;
  final double zeroOffsetYRad;
  final Float64List? powderSensitivityTC;
  final Float64List? powderSensitivityVMps;
  final Float64List? multiBcTableG1VMps;
  final Float64List? multiBcTableG1Bc;
  final Float64List? multiBcTableG7VMps;
  final Float64List? multiBcTableG7Bc;
  final Float64List? customDragTableMach;
  final Float64List? customDragTableCd;
  final String? projectileName;
  final String? vendor;
  final String? image;

  factory AmmoExport.fromJson(Map<String, dynamic> json) =>
      _$AmmoExportFromJson(json);

  Map<String, dynamic> toJson() => _$AmmoExportToJson(this);

  factory AmmoExport.fromEntity(Ammo a) => AmmoExport(
    name: a.name,
    caliberInch: a.caliberInch,
    weightGrain: a.weightGrain,
    lengthInch: a.lengthInch,
    dragTypeValue: a.dragTypeValue,
    bcG1: a.bcG1,
    bcG7: a.bcG7,
    useMultiBcG1: a.useMultiBcG1,
    useMultiBcG7: a.useMultiBcG7,
    muzzleVelocityMps: a.muzzleVelocityMps,
    muzzleVelocityTemperatureC: a.muzzleVelocityTemperatureC,
    usePowderSensitivity: a.usePowderSensitivity,
    powderSensitivityFrac: a.powderSensitivityFrac,
    zeroDistanceMeter: a.zeroDistanceMeter,
    zeroLookAngleRad: a.zeroLookAngleRad,
    zeroAltitudeMeter: a.zeroAltitudeMeter,
    zeroTemperatureC: a.zeroTemperatureC,
    zeroPressurehPa: a.zeroPressurehPa,
    zeroHumidityFrac: a.zeroHumidityFrac,
    zeroUseDiffPowderTemperature: a.zeroUseDiffPowderTemperature,
    zeroUseCoriolis: a.zeroUseCoriolis,
    zeroPowderTemperatureC: a.zeroPowderTemperatureC,
    zeroLatitudeDeg: a.zeroLatitudeDeg,
    zeroAzimuthDeg: a.zeroAzimuthDeg,
    zeroOffsetXRad: a.zeroOffsetXRad,
    zeroOffsetYRad: a.zeroOffsetYRad,
    powderSensitivityTC: a.powderSensitivityTC,
    powderSensitivityVMps: a.powderSensitivityVMps,
    multiBcTableG1VMps: a.multiBcTableG1VMps,
    multiBcTableG1Bc: a.multiBcTableG1Bc,
    multiBcTableG7VMps: a.multiBcTableG7VMps,
    multiBcTableG7Bc: a.multiBcTableG7Bc,
    customDragTableMach: a.customDragTableMach,
    customDragTableCd: a.customDragTableCd,
    projectileName: a.projectileName,
    vendor: a.vendor,
    image: a.image,
  );

  Ammo toEntity() => Ammo()
    ..name = name
    ..caliberInch = caliberInch
    ..weightGrain = weightGrain
    ..lengthInch = lengthInch
    ..dragTypeValue = dragTypeValue
    ..bcG1 = bcG1
    ..bcG7 = bcG7
    ..useMultiBcG1 = useMultiBcG1
    ..useMultiBcG7 = useMultiBcG7
    ..muzzleVelocityMps = muzzleVelocityMps
    ..muzzleVelocityTemperatureC = muzzleVelocityTemperatureC
    ..usePowderSensitivity = usePowderSensitivity
    ..powderSensitivityFrac = powderSensitivityFrac
    ..zeroDistanceMeter = zeroDistanceMeter
    ..zeroLookAngleRad = zeroLookAngleRad
    ..zeroAltitudeMeter = zeroAltitudeMeter
    ..zeroTemperatureC = zeroTemperatureC
    ..zeroPressurehPa = zeroPressurehPa
    ..zeroHumidityFrac = zeroHumidityFrac
    ..zeroUseDiffPowderTemperature = zeroUseDiffPowderTemperature
    ..zeroUseCoriolis = zeroUseCoriolis
    ..zeroPowderTemperatureC = zeroPowderTemperatureC
    ..zeroLatitudeDeg = zeroLatitudeDeg
    ..zeroAzimuthDeg = zeroAzimuthDeg
    ..zeroOffsetXRad = zeroOffsetXRad
    ..zeroOffsetYRad = zeroOffsetYRad
    ..powderSensitivityTC = powderSensitivityTC
    ..powderSensitivityVMps = powderSensitivityVMps
    ..multiBcTableG1VMps = multiBcTableG1VMps
    ..multiBcTableG1Bc = multiBcTableG1Bc
    ..multiBcTableG7VMps = multiBcTableG7VMps
    ..multiBcTableG7Bc = multiBcTableG7Bc
    ..customDragTableMach = customDragTableMach
    ..customDragTableCd = customDragTableCd
    ..projectileName = projectileName
    ..vendor = vendor
    ..image = image;
}
