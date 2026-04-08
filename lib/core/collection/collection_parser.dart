import 'dart:convert';
import 'dart:typed_data';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';

class BuiltinCollection {
  final List<Weapon> rifles;
  final List<Ammo> cartridges;
  final List<Ammo> projectiles;
  final List<Sight> sights;

  const BuiltinCollection({
    required this.rifles,
    required this.cartridges,
    required this.projectiles,
    required this.sights,
  });

  static const empty = BuiltinCollection(
    rifles: [],
    cartridges: [],
    projectiles: [],
    sights: [],
  );
}

abstract final class CollectionParser {
  static BuiltinCollection parse(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    // calibers lookup: id → diameter in inches
    final calibers = <int, double>{};
    for (final c in (map['calibers'] as List? ?? [])) {
      final cm = c as Map<String, dynamic>;
      calibers[cm['id'] as int] = ((cm['diameter'] ?? cm['caliber']) as num)
          .toDouble();
    }

    return BuiltinCollection(
      rifles: (map['weapon'] as List? ?? [])
          .map((w) => _parseRifle(w as Map<String, dynamic>, calibers))
          .toList(),
      cartridges: (map['cartridges'] as List? ?? [])
          .map((c) => _parseCartridge(c as Map<String, dynamic>, calibers))
          .toList(),
      projectiles: (map['projectiles'] as List? ?? [])
          .map((p) => _parseCartridge(p as Map<String, dynamic>, calibers))
          .toList(),
      sights: (map['sights'] as List? ?? [])
          .map((s) => _parseSight(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Rifle ──────────────────────────────────────────────────────────────────

  static Weapon _parseRifle(Map<String, dynamic> j, Map<int, double> calibers) {
    final caliberId = j['caliberId'] as int?;
    final diameterInch = caliberId != null ? calibers[caliberId] : null;
    final barrelRaw =
        (j['extra'] as Map<String, dynamic>?)?['barrelLength'] as num?;
    return Weapon()
      ..name = j['name'] as String
      ..vendor = j['vendor'] as String?
      ..twist = Distance.inch((j['rTwist'] as num).toDouble())
      ..caliber = Distance.inch(diameterInch ?? 0.0)
      ..barrelLength = barrelRaw != null
          ? Distance.inch(barrelRaw.toDouble())
          : null;
  }

  // ── Cartridge ──────────────────────────────────────────────────────────────

  static Ammo _parseCartridge(
    Map<String, dynamic> j,
    Map<int, double> calibers,
  ) {
    final caliberId = j['caliberId'] as int?;
    final diameterInch =
        (caliberId != null ? calibers[caliberId] : null) ?? 0.0;
    final dragType = _dragType(j['dType'] as String? ?? 'G1');

    final useMultiG1 = j['useMultiBcG1'] as bool? ?? false;
    final useMultiG7 = j['useMultiBcG7'] as bool? ?? false;

    final ammo = Ammo()
      ..name = j['name'] as String
      ..vendor = j['vendor'] as String?
      ..projectileName = j['projectileName'] as String?
      ..dragType = dragType
      ..caliber = Distance.inch(diameterInch)
      ..weight = Weight.grain((j['bulletWeight'] as num? ?? 0.0).toDouble())
      ..length = Distance.inch((j['bulletLength'] as num? ?? 0.0).toDouble())
      ..mv = Velocity.mps((j['muzzleVelocity'] as num? ?? 0.0).toDouble())
      ..mvTemperature = Temperature.celsius(
        (j['powderTemperature'] as num? ?? 15.0).toDouble(),
      )
      ..powderTemp = Temperature.celsius(
        (j['powderTemperature'] as num? ?? 15.0).toDouble(),
      )
      ..powderSensitivity = Ratio.fraction(
        (j['powderSensitivity'] as num? ?? 0.0).toDouble(),
      )
      ..useMultiBcG1 = useMultiG1
      ..useMultiBcG7 = useMultiG7;

    // BC values
    if (dragType == DragType.g7) {
      ammo.bcG7 = (j['bcG7'] as num? ?? 0.0).toDouble();
      if (useMultiG7) {
        _applyMultiBc(ammo, j['multiBCtableG7'] as List? ?? [], isG7: true);
      }
    } else {
      ammo.bcG1 = (j['bcG1'] as num? ?? 0.0).toDouble();
      if (useMultiG1) {
        _applyMultiBc(ammo, j['multiBCtableG1'] as List? ?? [], isG7: false);
      }
    }

    // Zero conditions
    final zc = j['zeroConditions'] as Map<String, dynamic>?;
    if (zc != null) {
      ammo.zeroDistance = Distance.meter(
        (zc['targetDistance'] as num? ?? 100.0).toDouble(),
      );
      final atmo = zc['atmo'] as Map<String, dynamic>?;
      if (atmo != null) {
        ammo.zeroAltitude = Distance.meter(
          (atmo['altitude'] as num? ?? 0.0).toDouble(),
        );
        ammo.zeroTemperature = Temperature.celsius(
          (atmo['temperature'] as num? ?? 15.0).toDouble(),
        );
        ammo.zeroPressure = Pressure.hPa(
          (atmo['pressure'] as num? ?? 1013.0).toDouble(),
        );
        ammo.zeroHumidityFrac = (atmo['humidity'] as num? ?? 0.0).toDouble();
        ammo.zeroPowderTemp = Temperature.celsius(
          (atmo['powderTemp'] as num? ?? 15.0).toDouble(),
        );
      }
    }

    return ammo;
  }

  static void _applyMultiBc(Ammo ammo, List rows, {required bool isG7}) {
    if (rows.isEmpty) return;
    final vList = rows
        .map<double>((r) => ((r as Map)['v'] as num).toDouble())
        .toList();
    final bcList = rows
        .map<double>((r) => ((r as Map)['bc'] as num).toDouble())
        .toList();
    if (isG7) {
      ammo.multiBcTableG7VMps = Float64List.fromList(vList);
      ammo.multiBcTableG7Bc = Float64List.fromList(bcList);
      ammo.bcG7 = bcList.first;
    } else {
      ammo.multiBcTableG1VMps = Float64List.fromList(vList);
      ammo.multiBcTableG1Bc = Float64List.fromList(bcList);
      ammo.bcG1 = bcList.first;
    }
  }

  // ── Sight ──────────────────────────────────────────────────────────────────

  static Sight _parseSight(Map<String, dynamic> j) => Sight()
    ..name = j['name'] as String
    ..vendor = j['vendor'] as String?;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DragType _dragType(String raw) => switch (raw.toUpperCase()) {
    'G7' => DragType.g7,
    'CUSTOM' => DragType.custom,
    _ => DragType.g1,
  };
}
