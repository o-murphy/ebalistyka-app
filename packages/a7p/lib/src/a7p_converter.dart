import 'dart:typed_data';

import 'package:ebalistyka_db/ebalistyka_db.dart';

import 'a7p_validator.dart';
import 'proto/profedit.pb.dart' as proto;

// ── Multipliers from the a7p specification ────────────────────────────────────
// sc_height   : mm   × 1
// r_twist     : inch × 100
// c_muzzle_velocity : mps  × 10
// c_t_coeff   : %/15°C × 1000
// c_zero_air_pressure : hPa × 10
// c_zero_air_humidity : % × 1   (0–100)
// b_diameter  : inch × 1000
// b_weight    : grain × 10
// b_length    : inch × 1000
// distances   : m × 100
// coef_rows.bc_cd (G1/G7) : bc × 10000
// coef_rows.mv    (G1/G7) : mps × 10
// coef_rows.bc_cd (CUSTOM): Cd × 10000
// coef_rows.mv    (CUSTOM): mach × 10000

const _kInchToMm = 25.4;

abstract final class A7pConverter {
  // ── proto → ProfileExport (import) ───────────────────────────────────────────

  static ProfileExport fromPayload(
    proto.Payload payload, {
    bool validate = true,
  }) {
    if (validate) A7pValidator.validate(payload);
    return _fromProfile(payload.profile);
  }

  static ProfileExport _fromProfile(proto.Profile p) {
    final weapon = WeaponExport(
      name: p.profileName,
      caliberInch: p.bDiameter / 1000.0,
      caliberName: p.caliber,
      twistInch:
          (p.twistDir == proto.TwistDir.LEFT ? -1.0 : 1.0) * (p.rTwist / 100.0),
      barrelLengthInch: 0.0,
      zeroElevationRad: 0.0,
    );

    final ammo = _ammoFromProfile(p);
    final sight = _sightFromProfile(p);

    return ProfileExport(
      name: p.profileName,
      weapon: weapon,
      ammo: ammo,
      sight: sight,
    );
  }

  static AmmoExport _ammoFromProfile(proto.Profile p) {
    final zeroMeter = p.distances.isNotEmpty
        ? p.distances[p.cZeroDistanceIdx.clamp(0, p.distances.length - 1)] /
              100.0
        : 100.0;

    bool useMultiG1 = false;
    bool useMultiG7 = false;
    double bcG1 = 0.0;
    double bcG7 = 0.0;
    Float64List? multiG1VMps;
    Float64List? multiG1Bc;
    Float64List? multiG7VMps;
    Float64List? multiG7Bc;
    Float64List? customMach;
    Float64List? customCd;
    String dragType = 'g1';

    switch (p.bcType) {
      case proto.GType.G1:
        dragType = 'g1';
        if (p.coefRows.isNotEmpty) {
          bcG1 = p.coefRows.first.bcCd / 10000.0;
          if (p.coefRows.length > 1) {
            useMultiG1 = true;
            multiG1VMps = Float64List.fromList(
              p.coefRows.map((r) => r.mv / 10.0).toList(),
            );
            multiG1Bc = Float64List.fromList(
              p.coefRows.map((r) => r.bcCd / 10000.0).toList(),
            );
          }
        }
      case proto.GType.G7:
        dragType = 'g7';
        if (p.coefRows.isNotEmpty) {
          bcG7 = p.coefRows.first.bcCd / 10000.0;
          if (p.coefRows.length > 1) {
            useMultiG7 = true;
            multiG7VMps = Float64List.fromList(
              p.coefRows.map((r) => r.mv / 10.0).toList(),
            );
            multiG7Bc = Float64List.fromList(
              p.coefRows.map((r) => r.bcCd / 10000.0).toList(),
            );
          }
        }
      case proto.GType.CUSTOM:
        dragType = 'custom';
        final sorted = List.of(p.coefRows)
          ..sort((a, b) => a.mv.compareTo(b.mv));
        customMach = Float64List.fromList(
          sorted.map((r) => r.mv / 10000.0).toList(),
        );
        customCd = Float64List.fromList(
          sorted.map((r) => r.bcCd / 10000.0).toList(),
        );
      default:
        dragType = 'g1';
    }

    return AmmoExport(
      name: p.cartridgeName,
      projectileName: p.bulletName,
      caliberInch: p.bDiameter / 1000.0,
      weightGrain: p.bWeight / 10.0,
      lengthInch: p.bLength / 1000.0,
      dragTypeValue: dragType,
      bcG1: bcG1,
      bcG7: bcG7,
      useMultiBcG1: useMultiG1,
      useMultiBcG7: useMultiG7,
      multiBcTableG1VMps: multiG1VMps,
      multiBcTableG1Bc: multiG1Bc,
      multiBcTableG7VMps: multiG7VMps,
      multiBcTableG7Bc: multiG7Bc,
      customDragTableMach: customMach,
      customDragTableCd: customCd,
      muzzleVelocityMps: p.cMuzzleVelocity / 10.0,
      muzzleVelocityTemperatureC: p.cZeroTemperature.toDouble(),
      usePowderSensitivity: p.cTCoeff != 0,
      powderSensitivityFrac: p.cTCoeff / 1000.0,
      zeroDistanceMeter: zeroMeter,
      zeroLookAngleRad: 0.0,
      zeroAltitudeMeter: 0.0,
      zeroTemperatureC: p.cZeroAirTemperature.toDouble(),
      zeroPressurehPa: p.cZeroAirPressure / 10.0,
      zeroHumidityFrac: p.cZeroAirHumidity / 100.0,
      zeroUseDiffPowderTemperature:
          p.cZeroPTemperature != p.cZeroAirTemperature,
      zeroUseCoriolis: false,
      zeroPowderTemperatureC: p.cZeroPTemperature.toDouble(),
      zeroLatitudeDeg: 0.0,
      zeroAzimuthDeg: 0.0,
      zeroOffsetXRad: 0.0,
      zeroOffsetYRad: 0.0,
    );
  }

  static SightExport _sightFromProfile(proto.Profile p) => SightExport(
    name: p.profileName,
    focalPlaneValue: 'ffp',
    sightHeightInch: p.scHeight / _kInchToMm,
    sightHorizontalOffsetInch: 0.0,
    verticalClick: 0.1,
    horizontalClick: 0.1,
    verticalClickUnit: 'mil',
    horizontalClickUnit: 'mil',
    minMagnification: 0.0,
    maxMagnification: 0.0,
    calibratedMagnification: 0.0,
  );

  // ── ProfileExport → proto (export) ────────────────────────────────────────────

  static proto.Payload toPayload(ProfileExport export) {
    final ammo = export.ammo;
    final sight = export.sight;
    final weapon = export.weapon;

    final profileName = export.name.substring(
      0,
      export.name.length.clamp(0, 50),
    );
    final shortTop = profileName.substring(0, profileName.length.clamp(0, 8));
    final shortBot = profileName.length > 8
        ? profileName.substring(8, profileName.length.clamp(8, 16))
        : '';

    final scHeight = ((sight?.sightHeightInch ?? 0.0) * _kInchToMm).round();
    final rTwist = (weapon.twistInch.abs() * 100).round().clamp(0, 10000);
    final twistDir = weapon.twistInch < 0
        ? proto.TwistDir.LEFT
        : proto.TwistDir.RIGHT;

    final mv = ((ammo?.muzzleVelocityMps ?? 300.0) * 10).round().clamp(
      10,
      30000,
    );
    final zeroTemp = (ammo?.muzzleVelocityTemperatureC ?? 15.0).round().clamp(
      -100,
      100,
    );
    final tCoeff = ((ammo?.powderSensitivityFrac ?? 0.0) * 1000).round().clamp(
      0,
      5000,
    );
    final bDiameter = ((ammo?.caliberInch ?? weapon.caliberInch) * 1000)
        .round()
        .clamp(1, 50000);
    final bWeight = ((ammo?.weightGrain ?? 100.0) * 10).round().clamp(
      10,
      65535,
    );
    final bLength = ((ammo?.lengthInch ?? 0.1) * 1000).round().clamp(1, 200000);

    final zeroDist = ((ammo?.zeroDistanceMeter ?? 100.0) * 100).round().clamp(
      100,
      300000,
    );
    final zeroAirTemp = (ammo?.zeroTemperatureC ?? 15.0).round().clamp(
      -100,
      100,
    );
    final zeroAirPres = ((ammo?.zeroPressurehPa ?? 1013.25) * 10).round().clamp(
      3000,
      15000,
    );
    final zeroHumidity = ((ammo?.zeroHumidityFrac ?? 0.5) * 100).round().clamp(
      0,
      100,
    );
    final zeroPowderTemp = (ammo?.zeroPowderTemperatureC ?? 15.0).round().clamp(
      -100,
      100,
    );

    final coefRows = _buildCoefRows(ammo);
    final bcType = _bcType(ammo?.dragTypeValue ?? 'g1');

    final profile = proto.Profile()
      ..profileName = profileName
      ..cartridgeName = (ammo?.name ?? export.name).substring(
        0,
        (ammo?.name ?? export.name).length.clamp(0, 50),
      )
      ..bulletName = (ammo?.projectileName ?? ammo?.name ?? export.name)
          .substring(
            0,
            (ammo?.projectileName ?? ammo?.name ?? export.name).length.clamp(
              0,
              50,
            ),
          )
      ..shortNameTop = shortTop
      ..shortNameBot = shortBot
      ..caliber = weapon.caliberName.substring(
        0,
        weapon.caliberName.length.clamp(0, 50),
      )
      ..scHeight = scHeight.clamp(-5000, 5000)
      ..rTwist = rTwist
      ..twistDir = twistDir
      ..cMuzzleVelocity = mv
      ..cZeroTemperature = zeroTemp
      ..cTCoeff = tCoeff
      ..bDiameter = bDiameter
      ..bWeight = bWeight
      ..bLength = bLength
      ..bcType = bcType
      ..cZeroDistanceIdx = 0
      ..cZeroAirTemperature = zeroAirTemp
      ..cZeroAirPressure = zeroAirPres
      ..cZeroAirHumidity = zeroHumidity
      ..cZeroWPitch = 0
      ..cZeroPTemperature = zeroPowderTemp
      ..zeroX = 0
      ..zeroY = 0
      ..distances.add(zeroDist)
      ..coefRows.addAll(coefRows)
      ..switches.addAll(_defaultSwitches());

    return proto.Payload()..profile = profile;
  }

  static List<proto.CoefRow> _buildCoefRows(AmmoExport? ammo) {
    if (ammo == null)
      return [
        proto.CoefRow()
          ..bcCd = 0
          ..mv = 0,
      ];
    switch (ammo.dragTypeValue) {
      case 'g7':
        if (ammo.useMultiBcG7 &&
            ammo.multiBcTableG7VMps != null &&
            ammo.multiBcTableG7Bc != null) {
          return List.generate(
            ammo.multiBcTableG7VMps!.length,
            (i) => proto.CoefRow()
              ..mv = (ammo.multiBcTableG7VMps![i] * 10).round()
              ..bcCd = (ammo.multiBcTableG7Bc![i] * 10000).round(),
          );
        }
        return [
          proto.CoefRow()
            ..mv = 0
            ..bcCd = (ammo.bcG7 * 10000).round(),
        ];
      case 'custom':
        if (ammo.customDragTableMach != null &&
            ammo.customDragTableCd != null) {
          final rows = List.generate(
            ammo.customDragTableMach!.length,
            (i) => proto.CoefRow()
              ..mv = (ammo.customDragTableMach![i] * 10000).round()
              ..bcCd = (ammo.customDragTableCd![i] * 10000).round(),
          );
          rows.sort((a, b) => a.mv.compareTo(b.mv));
          return rows;
        }
        return [
          proto.CoefRow()
            ..mv = 0
            ..bcCd = 0,
        ];
      default: // g1
        if (ammo.useMultiBcG1 &&
            ammo.multiBcTableG1VMps != null &&
            ammo.multiBcTableG1Bc != null) {
          return List.generate(
            ammo.multiBcTableG1VMps!.length,
            (i) => proto.CoefRow()
              ..mv = (ammo.multiBcTableG1VMps![i] * 10).round()
              ..bcCd = (ammo.multiBcTableG1Bc![i] * 10000).round(),
          );
        }
        return [
          proto.CoefRow()
            ..mv = 0
            ..bcCd = (ammo.bcG1 * 10000).round(),
        ];
    }
  }

  static List<proto.SwPos> _defaultSwitches() => List.generate(
    4,
    (_) => proto.SwPos()
      ..cIdx = 0
      ..distanceFrom = proto.DType.INDEX
      ..distance = 0
      ..reticleIdx = 0
      ..zoom = 1,
  );

  static proto.GType _bcType(String dt) => switch (dt) {
    'g7' => proto.GType.G7,
    'custom' => proto.GType.CUSTOM,
    _ => proto.GType.G1,
  };
}
