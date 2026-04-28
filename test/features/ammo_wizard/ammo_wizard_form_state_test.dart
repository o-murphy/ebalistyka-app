//   flutter test test/features/ammo_wizard/ammo_wizard_form_state_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_form_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// 7.62×51 NATO .308 ammo fixture — all fields populated.
Ammo _make308() {
  final a = Ammo();
  a.name = 'Test .308';
  a.vendor = 'Hornady';
  a.projectileName = '175gr BTHP';
  a.caliberInch = 0.308;
  a.weightGrain = 175.0;
  a.lengthInch = 1.530;
  a.dragType = DragType.g7;
  a.useMultiBcG7 = false;
  a.bcG7 = 0.475;
  a.muzzleVelocityMps = 800.0;
  a.muzzleVelocityTemperatureC = 15.0;
  a.zeroDistanceMeter = 100.0;
  a.zeroLookAngleRad = 0.0;
  a.zeroTemperatureC = 15.0;
  a.zeroAltitudeMeter = 0.0;
  a.zeroPressurehPa = 1013.0;
  a.zeroHumidityFrac = 0.5;
  a.usePowderSensitivity = false;
  a.powderSensitivityFrac = 0.0;
  a.zeroUseDiffPowderTemperature = false;
  a.zeroPowderTemperatureC = 15.0;
  a.zeroUseCoriolis = false;
  a.zeroLatitudeDeg = 0.0;
  a.zeroAzimuthDeg = 0.0;
  a.zeroOffsetYUnit = Unit.mil.name;
  a.zeroOffsetY = 0.0;
  a.zeroOffsetXUnit = Unit.mil.name;
  a.zeroOffsetX = 0.0;
  return a;
}

void main() {
  // ── fromAmmo — new ammo ───────────────────────────────────────────────────────

  group('AmmoWizardFormState.fromAmmo — new ammo', () {
    late AmmoWizardFormState s;

    setUp(() {
      s = AmmoWizardFormState.fromAmmo(initial: null, caliberInch: 0.308);
    });

    test('name is empty', () => expect(s.name, ''));
    test('vendor is empty', () => expect(s.vendor, ''));
    test('projectileName is empty', () => expect(s.projectileName, ''));

    test('caliberRaw reflects caliberInch parameter (mm)', () {
      // 0.308 inch → 7.8232 mm
      expect(s.caliberRaw, closeTo(0.308 * 25.4, 0.001));
    });

    test('weightRaw is null for new ammo', () => expect(s.weightRaw, isNull));
    test('lengthRaw is null for new ammo', () => expect(s.lengthRaw, isNull));
    test('mvRaw is null for new ammo', () => expect(s.mvRaw, isNull));

    test('defaults: dragType G1', () => expect(s.dragType, DragType.g1));
    test('defaults: useMultiBcG1 false', () => expect(s.useMultiBcG1, false));
    test('defaults: useMultiBcG7 false', () => expect(s.useMultiBcG7, false));
    test('defaults: bcG1 null', () => expect(s.bcG1, isNull));
    test('defaults: bcG7 null', () => expect(s.bcG7, isNull));

    test('defaults: mvTempRaw 15 °C', () => expect(s.mvTempRaw, 15.0));
    test('defaults: zeroDistRaw 100 m', () => expect(s.zeroDistRaw, 100.0));
    test(
      'defaults: zeroLookAngleRaw 0°',
      () => expect(s.zeroLookAngleRaw, 0.0),
    );
    test('defaults: zeroTempRaw 15 °C', () => expect(s.zeroTempRaw, 15.0));
    test('defaults: zeroAltRaw 0 m', () => expect(s.zeroAltRaw, 0.0));
    test(
      'defaults: zeroPressureRaw 1013 hPa',
      () => expect(s.zeroPressureRaw, 1013.0),
    );
    test('defaults: zeroHumidityRaw 0.0', () => expect(s.zeroHumidityRaw, 0.0));
    test(
      'defaults: usePowderSensitivity false',
      () => expect(s.usePowderSensitivity, false),
    );
    test(
      'defaults: zeroUseCoriolis false',
      () => expect(s.zeroUseCoriolis, false),
    );
  });

  // ── fromAmmo — existing ammo ─────────────────────────────────────────────────

  group('AmmoWizardFormState.fromAmmo — existing ammo', () {
    late AmmoWizardFormState s;
    late Ammo a;

    setUp(() {
      a = _make308();
      s = AmmoWizardFormState.fromAmmo(initial: a, caliberInch: null);
    });

    test('name restored', () => expect(s.name, 'Test .308'));
    test('vendor restored', () => expect(s.vendor, 'Hornady'));
    test(
      'projectileName restored',
      () => expect(s.projectileName, '175gr BTHP'),
    );

    test('caliberRaw restored (inch → mm)', () {
      // 0.308 inch stored → 0.308 * 25.4 ≈ 7.823 mm in rawUnit
      expect(s.caliberRaw, closeTo(0.308 * 25.4, 0.01));
    });

    test('weightRaw restored (grain)', () {
      expect(s.weightRaw, closeTo(175.0, 0.01));
    });

    test('lengthRaw restored (inch → mm)', () {
      // 1.530 inch → 38.862 mm
      expect(s.lengthRaw, closeTo(1.530 * 25.4, 0.01));
    });

    test('dragType restored to G7', () => expect(s.dragType, DragType.g7));
    test('useMultiBcG7 restored false', () => expect(s.useMultiBcG7, false));
    test('bcG7 restored', () => expect(s.bcG7, closeTo(0.475, 1e-6)));

    test('mvRaw restored (mps)', () => expect(s.mvRaw, closeTo(800.0, 0.01)));
    test(
      'mvTempRaw restored (°C)',
      () => expect(s.mvTempRaw, closeTo(15.0, 0.01)),
    );

    test(
      'zeroDistRaw restored (m)',
      () => expect(s.zeroDistRaw, closeTo(100.0, 0.01)),
    );
    test(
      'zeroTempRaw restored (°C)',
      () => expect(s.zeroTempRaw, closeTo(15.0, 0.01)),
    );
    test(
      'zeroPressureRaw restored (hPa)',
      () => expect(s.zeroPressureRaw, closeTo(1013.0, 0.5)),
    );
    test(
      'zeroHumidityRaw restored',
      () => expect(s.zeroHumidityRaw, closeTo(0.5, 1e-6)),
    );

    test('BC tables null for single-BC ammo', () {
      expect(s.multiBcG1Table, isNull);
      expect(s.multiBcG7Table, isNull);
    });

    test('custom drag table null', () => expect(s.customDragTable, isNull));
    test('powder sens table null', () => expect(s.powderSensTable, isNull));
  });

  group('AmmoWizardFormState.fromAmmo — multi-BC ammo', () {
    test('multiBcG7Table restored from Float64Lists', () {
      final a = _make308();
      a.useMultiBcG7 = true;
      a.multiBcTableG7VMps = Float64List.fromList([900.0, 800.0]);
      a.multiBcTableG7Bc = Float64List.fromList([0.45, 0.47]);

      final s = AmmoWizardFormState.fromAmmo(initial: a, caliberInch: null);

      expect(s.multiBcG7Table, isNotNull);
      expect(s.multiBcG7Table!.length, 2);
      expect(s.multiBcG7Table![0].vMps, 900.0);
      expect(s.multiBcG7Table![0].bc, 0.45);
    });

    test('customDragTable restored from Float64Lists', () {
      final a = _make308();
      a.dragType = DragType.custom;
      a.customDragTableMach = Float64List.fromList([0.5, 1.0]);
      a.customDragTableCd = Float64List.fromList([0.284, 0.415]);

      final s = AmmoWizardFormState.fromAmmo(initial: a, caliberInch: null);

      expect(s.customDragTable, isNotNull);
      expect(s.customDragTable!.length, 2);
      expect(s.customDragTable![0].mach, 0.5);
      expect(s.customDragTable![0].cd, 0.284);
    });

    test('powderSensTable restored from Float64Lists', () {
      final a = _make308();
      a.powderSensitivityTC = Float64List.fromList([-10.0, 15.0, 40.0]);
      a.powderSensitivityVMps = Float64List.fromList([790.0, 800.0, 812.0]);

      final s = AmmoWizardFormState.fromAmmo(initial: a, caliberInch: null);

      expect(s.powderSensTable, isNotNull);
      expect(s.powderSensTable!.length, 3);
      expect(s.powderSensTable![1].tempC, 15.0);
      expect(s.powderSensTable![1].vMps, 800.0);
    });
  });

  // ── isValid ───────────────────────────────────────────────────────────────────

  group('AmmoWizardFormState.isValid', () {
    AmmoWizardFormState valid() =>
        AmmoWizardFormState.fromAmmo(
          initial: null,
          caliberInch: 0.308,
        ).copyWith(
          name: 'Test',
          weightRaw: 175.0,
          lengthRaw: 38.86,
          mvRaw: 800.0,
          bcG1: 0.4,
        );

    test('false when name is empty', () {
      expect(valid().copyWith(name: '').isValid, false);
    });

    test('false when name is whitespace only', () {
      final s = valid().copyWith(name: '   ');
      expect(s.isValid, false);
    });

    test('false when caliberRaw is zero', () {
      expect(valid().copyWith(caliberRaw: 0.0).isValid, false);
    });

    test('false when weightRaw is null', () {
      expect(
        valid().copyWith(weightRaw: null, clearWeight: true).isValid,
        false,
      );
    });

    test('false when weightRaw is zero', () {
      expect(valid().copyWith(weightRaw: 0.0).isValid, false);
    });

    test('false when lengthRaw is null', () {
      expect(
        valid().copyWith(lengthRaw: null, clearLength: true).isValid,
        false,
      );
    });

    test('false when mvRaw is null', () {
      expect(valid().copyWith(mvRaw: null, clearMv: true).isValid, false);
    });

    test('false when mvRaw is zero', () {
      expect(valid().copyWith(mvRaw: 0.0).isValid, false);
    });

    test('false for G1 single-BC when bcG1 is null', () {
      final s = valid().copyWith(
        dragType: DragType.g1,
        useMultiBcG1: false,
        bcG1: null,
        clearBcG1: true,
      );
      expect(s.isValid, false);
    });

    test('false for G1 single-BC when bcG1 is zero', () {
      final s = valid().copyWith(
        dragType: DragType.g1,
        useMultiBcG1: false,
        bcG1: 0.0,
      );
      expect(s.isValid, false);
    });

    test('false for G1 multi-BC when table is null', () {
      final s = valid().copyWith(
        dragType: DragType.g1,
        useMultiBcG1: true,
        multiBcG1Table: null,
        clearMultiBcG1Table: true,
      );
      expect(s.isValid, false);
    });

    test('false for G1 multi-BC when table is empty', () {
      final s = valid().copyWith(
        dragType: DragType.g1,
        useMultiBcG1: true,
        multiBcG1Table: [],
      );
      expect(s.isValid, false);
    });

    test('true for G1 multi-BC with non-empty table', () {
      final s = valid().copyWith(
        dragType: DragType.g1,
        useMultiBcG1: true,
        multiBcG1Table: [(vMps: 800.0, bc: 0.4)],
      );
      expect(s.isValid, true);
    });

    test('false for G7 single-BC when bcG7 is null', () {
      final s = valid().copyWith(
        dragType: DragType.g7,
        useMultiBcG7: false,
        bcG7: null,
        clearBcG7: true,
      );
      expect(s.isValid, false);
    });

    test('true for G7 single-BC with positive bcG7', () {
      final s = valid().copyWith(
        dragType: DragType.g7,
        useMultiBcG7: false,
        bcG7: 0.475,
      );
      expect(s.isValid, true);
    });

    test('false for G7 multi-BC when table is empty', () {
      final s = valid().copyWith(
        dragType: DragType.g7,
        useMultiBcG7: true,
        multiBcG7Table: [],
      );
      expect(s.isValid, false);
    });

    test('false for custom drag when table is null', () {
      final s = valid().copyWith(
        dragType: DragType.custom,
        customDragTable: null,
        clearCustomDragTable: true,
      );
      expect(s.isValid, false);
    });

    test('false for custom drag when table is empty', () {
      final s = valid().copyWith(
        dragType: DragType.custom,
        customDragTable: [],
      );
      expect(s.isValid, false);
    });

    test('true for custom drag with non-empty table', () {
      final s = valid().copyWith(
        dragType: DragType.custom,
        customDragTable: [(mach: 0.5, cd: 0.284)],
      );
      expect(s.isValid, true);
    });

    test('true with all required fields for G1', () {
      expect(valid().isValid, true);
    });
  });

  // ── buildAmmo ─────────────────────────────────────────────────────────────────

  group('AmmoWizardFormState.buildAmmo — create new', () {
    late Ammo ammo;

    setUp(() {
      final s = AmmoWizardFormState.fromAmmo(initial: null, caliberInch: 0.308)
          .copyWith(
            name: 'Match .308',
            vendor: 'Federal',
            projectileName: '175gr SMK',
            weightRaw: 175.0, // grain
            lengthRaw: 38.86, // mm
            dragType: DragType.g7,
            bcG7: 0.475,
            mvRaw: 800.0, // mps
            mvTempRaw: 15.0, // °C
            zeroDistRaw: 100.0, // m
            zeroTempRaw: 15.0, // °C
            zeroPressureRaw: 1013.0, // hPa
            zeroHumidityRaw: 0.5,
          );
      ammo = s.buildAmmo(null);
    });

    test('name set', () => expect(ammo.name, 'Match .308'));
    test('vendor set', () => expect(ammo.vendor, 'Federal'));
    test('projectileName set', () => expect(ammo.projectileName, '175gr SMK'));

    test('caliberInch correct (mm → inch)', () {
      expect(ammo.caliberInch, closeTo(0.308, 0.001));
    });

    test('weightGrain correct (grain identity)', () {
      expect(ammo.weightGrain, closeTo(175.0, 0.01));
    });

    test('lengthInch correct (mm → inch)', () {
      // 38.86 mm / 25.4 ≈ 1.530 inch
      expect(ammo.lengthInch, closeTo(38.86 / 25.4, 0.001));
    });

    test('dragType set to G7', () => expect(ammo.dragType, DragType.g7));
    test('bcG7 set', () => expect(ammo.bcG7, closeTo(0.475, 1e-6)));

    test(
      'muzzleVelocityMps correct',
      () => expect(ammo.muzzleVelocityMps, closeTo(800.0, 0.01)),
    );
    test(
      'muzzleVelocityTemperatureC correct',
      () => expect(ammo.muzzleVelocityTemperatureC, closeTo(15.0, 0.01)),
    );

    test(
      'zeroDistanceMeter correct',
      () => expect(ammo.zeroDistanceMeter, closeTo(100.0, 0.01)),
    );
    test(
      'zeroTemperatureC correct',
      () => expect(ammo.zeroTemperatureC, closeTo(15.0, 0.01)),
    );
    test(
      'zeroPressurehPa correct',
      () => expect(ammo.zeroPressurehPa, closeTo(1013.0, 0.5)),
    );
    test(
      'zeroHumidityFrac correct',
      () => expect(ammo.zeroHumidityFrac, closeTo(0.5, 1e-6)),
    );

    test('null weight → sentinel -1', () {
      final s = AmmoWizardFormState.fromAmmo(
        initial: null,
        caliberInch: 0.308,
      ).copyWith(name: 'x', mvRaw: 800.0, lengthRaw: 38.0, bcG1: 0.4);
      final a = s.buildAmmo(null);
      expect(a.weightGrain, -1.0);
    });

    test('null length → sentinel -1', () {
      final s = AmmoWizardFormState.fromAmmo(
        initial: null,
        caliberInch: 0.308,
      ).copyWith(name: 'x', mvRaw: 800.0, weightRaw: 175.0, bcG1: 0.4);
      final a = s.buildAmmo(null);
      expect(a.lengthInch, -1.0);
    });

    test('null mv → sentinel -1', () {
      final s = AmmoWizardFormState.fromAmmo(
        initial: null,
        caliberInch: 0.308,
      ).copyWith(name: 'x', weightRaw: 175.0, lengthRaw: 38.0, bcG1: 0.4);
      final a = s.buildAmmo(null);
      expect(a.muzzleVelocityMps, -1.0);
    });
  });

  group('AmmoWizardFormState.buildAmmo — multi-BC G1 table encoding', () {
    test('table encoded to Float64Lists', () {
      final s = AmmoWizardFormState.fromAmmo(initial: null, caliberInch: 0.308)
          .copyWith(
            name: 'x',
            weightRaw: 175.0,
            lengthRaw: 38.0,
            mvRaw: 800.0,
            dragType: DragType.g1,
            useMultiBcG1: true,
            multiBcG1Table: [(vMps: 900.0, bc: 0.45), (vMps: 800.0, bc: 0.47)],
          );
      final ammo = s.buildAmmo(null);
      expect(ammo.multiBcTableG1VMps, isNotNull);
      expect(ammo.multiBcTableG1VMps!.length, 2);
      expect(ammo.multiBcTableG1VMps![0], closeTo(900.0, 1e-9));
      expect(ammo.multiBcTableG1Bc![0], closeTo(0.45, 1e-9));
    });

    test('empty table → null Float64Lists', () {
      final s = AmmoWizardFormState.fromAmmo(initial: null, caliberInch: 0.308)
          .copyWith(
            name: 'x',
            weightRaw: 175.0,
            lengthRaw: 38.0,
            mvRaw: 800.0,
            dragType: DragType.g1,
            useMultiBcG1: true,
            multiBcG1Table: [],
          );
      final ammo = s.buildAmmo(null);
      expect(ammo.multiBcTableG1VMps, isNull);
      expect(ammo.multiBcTableG1Bc, isNull);
    });
  });

  group('AmmoWizardFormState.buildAmmo — edits existing ammo', () {
    test('mutates and returns the initial Ammo object', () {
      final existing = _make308();
      final id = existing.id;
      final s = AmmoWizardFormState.fromAmmo(
        initial: existing,
        caliberInch: null,
      ).copyWith(name: 'Renamed');
      final result = s.buildAmmo(existing);
      expect(identical(result, existing), true);
      expect(result.name, 'Renamed');
      expect(result.id, id);
    });
  });

  group('AmmoWizardFormState.buildAmmo — powder sens table encoding', () {
    test('table encoded to Float64Lists', () {
      final s = AmmoWizardFormState.fromAmmo(initial: null, caliberInch: 0.308)
          .copyWith(
            name: 'x',
            weightRaw: 175.0,
            lengthRaw: 38.0,
            mvRaw: 800.0,
            bcG1: 0.4,
            usePowderSensitivity: true,
            powderSensTable: [
              (tempC: -10.0, vMps: 790.0),
              (tempC: 15.0, vMps: 800.0),
            ],
          );
      final ammo = s.buildAmmo(null);
      expect(ammo.powderSensitivityTC, isNotNull);
      expect(ammo.powderSensitivityTC![0], closeTo(-10.0, 1e-9));
      expect(ammo.powderSensitivityVMps![1], closeTo(800.0, 1e-9));
    });
  });

  group(
    'AmmoWizardFormState.buildAmmo — vendor/projectileName empty → null',
    () {
      test('empty vendor stored as null', () {
        final s =
            AmmoWizardFormState.fromAmmo(
              initial: null,
              caliberInch: 0.308,
            ).copyWith(
              name: 'x',
              vendor: '',
              weightRaw: 175.0,
              lengthRaw: 38.0,
              mvRaw: 800.0,
              bcG1: 0.4,
            );
        expect(s.buildAmmo(null).vendor, isNull);
      });

      test('empty projectileName stored as null', () {
        final s =
            AmmoWizardFormState.fromAmmo(
              initial: null,
              caliberInch: 0.308,
            ).copyWith(
              name: 'x',
              projectileName: '',
              weightRaw: 175.0,
              lengthRaw: 38.0,
              mvRaw: 800.0,
              bcG1: 0.4,
            );
        expect(s.buildAmmo(null).projectileName, isNull);
      });
    },
  );
} // end main
