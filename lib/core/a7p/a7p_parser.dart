import 'dart:typed_data';

import 'package:ebalistyka_db/ebalistyka_db.dart';
import '../proto/profedit.pb.dart' as proto;
import 'a7p_validator.dart';

/// Converts a validated [proto.Payload] into a [Profile] (ObjectBox entity).
///
/// Call [A7pValidator.validate] before this if you want explicit error
/// reporting; [fromPayload] will throw [A7pValidationException] on its own
/// by default (pass [validate] = false to skip).
class A7pParser {
  static Profile fromPayload(proto.Payload payload, {bool validate = true}) {
    if (validate) A7pValidator.validate(payload);
    return _parseProfile(payload.profile);
  }

  // ── main ───────────────────────────────────────────────────────────────────

  static Profile _parseProfile(proto.Profile p) {
    final weapon = Weapon()
      ..name = p.profileName
      ..twistInch = p.rTwist / 100.0;

    final sight = Sight()
      ..name = p.profileName
      ..sightHeightInch = p.scHeight / 25.4; // mm → inch

    final ammo = Ammo()
      ..name = p.cartridgeName
      ..projectileName = p.bulletName
      ..dragTypeValue = _dragTypeStr(p.bcType)
      ..weightGrain = p.bWeight / 10.0
      ..caliberInch = p.bDiameter / 1000.0
      ..lengthInch = p.bLength / 1000.0
      ..muzzleVelocityMps = p.cMuzzleVelocity / 10.0
      ..muzzleVelocityTemperatureC = p.cZeroTemperature.toDouble()
      ..powderTemperatureC = p.cZeroPTemperature.toDouble()
      ..powderSensitivityFrac = p.cTCoeff / 1000.0
      ..usePowderSensitivity = p.cTCoeff != 0
      ..zeroDistanceMeter = _zeroDistanceMeter(p)
      ..zeroTemperatureC = p.cZeroAirTemperature.toDouble()
      ..zeroPressurehPa = p.cZeroAirPressure / 10.0
      ..zeroHumidityFrac = p.cZeroAirHumidity / 100.0
      ..zeroPowderTemperatureC = p.cZeroPTemperature.toDouble()
      ..zeroUseDiffPowderTemperature =
          p.cZeroPTemperature != p.cZeroAirTemperature;

    _applyBc(ammo, p);

    final profile = Profile()..name = p.profileName;
    profile.weapon.target = weapon;
    profile.sight.target = sight;
    profile.ammo.target = ammo;
    return profile;
  }

  // ── BC / drag model ────────────────────────────────────────────────────────

  static void _applyBc(Ammo ammo, proto.Profile p) {
    switch (p.bcType) {
      case proto.GType.G7:
        if (p.coefRows.isNotEmpty) {
          ammo.bcG7 = p.coefRows.first.bcCd / 10000.0;
          if (p.coefRows.length > 1) {
            ammo.useMultiBcG7 = true;
            ammo.multiBcTableG7VMps = Float64List.fromList(
              p.coefRows.map((r) => r.mv / 10.0).toList(),
            );
            ammo.multiBcTableG7Bc = Float64List.fromList(
              p.coefRows.map((r) => r.bcCd / 10000.0).toList(),
            );
          }
        }
      case proto.GType.CUSTOM:
        final sorted = List.of(p.coefRows)
          ..sort((a, b) => a.mv.compareTo(b.mv));
        ammo.cusomDragTableMach = Float64List.fromList(
          sorted.map((r) => r.mv / 10000.0).toList(),
        );
        ammo.cusomDragTableCd = Float64List.fromList(
          sorted.map((r) => r.bcCd / 10000.0).toList(),
        );
      default: // G1
        if (p.coefRows.isNotEmpty) {
          ammo.bcG1 = p.coefRows.first.bcCd / 10000.0;
          if (p.coefRows.length > 1) {
            ammo.useMultiBcG1 = true;
            ammo.multiBcTableG1VMps = Float64List.fromList(
              p.coefRows.map((r) => r.mv / 10.0).toList(),
            );
            ammo.multiBcTableG1Bc = Float64List.fromList(
              p.coefRows.map((r) => r.bcCd / 10000.0).toList(),
            );
          }
        }
    }
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static double _zeroDistanceMeter(proto.Profile p) {
    if (p.distances.isNotEmpty) {
      final idx = p.cZeroDistanceIdx.clamp(0, p.distances.length - 1);
      return p.distances[idx] / 100.0;
    }
    return 100.0;
  }

  static String _dragTypeStr(proto.GType t) => switch (t) {
    proto.GType.G1 => 'g1',
    proto.GType.G7 => 'g7',
    proto.GType.CUSTOM => 'custom',
    _ => 'g1',
  };
}
