import 'dart:typed_data';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
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
      ..twist = Distance.inch(p.rTwist / 100.0);

    final sight = Sight()
      ..name = p.profileName
      ..sightHeight = Distance.millimeter(p.scHeight.toDouble());

    final ammo = Ammo()
      ..name = p.cartridgeName
      ..projectileName = p.bulletName
      ..dragType = _dragType(p.bcType)
      ..weight = Weight.grain(p.bWeight / 10.0)
      ..caliber = Distance.millimeter(p.bDiameter / 100.0)
      ..length = Distance.millimeter(p.bLength / 100.0)
      ..mv = Velocity.mps(p.cMuzzleVelocity / 10.0)
      ..mvTemperature = Temperature.celsius(p.cZeroTemperature.toDouble())
      ..powderTemp = Temperature.celsius(p.cZeroPTemperature.toDouble())
      ..powderSensitivity = Ratio.fraction(p.cTCoeff / 1000.0)
      ..usePowderSensitivity = p.cTCoeff != 0
      ..zeroDistance = Distance.meter(_zeroDistanceMeter(p))
      ..zeroTemperature = Temperature.celsius(p.cZeroAirTemperature.toDouble())
      ..zeroPressure = Pressure.hPa(p.cZeroAirPressure / 10.0)
      ..zeroHumidityFrac = p.cZeroAirHumidity / 100.0
      ..zeroPowderTemp = Temperature.celsius(p.cZeroPTemperature.toDouble())
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

  static DragType _dragType(proto.GType t) => switch (t) {
    proto.GType.G1 => DragType.g1,
    proto.GType.G7 => DragType.g7,
    proto.GType.CUSTOM => DragType.custom,
    _ => DragType.g1,
  };
}
