import 'dart:convert';
import 'dart:typed_data';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';

class BuiltinCollection {
  final List<Weapon> weapons;
  final List<Ammo> cartridges;
  final List<Ammo> bullets;
  final List<Sight> sights;

  const BuiltinCollection({
    required this.weapons,
    required this.cartridges,
    required this.bullets,
    required this.sights,
  });

  static const empty = BuiltinCollection(
    weapons: [],
    cartridges: [],
    bullets: [],
    sights: [],
  );
}

abstract final class CollectionParser {
  static BuiltinCollection parse(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    final ammoList = (map['ammo'] as List? ?? []).cast<Map<String, dynamic>>();

    return BuiltinCollection(
      weapons: (map['weapon'] as List? ?? [])
          .map((w) => _parseWeapon(w as Map<String, dynamic>))
          .toList(),
      cartridges: ammoList
          .where((j) => (j['type'] as String?) != 'bullet')
          .map(_parseAmmo)
          .toList(),
      bullets: ammoList
          .where((j) => (j['type'] as String?) == 'bullet')
          .map(_parseAmmo)
          .toList(),
      sights: (map['sights'] as List? ?? [])
          .map((s) => _parseSight(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Weapon ─────────────────────────────────────────────────────────────────

  static Weapon _parseWeapon(Map<String, dynamic> j) {
    final barrelRaw = j['barrelLengthInch'] as num?;
    return Weapon()
      ..name = j['name'] as String
      ..vendor = j['vendor'] as String?
      ..notes = j['notes'] as String?
      ..image = j['image'] as String?
      ..caliberInch = (j['caliberInch'] as num?)?.toDouble() ?? -1.0
      ..caliberName = j['caliberName'] as String? ?? ''
      ..twist = Distance.inch((j['twistInch'] as num).toDouble())
      ..barrelLength = barrelRaw != null
          ? Distance.inch(barrelRaw.toDouble())
          : null;
  }

  // ── Ammo ───────────────────────────────────────────────────────────────────

  static Ammo _parseAmmo(Map<String, dynamic> j) {
    final dragType = _dragType(j['dragTypeValue'] as String? ?? 'g1');

    final useMultiG1 = j['useMultiBcG1'] as bool? ?? false;
    final useMultiG7 = j['useMultiBcG7'] as bool? ?? false;
    final useCustom = j['useCusomDragTable'] as bool? ?? false;

    final mvRaw = j['muzzleVelocityMps'] as num?;

    final ammo = Ammo()
      ..name = j['name'] as String
      ..vendor = j['vendor'] as String?
      ..projectileName = j['projectileName'] as String?
      ..image = j['image'] as String?
      ..dragType = dragType
      ..caliberInch = (j['caliberInch'] as num?)?.toDouble() ?? -1.0
      ..weightGrain = (j['weightGrain'] as num?)?.toDouble() ?? -1.0
      ..lengthInch = (j['lengthInch'] as num?)?.toDouble() ?? -1.0
      ..muzzleVelocityMps = mvRaw != null ? mvRaw.toDouble() : -1.0
      ..mvTemperature = Temperature.celsius(
        (j['muzzleVelocityTemperatureC'] as num? ?? 15.0).toDouble(),
      )
      ..powderSensitivity = Ratio.fraction(
        (j['powderSensitivityFrac'] as num? ?? 0.0).toDouble(),
      )
      ..usePowderSensitivity = j['usePowderSensitivity'] as bool? ?? false
      ..useMultiBcG1 = useMultiG1
      ..useMultiBcG7 = useMultiG7;

    // BC values
    final bcG1Raw = j['bcG1'] as num?;
    final bcG7Raw = j['bcG7'] as num?;
    if (dragType == DragType.g7) {
      ammo.bcG7 = bcG7Raw?.toDouble() ?? -1.0;
      if (useMultiG7) {
        _applyMultiBc(ammo, j['multiBCtableG7'] as List? ?? [], isG7: true);
      }
    } else if (dragType == DragType.g1) {
      ammo.bcG1 = bcG1Raw?.toDouble() ?? -1.0;
      if (useMultiG1) {
        _applyMultiBc(ammo, j['multiBCtableG1'] as List? ?? [], isG7: false);
      }
    } else if (useCustom) {
      _applyCustomDrag(ammo, j['cusomDragTable'] as List? ?? []);
    }

    // Powder sensitivity table [{t, v}]
    final sensTable = j['powderSensitivityTable'] as List? ?? [];
    if (sensTable.isNotEmpty) {
      _applyPowderSensTable(ammo, sensTable);
    }

    // Zero conditions
    final zc = j['zeroConditions'] as Map<String, dynamic>?;
    if (zc != null) {
      ammo.zeroDistance = Distance.meter(
        (zc['distance'] as num? ?? 100.0).toDouble(),
      );
      ammo.zeroLookAngle = Angular.degree(
        (zc['lookAngle'] as num? ?? 0.0).toDouble(),
      );
      ammo.zeroUseDiffPowderTemperature =
          zc['useDiffPowderTemperature'] as bool? ?? false;
      ammo.zeroUseCoriolis = zc['useCoriolis'] as bool? ?? false;
      ammo.zeroLatitudeDeg = (zc['latitudeDeg'] as num? ?? 0.0).toDouble();
      ammo.zeroAzimuthDeg = (zc['azimuthDeg'] as num? ?? 0.0).toDouble();

      final atmo = zc['atmo'] as Map<String, dynamic>?;
      if (atmo != null) {
        ammo.zeroAltitude = Distance.meter(
          (atmo['altitude'] as num? ?? 0.0).toDouble(),
        );
        ammo.zeroTemperature = Temperature.celsius(
          (atmo['temperature'] as num? ?? 15.0).toDouble(),
        );
        ammo.zeroPressure = Pressure.hPa(
          (atmo['pressure'] as num? ?? 1013.25).toDouble(),
        );
        ammo.zeroHumidityFrac = (atmo['humidity'] as num? ?? 0.0).toDouble();
        ammo.zeroPowderTemp = Temperature.celsius(
          (atmo['powderTemperature'] as num? ?? 15.0).toDouble(),
        );
      }
    }

    // Zero offset (x/y in mrad → radians)
    final zo = j['zeroOffset'] as Map<String, dynamic>?;
    if (zo != null) {
      ammo.zeroOffsetXRad = ((zo['x'] as num? ?? 0.0).toDouble()) / 1000.0;
      ammo.zeroOffsetYRad = ((zo['y'] as num? ?? 0.0).toDouble()) / 1000.0;
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

  static void _applyCustomDrag(Ammo ammo, List rows) {
    if (rows.isEmpty) return;
    ammo.cusomDragTableMach = Float64List.fromList(
      rows.map<double>((r) => ((r as Map)['v'] as num).toDouble()).toList(),
    );
    ammo.cusomDragTableCd = Float64List.fromList(
      rows.map<double>((r) => ((r as Map)['cd'] as num).toDouble()).toList(),
    );
  }

  static void _applyPowderSensTable(Ammo ammo, List rows) {
    ammo.powderSensitivityTC = Float64List.fromList(
      rows.map<double>((r) => ((r as Map)['t'] as num).toDouble()).toList(),
    );
    ammo.powderSensitivityVMps = Float64List.fromList(
      rows.map<double>((r) => ((r as Map)['v'] as num).toDouble()).toList(),
    );
  }

  // ── Sight ──────────────────────────────────────────────────────────────────

  static Sight _parseSight(Map<String, dynamic> j) {
    final click = (j['horizontalClick'] as num? ?? 0.1).toDouble();
    final calibMag = j['calibratedMagnification'] as num?;
    return Sight()
      ..name = j['name'] as String
      ..vendor = j['vendor'] as String?
      ..image = j['image'] as String?
      ..reticleImage = j['reticleImage'] as String?
      ..focalPlaneValue = j['focalPlaneValue'] as String? ?? 'ffp'
      ..sightHeightInch = (j['sightHeightInch'] as num? ?? 0.0).toDouble()
      ..sightHorizontalOffsetInch =
          (j['sightHorizontalOffsetInch'] as num? ?? 0.0).toDouble()
      ..verticalClick = click
      ..horizontalClick = click
      ..verticalClickUnit = j['verticalClickUnit'] as String? ?? 'mil'
      ..horizontalClickUnit = j['horizontalClickUnit'] as String? ?? 'mil'
      ..minMagnification = (j['minMagnification'] as num? ?? 0.0).toDouble()
      ..maxMagnification = (j['maxMagnification'] as num? ?? 0.0).toDouble()
      ..calibratedMagnification = calibMag?.toDouble() ?? -1.0;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DragType _dragType(String raw) => switch (raw.toUpperCase()) {
    'G7' => DragType.g7,
    'CUSTOM' => DragType.custom,
    _ => DragType.g1,
  };
}
