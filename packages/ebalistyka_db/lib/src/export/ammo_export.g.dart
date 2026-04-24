// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ammo_export.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AmmoExport _$AmmoExportFromJson(Map<String, dynamic> json) => AmmoExport(
  name: json['name'] as String,
  caliberInch: (json['caliberInch'] as num).toDouble(),
  weightGrain: (json['weightGrain'] as num).toDouble(),
  lengthInch: (json['lengthInch'] as num).toDouble(),
  dragTypeValue: json['dragTypeValue'] as String,
  bcG1: (json['bcG1'] as num).toDouble(),
  bcG7: (json['bcG7'] as num).toDouble(),
  useMultiBcG1: json['useMultiBcG1'] as bool,
  useMultiBcG7: json['useMultiBcG7'] as bool,
  muzzleVelocityMps: (json['muzzleVelocityMps'] as num).toDouble(),
  muzzleVelocityTemperatureC: (json['muzzleVelocityTemperatureC'] as num)
      .toDouble(),
  usePowderSensitivity: json['usePowderSensitivity'] as bool,
  powderSensitivityFrac: (json['powderSensitivityFrac'] as num).toDouble(),
  zeroDistanceMeter: (json['zeroDistanceMeter'] as num).toDouble(),
  zeroLookAngleRad: (json['zeroLookAngleRad'] as num).toDouble(),
  zeroAltitudeMeter: (json['zeroAltitudeMeter'] as num).toDouble(),
  zeroTemperatureC: (json['zeroTemperatureC'] as num).toDouble(),
  zeroPressurehPa: (json['zeroPressurehPa'] as num).toDouble(),
  zeroHumidityFrac: (json['zeroHumidityFrac'] as num).toDouble(),
  zeroUseDiffPowderTemperature: json['zeroUseDiffPowderTemperature'] as bool,
  zeroUseCoriolis: json['zeroUseCoriolis'] as bool,
  zeroPowderTemperatureC: (json['zeroPowderTemperatureC'] as num).toDouble(),
  zeroLatitudeDeg: (json['zeroLatitudeDeg'] as num).toDouble(),
  zeroAzimuthDeg: (json['zeroAzimuthDeg'] as num).toDouble(),
  zeroOffsetX: (json['zeroOffsetX'] as num).toDouble(),
  zeroOffsetY: (json['zeroOffsetY'] as num).toDouble(),
  zeroOffsetXUnit: json['zeroOffsetXUnit'] as String,
  zeroOffsetYUnit: json['zeroOffsetYUnit'] as String,
  powderSensitivityTC: const Float64ListConverter().fromJson(
    json['powderSensitivityTC'] as List?,
  ),
  powderSensitivityVMps: const Float64ListConverter().fromJson(
    json['powderSensitivityVMps'] as List?,
  ),
  multiBcTableG1VMps: const Float64ListConverter().fromJson(
    json['multiBcTableG1VMps'] as List?,
  ),
  multiBcTableG1Bc: const Float64ListConverter().fromJson(
    json['multiBcTableG1Bc'] as List?,
  ),
  multiBcTableG7VMps: const Float64ListConverter().fromJson(
    json['multiBcTableG7VMps'] as List?,
  ),
  multiBcTableG7Bc: const Float64ListConverter().fromJson(
    json['multiBcTableG7Bc'] as List?,
  ),
  customDragTableMach: const Float64ListConverter().fromJson(
    json['customDragTableMach'] as List?,
  ),
  customDragTableCd: const Float64ListConverter().fromJson(
    json['customDragTableCd'] as List?,
  ),
  projectileName: json['projectileName'] as String?,
  vendor: json['vendor'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$AmmoExportToJson(AmmoExport instance) =>
    <String, dynamic>{
      'name': instance.name,
      'caliberInch': instance.caliberInch,
      'weightGrain': instance.weightGrain,
      'lengthInch': instance.lengthInch,
      'dragTypeValue': instance.dragTypeValue,
      'bcG1': instance.bcG1,
      'bcG7': instance.bcG7,
      'useMultiBcG1': instance.useMultiBcG1,
      'useMultiBcG7': instance.useMultiBcG7,
      'muzzleVelocityMps': instance.muzzleVelocityMps,
      'muzzleVelocityTemperatureC': instance.muzzleVelocityTemperatureC,
      'usePowderSensitivity': instance.usePowderSensitivity,
      'powderSensitivityFrac': instance.powderSensitivityFrac,
      'zeroDistanceMeter': instance.zeroDistanceMeter,
      'zeroLookAngleRad': instance.zeroLookAngleRad,
      'zeroAltitudeMeter': instance.zeroAltitudeMeter,
      'zeroTemperatureC': instance.zeroTemperatureC,
      'zeroPressurehPa': instance.zeroPressurehPa,
      'zeroHumidityFrac': instance.zeroHumidityFrac,
      'zeroUseDiffPowderTemperature': instance.zeroUseDiffPowderTemperature,
      'zeroUseCoriolis': instance.zeroUseCoriolis,
      'zeroPowderTemperatureC': instance.zeroPowderTemperatureC,
      'zeroLatitudeDeg': instance.zeroLatitudeDeg,
      'zeroAzimuthDeg': instance.zeroAzimuthDeg,
      'zeroOffsetX': instance.zeroOffsetX,
      'zeroOffsetY': instance.zeroOffsetY,
      'zeroOffsetXUnit': instance.zeroOffsetXUnit,
      'zeroOffsetYUnit': instance.zeroOffsetYUnit,
      'powderSensitivityTC': ?const Float64ListConverter().toJson(
        instance.powderSensitivityTC,
      ),
      'powderSensitivityVMps': ?const Float64ListConverter().toJson(
        instance.powderSensitivityVMps,
      ),
      'multiBcTableG1VMps': ?const Float64ListConverter().toJson(
        instance.multiBcTableG1VMps,
      ),
      'multiBcTableG1Bc': ?const Float64ListConverter().toJson(
        instance.multiBcTableG1Bc,
      ),
      'multiBcTableG7VMps': ?const Float64ListConverter().toJson(
        instance.multiBcTableG7VMps,
      ),
      'multiBcTableG7Bc': ?const Float64ListConverter().toJson(
        instance.multiBcTableG7Bc,
      ),
      'customDragTableMach': ?const Float64ListConverter().toJson(
        instance.customDragTableMach,
      ),
      'customDragTableCd': ?const Float64ListConverter().toJson(
        instance.customDragTableCd,
      ),
      'projectileName': ?instance.projectileName,
      'vendor': ?instance.vendor,
      'image': ?instance.image,
    };
