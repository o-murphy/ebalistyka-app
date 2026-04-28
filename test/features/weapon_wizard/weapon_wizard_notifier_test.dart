// flutter test test/features/weapon_wizard/weapon_wizard_notifier_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/home/sub_screens/weapon_wizard_notifier.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

Weapon _makeWeapon() => Weapon()
  ..name = 'Test Rifle'
  ..vendor = 'Remington'
  ..caliberName = '.308 Win'
  ..caliber = Distance.inch(0.308)
  ..twist = Distance.inch(10.0)
  ..barrelLength = Distance.inch(24.0);

void main() {
  // ── isValid ──────────────────────────────────────────────────────────────────
  group('WeaponWizardState.isValid', () {
    test('empty name → false', () {
      expect(
        WeaponWizardState(name: '', caliberRaw: 7.82, twistRaw: 10.0).isValid,
        isFalse,
      );
    });

    test('whitespace-only name → false', () {
      expect(
        WeaponWizardState(name: '  ', caliberRaw: 7.82, twistRaw: 10.0).isValid,
        isFalse,
      );
    });

    test('caliberRaw ≤ 0 → false', () {
      expect(
        WeaponWizardState(
          name: 'Rifle',
          caliberRaw: 0.0,
          twistRaw: 10.0,
        ).isValid,
        isFalse,
      );
    });

    test('twistRaw < 0 → false', () {
      expect(
        WeaponWizardState(
          name: 'Rifle',
          caliberRaw: 7.82,
          twistRaw: -1.0,
        ).isValid,
        isFalse,
      );
    });

    test('twistRaw = 0 → valid', () {
      expect(
        WeaponWizardState(
          name: 'Rifle',
          caliberRaw: 7.82,
          twistRaw: 0.0,
        ).isValid,
        isTrue,
      );
    });

    test('all fields valid → true', () {
      expect(
        WeaponWizardState(
          name: 'Rifle',
          caliberRaw: 7.82,
          twistRaw: 10.0,
        ).isValid,
        isTrue,
      );
    });
  });

  // ── fromWeapon ───────────────────────────────────────────────────────────────
  group('WeaponWizardState.fromWeapon', () {
    test('null → defaults', () {
      final st = WeaponWizardState.fromWeapon(null);
      expect(st.name, '');
      expect(st.vendor, '');
      expect(st.caliberName, '');
      expect(
        st.caliberRaw,
        closeTo(Distance.inch(0.338).in_(FC.projectileDiameter.rawUnit), 0.001),
      );
      expect(st.twistRaw, FC.twist.minRaw);
      expect(st.rightHand, isTrue);
      expect(st.showExtraFields, isFalse);
      expect(st.barrelLengthRaw, isNull);
      expect(st.initial, isNull);
    });

    test('existing weapon → state matches', () {
      final w = _makeWeapon();
      final st = WeaponWizardState.fromWeapon(w);
      expect(st.name, 'Test Rifle');
      expect(st.vendor, 'Remington');
      expect(st.caliberName, '.308 Win');
      expect(
        st.caliberRaw,
        closeTo(Distance.inch(0.308).in_(FC.projectileDiameter.rawUnit), 0.001),
      );
      expect(
        st.twistRaw,
        closeTo(Distance.inch(10.0).in_(FC.twist.rawUnit), 0.001),
      );
      expect(st.rightHand, isTrue);
      expect(st.showExtraFields, isTrue);
      expect(
        st.barrelLengthRaw,
        closeTo(Distance.inch(24.0).in_(FC.barrelLength.rawUnit), 0.001),
      );
      expect(st.initial, same(w));
    });

    test('left-hand twist → rightHand=false, twistRaw is positive', () {
      final w = Weapon()
        ..name = 'LH Rifle'
        ..caliber = Distance.inch(0.308)
        ..twist = Distance.inch(-10.0);
      final st = WeaponWizardState.fromWeapon(w);
      expect(st.rightHand, isFalse);
      expect(st.twistRaw, closeTo(10.0, 0.001));
    });

    test('no barrel length → showExtraFields=false, barrelLengthRaw=null', () {
      final w = Weapon()
        ..name = 'Rifle'
        ..caliber = Distance.inch(0.308)
        ..twist = Distance.inch(10.0);
      final st = WeaponWizardState.fromWeapon(w);
      expect(st.showExtraFields, isFalse);
      expect(st.barrelLengthRaw, isNull);
    });
  });

  // ── buildWeapon ──────────────────────────────────────────────────────────────
  group('WeaponWizardState.buildWeapon', () {
    test('new weapon — correct fields via extension setters', () {
      final st = WeaponWizardState(
        name: 'New Rifle',
        vendor: 'Remington',
        caliberName: '.308 Win',
        caliberRaw: Distance.inch(0.308).in_(FC.projectileDiameter.rawUnit),
        twistRaw: Distance.inch(10.0).in_(FC.twist.rawUnit),
      );
      final w = st.buildWeapon();
      expect(w.name, 'New Rifle');
      expect(w.vendor, 'Remington');
      expect(w.caliberName, '.308 Win');
      expect(w.caliber.in_(Unit.inch), closeTo(0.308, 0.001));
      expect(w.twist.in_(Unit.inch), closeTo(10.0, 0.001));
      expect(w.isRightHandTwist, isTrue);
    });

    test('edit mode — returns same identity as initial', () {
      final original = _makeWeapon();
      final st = WeaponWizardState.fromWeapon(original);
      final result = st.buildWeapon();
      expect(identical(result, original), isTrue);
    });

    test('left-hand twist → negative twistInch', () {
      final st = WeaponWizardState(
        name: 'LH Rifle',
        caliberRaw: 7.82,
        twistRaw: 10.0,
        rightHand: false,
      );
      final w = st.buildWeapon();
      expect(w.twist.in_(Unit.inch), closeTo(-10.0, 0.001));
      expect(w.isRightHandTwist, isFalse);
    });

    test('showExtraFields=false → barrelLength is null (sentinel -1)', () {
      final st = WeaponWizardState(
        name: 'Rifle',
        caliberRaw: 7.82,
        twistRaw: 10.0,
        showExtraFields: false,
        barrelLengthRaw: 24.0,
      );
      final w = st.buildWeapon();
      expect(w.barrelLength, isNull);
      expect(w.barrelLengthInch, -1.0);
    });

    test('showExtraFields=true with barrelLengthRaw → barrelLength set', () {
      final st = WeaponWizardState(
        name: 'Rifle',
        caliberRaw: 7.82,
        twistRaw: 10.0,
        showExtraFields: true,
        barrelLengthRaw: Distance.inch(24.0).in_(FC.barrelLength.rawUnit),
      );
      final w = st.buildWeapon();
      expect(w.barrelLength?.in_(Unit.inch), closeTo(24.0, 0.001));
    });

    test('empty vendor → null on entity', () {
      final st = WeaponWizardState(
        name: 'Rifle',
        vendor: '',
        caliberRaw: 7.82,
        twistRaw: 10.0,
      );
      final w = st.buildWeapon();
      expect(w.vendor, isNull);
    });
  });
}
