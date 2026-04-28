//   flutter test test/features/ammo_wizard/ammo_wizard_notifier_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_notifier.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

AmmoWizardState _validG1({
  String name = 'Test .308',
  double caliberRaw = 7.82,
  double? weightRaw = 175.0,
  double? lengthRaw = 31.0,
  double? mvRaw = 800.0,
  bool useMultiBcG1 = false,
  double? bcG1 = 0.475,
  List<({double vMps, double bc})>? multiBcG1Table,
}) => AmmoWizardState(
  name: name,
  caliberRaw: caliberRaw,
  weightRaw: weightRaw,
  lengthRaw: lengthRaw,
  mvRaw: mvRaw,
  dragType: DragType.g1,
  useMultiBcG1: useMultiBcG1,
  bcG1: bcG1,
  multiBcG1Table: multiBcG1Table,
);

AmmoWizardState _validG7({
  bool useMultiBcG7 = false,
  double? bcG7 = 0.317,
  List<({double vMps, double bc})>? multiBcG7Table,
}) => AmmoWizardState(
  name: 'Test .308 G7',
  caliberRaw: 7.82,
  weightRaw: 175.0,
  lengthRaw: 31.0,
  mvRaw: 800.0,
  dragType: DragType.g7,
  useMultiBcG7: useMultiBcG7,
  bcG7: bcG7,
  multiBcG7Table: multiBcG7Table,
);

AmmoWizardState _validCustom({
  List<({double mach, double cd})>? customDragTable = const [
    (mach: 0.5, cd: 0.284),
  ],
}) => AmmoWizardState(
  name: 'Custom Drag',
  caliberRaw: 7.82,
  weightRaw: 175.0,
  lengthRaw: 31.0,
  mvRaw: 800.0,
  dragType: DragType.custom,
  customDragTable: customDragTable,
);

Ammo _makeAmmo() {
  final a = Ammo()
    ..name = 'Saved .308'
    ..vendor = 'Hornady'
    ..projectileName = '175gr BTHP'
    ..dragType = DragType.g7
    ..bcG7 = 0.317
    ..caliber = Distance.inch(0.308)
    ..weight = Weight.grain(175.0)
    ..length = Distance.inch(1.220)
    ..mv = Velocity.mps(790.0)
    ..mvTemperature = Temperature.celsius(21.0)
    ..zeroDistance = Distance.meter(100.0)
    ..zeroTemperature = Temperature.celsius(15.0)
    ..zeroPressure = Pressure.hPa(1013.0)
    ..zeroHumidityFrac = 0.5
    ..zeroAltitude = Distance.meter(50.0)
    ..zeroLookAngle = Angular.degree(2.0)
    ..usePowderSensitivity = true
    ..powderSensitivity = Ratio.fraction(0.0015)
    ..zeroUseDiffPowderTemperature = true
    ..zeroPowderTemp = Temperature.celsius(10.0)
    ..zeroUseCoriolis = true
    ..zeroLatitude = Angular.degree(48.5)
    ..zeroAzimuth = Angular.degree(180.0)
    ..zeroOffsetX = 0.5
    ..zeroOffsetXUnitValue = Unit.mil
    ..zeroOffsetY = -0.3
    ..zeroOffsetYUnitValue = Unit.mil;
  return a;
}

// ── isValid ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('AmmoWizardState.isValid — G1 single BC', () {
    test('true for fully valid state', () {
      expect(_validG1().isValid, isTrue);
    });

    test('false when name is empty', () {
      expect(_validG1(name: '').isValid, isFalse);
    });

    test('false when name is whitespace only', () {
      expect(_validG1(name: '   ').isValid, isFalse);
    });

    test('false when caliberRaw is zero', () {
      expect(_validG1(caliberRaw: 0.0).isValid, isFalse);
    });

    test('false when caliberRaw is negative', () {
      expect(_validG1(caliberRaw: -1.0).isValid, isFalse);
    });

    test('false when weightRaw is null', () {
      expect(_validG1(weightRaw: null).isValid, isFalse);
    });

    test('false when weightRaw is zero', () {
      expect(_validG1(weightRaw: 0.0).isValid, isFalse);
    });

    test('false when lengthRaw is null', () {
      expect(_validG1(lengthRaw: null).isValid, isFalse);
    });

    test('false when mvRaw is null', () {
      expect(_validG1(mvRaw: null).isValid, isFalse);
    });

    test('false when mvRaw is zero', () {
      expect(_validG1(mvRaw: 0.0).isValid, isFalse);
    });

    test('false when bcG1 is null', () {
      expect(_validG1(bcG1: null).isValid, isFalse);
    });

    test('false when bcG1 is zero', () {
      expect(_validG1(bcG1: 0.0).isValid, isFalse);
    });
  });

  group('AmmoWizardState.isValid — G1 multi BC', () {
    test('false when multiBcG1Table is null', () {
      expect(
        _validG1(useMultiBcG1: true, bcG1: null, multiBcG1Table: null).isValid,
        isFalse,
      );
    });

    test('false when multiBcG1Table is empty', () {
      expect(
        _validG1(useMultiBcG1: true, bcG1: null, multiBcG1Table: []).isValid,
        isFalse,
      );
    });

    test('true when multiBcG1Table has entries', () {
      expect(
        _validG1(
          useMultiBcG1: true,
          bcG1: null,
          multiBcG1Table: [(vMps: 800.0, bc: 0.475)],
        ).isValid,
        isTrue,
      );
    });
  });

  group('AmmoWizardState.isValid — G7', () {
    test('true for valid G7 single BC', () {
      expect(_validG7().isValid, isTrue);
    });

    test('false when bcG7 is null', () {
      expect(_validG7(bcG7: null).isValid, isFalse);
    });

    test('false when multiBcG7Table is empty', () {
      expect(
        _validG7(useMultiBcG7: true, bcG7: null, multiBcG7Table: []).isValid,
        isFalse,
      );
    });

    test('true when multiBcG7Table has entries', () {
      expect(
        _validG7(
          useMultiBcG7: true,
          bcG7: null,
          multiBcG7Table: [(vMps: 800.0, bc: 0.317)],
        ).isValid,
        isTrue,
      );
    });
  });

  group('AmmoWizardState.isValid — custom drag', () {
    test('true when customDragTable has entries', () {
      expect(_validCustom().isValid, isTrue);
    });

    test('false when customDragTable is null', () {
      expect(_validCustom(customDragTable: null).isValid, isFalse);
    });

    test('false when customDragTable is empty', () {
      expect(_validCustom(customDragTable: []).isValid, isFalse);
    });
  });

  // ── fromAmmo ────────────────────────────────────────────────────────────────

  group('AmmoWizardState.fromAmmo — new ammo (null)', () {
    test('default name is empty', () {
      final s = AmmoWizardState.fromAmmo(null, null);
      expect(s.name, '');
    });

    test('caliberRaw uses provided caliberInch', () {
      final s = AmmoWizardState.fromAmmo(null, 0.308);
      expect(
        s.caliberRaw,
        closeTo(Distance.inch(0.308).in_(Unit.millimeter), 0.001),
      );
    });

    test('caliberRaw uses FC minimum when caliberInch is null', () {
      final s = AmmoWizardState.fromAmmo(null, null);
      expect(s.caliberRaw, greaterThan(0));
    });

    test('weight, length, mv are null', () {
      final s = AmmoWizardState.fromAmmo(null, null);
      expect(s.weightRaw, isNull);
      expect(s.lengthRaw, isNull);
      expect(s.mvRaw, isNull);
    });
  });

  group('AmmoWizardState.fromAmmo — edit existing ammo', () {
    late AmmoWizardState s;

    setUp(() => s = AmmoWizardState.fromAmmo(_makeAmmo(), null));

    test('reads name and vendor', () {
      expect(s.name, 'Saved .308');
      expect(s.vendor, 'Hornady');
      expect(s.projectileName, '175gr BTHP');
    });

    test('converts caliberInch to mm', () {
      expect(
        s.caliberRaw,
        closeTo(Distance.inch(0.308).in_(Unit.millimeter), 0.001),
      );
    });

    test('reads weight in grain (rawUnit identity)', () {
      expect(s.weightRaw, closeTo(175.0, 0.01));
    });

    test('converts lengthInch to mm', () {
      expect(
        s.lengthRaw,
        closeTo(Distance.inch(1.220).in_(Unit.millimeter), 0.01),
      );
    });

    test('reads mvRaw in m/s', () {
      expect(s.mvRaw, closeTo(790.0, 0.01));
    });

    test('reads mvTempRaw in celsius', () {
      expect(s.mvTempRaw, closeTo(21.0, 0.01));
    });

    test('reads zero fields', () {
      expect(s.zeroDistRaw, closeTo(100.0, 0.01));
      expect(s.zeroTempRaw, closeTo(15.0, 0.01));
      expect(s.zeroPressureRaw, closeTo(1013.0, 0.5));
      expect(s.zeroHumidityRaw, closeTo(0.5, 0.001));
      expect(s.zeroAltRaw, closeTo(50.0, 0.01));
      expect(s.zeroLookAngleRaw, closeTo(2.0, 0.01));
    });

    test('reads powder sensitivity fields', () {
      expect(s.usePowderSensitivity, isTrue);
      expect(s.powderSensRaw, closeTo(0.0015, 0.0001));
      expect(s.zeroUseDiffPowderTemp, isTrue);
      expect(s.zeroPowderTempRaw, closeTo(10.0, 0.01));
    });

    test('reads coriolis fields', () {
      expect(s.zeroUseCoriolis, isTrue);
      expect(s.zeroLatitudeRaw, closeTo(48.5, 0.01));
      expect(s.zeroAzimuthRaw, closeTo(180.0, 0.01));
    });

    test('reads drag type and G7 BC', () {
      expect(s.dragType, DragType.g7);
      expect(s.bcG7, closeTo(0.317, 0.001));
    });

    test('decodes multiBcG7Table from Float64Lists', () {
      final a = Ammo()
        ..name = 'BC Table'
        ..caliber = Distance.inch(0.308)
        ..weight = Weight.grain(175.0)
        ..length = Distance.inch(1.22)
        ..mv = Velocity.mps(800.0)
        ..mvTemperature = Temperature.celsius(15.0)
        ..zeroDistance = Distance.meter(100.0)
        ..zeroTemperature = Temperature.celsius(15.0)
        ..zeroPressure = Pressure.hPa(1013.0)
        ..zeroHumidityFrac = 0.0
        ..zeroAltitude = Distance.meter(0.0)
        ..zeroLookAngle = Angular.degree(0.0)
        ..zeroPowderTemp = Temperature.celsius(15.0)
        ..zeroLatitude = Angular.degree(0.0)
        ..zeroAzimuth = Angular.degree(0.0)
        ..dragType = DragType.g7
        ..useMultiBcG7 = true
        ..bcG7 = 0.317
        ..multiBcTableG7VMps = Float64List.fromList([900.0, 800.0])
        ..multiBcTableG7Bc = Float64List.fromList([0.30, 0.32]);
      final st = AmmoWizardState.fromAmmo(a, null);
      expect(st.multiBcG7Table, isNotNull);
      expect(st.multiBcG7Table!.length, 2);
      expect(st.multiBcG7Table![0].vMps, 900.0);
      expect(st.multiBcG7Table![0].bc, 0.30);
    });
  });

  // ── buildAmmo ────────────────────────────────────────────────────────────────

  group('AmmoWizardState.buildAmmo — roundtrip', () {
    test('sets name and vendor', () {
      final s = _validG1().copyWith(
        vendor: 'Federal',
        projectileName: 'Sierra',
      );
      final a = s.buildAmmo();
      expect(a.name, 'Test .308');
      expect(a.vendor, 'Federal');
      expect(a.projectileName, 'Sierra');
    });

    test('trims whitespace from name', () {
      final s = _validG1(name: '  308 Win  ');
      final a = s.buildAmmo();
      expect(a.name, '308 Win');
    });

    test('stores null vendor as null (empty vendor → null)', () {
      final s = _validG1().copyWith(vendor: '');
      final a = s.buildAmmo();
      expect(a.vendor, isNull);
    });

    test('converts caliberRaw (mm) to caliberInch', () {
      final s = _validG1(caliberRaw: 7.82);
      final a = s.buildAmmo();
      expect(a.caliberInch, closeTo(7.82 / 25.4, 0.001));
    });

    test('stores weightRaw (grain) as weightGrain — identity', () {
      final a = _validG1(weightRaw: 175.0).buildAmmo();
      expect(a.weightGrain, closeTo(175.0, 0.01));
    });

    test('stores weightGrain as -1 when weightRaw is null', () {
      final a = _validG1(weightRaw: null).buildAmmo();
      expect(a.weightGrain, -1.0);
    });

    test('converts lengthRaw (mm) to lengthInch', () {
      final a = _validG1(lengthRaw: 31.0).buildAmmo();
      expect(a.lengthInch, closeTo(31.0 / 25.4, 0.01));
    });

    test('stores lengthInch as -1 when lengthRaw is null', () {
      final a = _validG1(lengthRaw: null).buildAmmo();
      expect(a.lengthInch, -1.0);
    });

    test('stores mvRaw (m/s) as muzzleVelocityMps — identity', () {
      final a = _validG1(mvRaw: 800.0).buildAmmo();
      expect(a.muzzleVelocityMps, closeTo(800.0, 0.01));
    });

    test('stores muzzleVelocityMps as -1 when mvRaw is null', () {
      final a = _validG1(mvRaw: null).buildAmmo();
      expect(a.muzzleVelocityMps, -1.0);
    });

    test('stores bcG1 directly', () {
      final a = _validG1(bcG1: 0.475).buildAmmo();
      expect(a.bcG1, closeTo(0.475, 1e-9));
    });

    test('stores bcG1 as -1 when null', () {
      final a = _validG1(bcG1: null).buildAmmo();
      expect(a.bcG1, -1.0);
    });

    test('encodes multiBcG1Table to Float64Lists', () {
      final table = [(vMps: 900.0, bc: 0.45), (vMps: 800.0, bc: 0.47)];
      final a = _validG1(
        useMultiBcG1: true,
        bcG1: null,
        multiBcG1Table: table,
      ).buildAmmo();
      expect(a.multiBcTableG1VMps, isNotNull);
      expect(a.multiBcTableG1VMps!.length, 2);
      expect(a.multiBcTableG1VMps![0], closeTo(900.0, 1e-9));
      expect(a.multiBcTableG1Bc![0], closeTo(0.45, 1e-9));
    });

    test('clears G1 table lists when table is null', () {
      final a = _validG1(useMultiBcG1: false, multiBcG1Table: null).buildAmmo();
      expect(a.multiBcTableG1VMps, isNull);
      expect(a.multiBcTableG1Bc, isNull);
    });

    test('encodes customDragTable to Float64Lists', () {
      final a = _validCustom(
        customDragTable: [(mach: 0.5, cd: 0.284), (mach: 1.0, cd: 0.415)],
      ).buildAmmo();
      expect(a.customDragTableMach, isNotNull);
      expect(a.customDragTableMach!.length, 2);
      expect(a.customDragTableMach![0], closeTo(0.5, 1e-9));
      expect(a.customDragTableCd![1], closeTo(0.415, 1e-9));
    });

    test('clears custom table when null', () {
      final a = _validCustom(customDragTable: null).buildAmmo();
      expect(a.customDragTableMach, isNull);
      expect(a.customDragTableCd, isNull);
    });

    test('encodes zero fields correctly', () {
      final s = AmmoWizardState(
        name: 'Test',
        caliberRaw: 7.82,
        weightRaw: 175.0,
        lengthRaw: 31.0,
        mvRaw: 800.0,
        dragType: DragType.g1,
        bcG1: 0.475,
        zeroDistRaw: 100.0,
        zeroTempRaw: 20.0,
        zeroPressureRaw: 1013.0,
        zeroHumidityRaw: 0.5,
        zeroAltRaw: 150.0,
        zeroLookAngleRaw: 5.0,
      );
      final a = s.buildAmmo();
      expect(a.zeroDistance.in_(Unit.meter), closeTo(100.0, 0.01));
      expect(a.zeroTemperature.in_(Unit.celsius), closeTo(20.0, 0.01));
      expect(a.zeroPressure.in_(Unit.hPa), closeTo(1013.0, 0.5));
      expect(a.zeroHumidityFrac, closeTo(0.5, 0.001));
      expect(a.zeroAltitude.in_(Unit.meter), closeTo(150.0, 0.01));
      expect(a.zeroLookAngle.in_(Unit.degree), closeTo(5.0, 0.01));
    });

    test('encodes powder sensitivity table', () {
      final powderTable = [
        (tempC: -10.0, vMps: 790.0),
        (tempC: 20.0, vMps: 800.0),
      ];
      final s = AmmoWizardState(
        name: 'Test',
        caliberRaw: 7.82,
        weightRaw: 175.0,
        lengthRaw: 31.0,
        mvRaw: 800.0,
        dragType: DragType.g1,
        bcG1: 0.475,
        usePowderSensitivity: true,
        powderSensTable: powderTable,
      );
      final a = s.buildAmmo();
      expect(a.powderSensitivityTC, isNotNull);
      expect(a.powderSensitivityTC!.length, 2);
      expect(a.powderSensitivityTC![0], -10.0);
      expect(a.powderSensitivityVMps![1], closeTo(800.0, 0.01));
    });

    test('stores dragType', () {
      expect(_validG7().buildAmmo().dragType, DragType.g7);
      expect(_validCustom().buildAmmo().dragType, DragType.custom);
    });

    test('edit mode reuses the initial Ammo object', () {
      final original = _makeAmmo();
      final s = AmmoWizardState.fromAmmo(
        original,
        null,
      ).copyWith(name: 'Updated');
      final a = s.buildAmmo();
      expect(identical(a, original), isTrue);
      expect(a.name, 'Updated');
    });
  });
}
