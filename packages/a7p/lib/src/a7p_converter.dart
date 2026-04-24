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

enum A7pRange { subsonic, low, medium, long, ultra }

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
      usePowderSensitivity: p.cTCoeff >= 0,
      powderSensitivityFrac: (p.cTCoeff / 1000.0) / 100.0,
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
      zeroOffsetX: 0.0,
      zeroOffsetY: 0.0,
      zeroOffsetXUnit: "mil",
      zeroOffsetYUnit: "mil",
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

  static int _findClosestDistanceIndex(List<int> distances, int target) {
    if (distances.isEmpty) return 0;

    int closestIndex = 0;
    int minDiff = (distances[0] - target).abs();

    for (int i = 1; i < distances.length; i++) {
      final diff = (distances[i] - target).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  static proto.Payload toPayload(ProfileExport export, [A7pRange? range]) {
    final ammo = export.ammo;
    final sight = export.sight;
    final weapon = export.weapon;

    final distancesTable = switch (range) {
      A7pRange.subsonic => subsonicRangeTable,
      A7pRange.low => lowRangeTable,
      A7pRange.medium => mediumRangeTable,
      A7pRange.long => longRangeTable,
      A7pRange.ultra => ultraLongRangeTable,
      _ => mediumRangeTable,
    };
    final zeroDistanceMeter =
        ammo?.zeroDistanceMeter.toInt() ?? distancesTable.first;
    final zeroDistanceIdx = _findClosestDistanceIndex(
      distancesTable,
      zeroDistanceMeter,
    );
    final distances = distancesTable.map((el) => el * 100);

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
    final tCoeff = (((ammo?.powderSensitivityFrac ?? 0.0) * 100) * 1000)
        .round()
        .clamp(0, 5000);
    final bDiameter = ((ammo?.caliberInch ?? weapon.caliberInch) * 1000)
        .round()
        .clamp(1, 50000);
    final bWeight = ((ammo?.weightGrain ?? 100.0) * 10).round().clamp(
      10,
      65535,
    );
    final bLength = ((ammo?.lengthInch ?? 0.1) * 1000).round().clamp(1, 200000);

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
      ..cZeroDistanceIdx = zeroDistanceIdx
      ..cZeroAirTemperature = zeroAirTemp
      ..cZeroAirPressure = zeroAirPres
      ..cZeroAirHumidity = zeroHumidity
      ..cZeroWPitch = 0
      ..cZeroPTemperature = zeroPowderTemp
      ..zeroX = 0
      ..zeroY = 0
      ..distances.addAll(distances)
      ..coefRows.addAll(coefRows)
      ..switches.addAll(_defaultSwitches());

    return proto.Payload()..profile = profile;
  }

  static List<proto.CoefRow> _buildCoefRows(AmmoExport? ammo) {
    if (ammo == null) {
      return [
        proto.CoefRow()
          ..bcCd = 0
          ..mv = 0,
      ];
    }
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

const List<int> subsonicRangeTable = [
  // 25-400
  25,
  50,
  75,
  100,
  110,
  120,
  130,
  140,
  150,
  155,
  160,
  165,
  170,
  175,
  180,
  185,
  190,
  195,
  200,
  205,
  210,
  215,
  220,
  225,
  230,
  235,
  240,
  245,
  250,
  255,
  260,
  265,
  270,
  275,
  280,
  285,
  290,
  295,
  300,
  305,
  310,
  315,
  320,
  325,
  330,
  335,
  340,
  345,
  350,
  355,
  360,
  365,
  370,
  375,
  380,
  385,
  390,
  395,
  400,
];
const List<int> lowRangeTable = [
  // 100-700
  100,
  150,
  200,
  225,
  250,
  275,
  300,
  320,
  340,
  360,
  380,
  400,
  410,
  420,
  430,
  440,
  450,
  460,
  470,
  480,
  490,
  500,
  505,
  510,
  515,
  520,
  525,
  530,
  535,
  540,
  545,
  550,
  555,
  560,
  565,
  570,
  575,
  580,
  585,
  590,
  595,
  600,
  605,
  610,
  615,
  620,
  625,
  630,
  635,
  640,
  645,
  650,
  655,
  660,
  665,
  670,
  675,
  680,
  685,
  690,
  695,
  700,
];
const List<int> mediumRangeTable = [
  // 100 - 1000
  100,
  200,
  250,
  300,
  325,
  350,
  375,
  400,
  420,
  440,
  460,
  480,
  500,
  520,
  540,
  560,
  580,
  600,
  610,
  620,
  630,
  640,
  650,
  660,
  670,
  680,
  690,
  700,
  710,
  720,
  730,
  740,
  750,
  760,
  770,
  780,
  790,
  800,
  805,
  810,
  815,
  820,
  825,
  830,
  835,
  840,
  845,
  850,
  855,
  860,
  865,
  870,
  875,
  880,
  885,
  890,
  895,
  900,
  905,
  910,
  915,
  920,
  925,
  930,
  935,
  940,
  945,
  950,
  955,
  960,
  965,
  970,
  975,
  980,
  985,
  990,
  995,
  1000,
];
const List<int> longRangeTable = [
  // 100 - 1700
  100,
  200,
  250,
  300,
  350,
  400,
  420,
  440,
  460,
  480,
  500,
  520,
  540,
  560,
  580,
  600,
  610,
  620,
  630,
  640,
  650,
  660,
  670,
  680,
  690,
  700,
  710,
  720,
  730,
  740,
  750,
  760,
  770,
  780,
  790,
  800,
  810,
  820,
  830,
  840,
  850,
  860,
  870,
  880,
  890,
  900,
  910,
  920,
  930,
  940,
  950,
  960,
  970,
  980,
  990,
  1000,
  1005,
  1010,
  1015,
  1020,
  1025,
  1030,
  1035,
  1040,
  1045,
  1050,
  1055,
  1060,
  1065,
  1070,
  1075,
  1080,
  1085,
  1090,
  1095,
  1100,
  1105,
  1110,
  1115,
  1120,
  1125,
  1130,
  1135,
  1140,
  1145,
  1150,
  1155,
  1160,
  1165,
  1170,
  1175,
  1180,
  1185,
  1190,
  1195,
  1200,
  1205,
  1210,
  1215,
  1220,
  1225,
  1230,
  1235,
  1240,
  1245,
  1250,
  1255,
  1260,
  1265,
  1270,
  1275,
  1280,
  1285,
  1290,
  1295,
  1300,
  1305,
  1310,
  1315,
  1320,
  1325,
  1330,
  1335,
  1340,
  1345,
  1350,
  1355,
  1360,
  1365,
  1370,
  1375,
  1380,
  1385,
  1390,
  1395,
  1400,
  1405,
  1410,
  1415,
  1420,
  1425,
  1430,
  1435,
  1440,
  1445,
  1450,
  1455,
  1460,
  1465,
  1470,
  1475,
  1480,
  1485,
  1490,
  1495,
  1500,
  1505,
  1510,
  1515,
  1520,
  1525,
  1530,
  1535,
  1540,
  1545,
  1550,
  1555,
  1560,
  1565,
  1570,
  1575,
  1580,
  1585,
  1590,
  1595,
  1600,
  1605,
  1610,
  1615,
  1620,
  1625,
  1630,
  1635,
  1640,
  1645,
  1650,
  1655,
  1660,
  1665,
  1670,
  1675,
  1680,
  1685,
  1690,
  1695,
  1700,
];
const List<int> ultraLongRangeTable = [
  100,
  200,
  250,
  300,
  350,
  400,
  450,
  500,
  520,
  540,
  560,
  580,
  600,
  620,
  640,
  660,
  680,
  700,
  720,
  740,
  760,
  780,
  800,
  820,
  840,
  860,
  880,
  900,
  920,
  940,
  960,
  980,
  1000,
  1010,
  1020,
  1030,
  1040,
  1050,
  1060,
  1070,
  1080,
  1090,
  1100,
  1110,
  1120,
  1130,
  1140,
  1150,
  1160,
  1170,
  1180,
  1190,
  1200,
  1210,
  1220,
  1230,
  1240,
  1250,
  1260,
  1270,
  1280,
  1290,
  1300,
  1310,
  1320,
  1330,
  1340,
  1350,
  1360,
  1370,
  1380,
  1390,
  1400,
  1410,
  1420,
  1430,
  1440,
  1450,
  1460,
  1470,
  1480,
  1490,
  1500,
  1505,
  1510,
  1515,
  1520,
  1525,
  1530,
  1535,
  1540,
  1545,
  1550,
  1555,
  1560,
  1565,
  1570,
  1575,
  1580,
  1585,
  1590,
  1595,
  1600,
  1605,
  1610,
  1615,
  1620,
  1625,
  1630,
  1635,
  1640,
  1645,
  1650,
  1655,
  1660,
  1665,
  1670,
  1675,
  1680,
  1685,
  1690,
  1695,
  1700,
  1705,
  1710,
  1715,
  1720,
  1725,
  1730,
  1735,
  1740,
  1745,
  1750,
  1755,
  1760,
  1765,
  1770,
  1775,
  1780,
  1785,
  1790,
  1795,
  1800,
  1805,
  1810,
  1815,
  1820,
  1825,
  1830,
  1835,
  1840,
  1845,
  1850,
  1855,
  1860,
  1865,
  1870,
  1875,
  1880,
  1885,
  1890,
  1895,
  1900,
  1905,
  1910,
  1915,
  1920,
  1925,
  1930,
  1935,
  1940,
  1945,
  1950,
  1955,
  1960,
  1965,
  1970,
  1975,
  1980,
  1985,
  1990,
  1995,
  2000,
  2005,
  2010,
  2015,
  2020,
  2025,
  2030,
  2035,
  2040,
  2045,
  2050,
  2055,
  2060,
  2065,
];
