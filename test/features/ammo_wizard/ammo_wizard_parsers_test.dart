//   flutter test test/features/ammo_wizard/ammo_wizard_parsers_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_parsers.dart';

void main() {
  // ── decodeBcTable ────────────────────────────────────────────────────────

  group('decodeBcTable', () {
    test('returns null when both lists are null', () {
      expect(decodeBcTable(null, null), isNull);
    });

    test('returns null when vMps is null', () {
      expect(decodeBcTable(null, Float64List.fromList([0.5])), isNull);
    });

    test('returns null when bcs is null', () {
      expect(decodeBcTable(Float64List.fromList([800.0]), null), isNull);
    });

    test('returns null when vMps is empty', () {
      expect(
        decodeBcTable(Float64List(0), Float64List.fromList([0.5])),
        isNull,
      );
    });

    test('decodes a single pair correctly', () {
      final result = decodeBcTable(
        Float64List.fromList([800.0]),
        Float64List.fromList([0.475]),
      );
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].vMps, closeTo(800.0, 1e-9));
      expect(result[0].bc, closeTo(0.475, 1e-9));
    });

    test('decodes multiple pairs in order', () {
      final result = decodeBcTable(
        Float64List.fromList([900.0, 800.0, 700.0]),
        Float64List.fromList([0.45, 0.47, 0.50]),
      );
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0], (vMps: 900.0, bc: 0.45));
      expect(result[1], (vMps: 800.0, bc: 0.47));
      expect(result[2], (vMps: 700.0, bc: 0.50));
    });

    test('preserves zero velocity entry', () {
      final result = decodeBcTable(
        Float64List.fromList([0.0]),
        Float64List.fromList([0.3]),
      );
      expect(result![0].vMps, 0.0);
    });
  });

  // ── decodeCustomDragTable ─────────────────────────────────────────────────

  group('decodeCustomDragTable', () {
    test('returns null when both lists are null', () {
      expect(decodeCustomDragTable(null, null), isNull);
    });

    test('returns null when mach is null', () {
      expect(decodeCustomDragTable(null, Float64List.fromList([0.3])), isNull);
    });

    test('returns null when cd is null', () {
      expect(decodeCustomDragTable(Float64List.fromList([0.5]), null), isNull);
    });

    test('returns null when mach is empty', () {
      expect(
        decodeCustomDragTable(Float64List(0), Float64List.fromList([0.3])),
        isNull,
      );
    });

    test('decodes a single pair correctly', () {
      final result = decodeCustomDragTable(
        Float64List.fromList([0.5]),
        Float64List.fromList([0.284]),
      );
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].mach, closeTo(0.5, 1e-9));
      expect(result[0].cd, closeTo(0.284, 1e-9));
    });

    test('decodes multiple pairs in order', () {
      final result = decodeCustomDragTable(
        Float64List.fromList([0.5, 1.0, 2.0]),
        Float64List.fromList([0.284, 0.415, 0.320]),
      );
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0], (mach: 0.5, cd: 0.284));
      expect(result[1], (mach: 1.0, cd: 0.415));
      expect(result[2], (mach: 2.0, cd: 0.320));
    });
  });

  // ── decodePowderSensTable ─────────────────────────────────────────────────

  group('decodePowderSensTable', () {
    test('returns null when both lists are null', () {
      expect(decodePowderSensTable(null, null), isNull);
    });

    test('returns null when tempC is null', () {
      expect(
        decodePowderSensTable(null, Float64List.fromList([800.0])),
        isNull,
      );
    });

    test('returns null when vMps is null', () {
      expect(decodePowderSensTable(Float64List.fromList([20.0]), null), isNull);
    });

    test('returns null when tempC is empty', () {
      expect(
        decodePowderSensTable(Float64List(0), Float64List.fromList([800.0])),
        isNull,
      );
    });

    test('decodes a single pair correctly', () {
      final result = decodePowderSensTable(
        Float64List.fromList([20.0]),
        Float64List.fromList([800.0]),
      );
      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result[0].tempC, closeTo(20.0, 1e-9));
      expect(result[0].vMps, closeTo(800.0, 1e-9));
    });

    test('decodes multiple pairs in order', () {
      final result = decodePowderSensTable(
        Float64List.fromList([-10.0, 15.0, 40.0]),
        Float64List.fromList([790.0, 800.0, 812.0]),
      );
      expect(result, isNotNull);
      expect(result!.length, 3);
      expect(result[0], (tempC: -10.0, vMps: 790.0));
      expect(result[1], (tempC: 15.0, vMps: 800.0));
      expect(result[2], (tempC: 40.0, vMps: 812.0));
    });

    test('handles negative temperature correctly', () {
      final result = decodePowderSensTable(
        Float64List.fromList([-40.0]),
        Float64List.fromList([775.0]),
      );
      expect(result![0].tempC, -40.0);
    });
  });
}
