// flutter test test/features/sight_wizard/sight_wizard_notifier_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/home/sub_screens/sight_wizard_notifier.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

Sight _makeSight() => Sight()
  ..name = 'Test Scope'
  ..vendor = 'Vortex'
  ..sightHeight = Distance.millimeter(50.0)
  ..horizontalOffset = Distance.millimeter(5.0)
  ..focalPlane = FocalPlane.ffp
  ..verticalClickUnitValue = Unit.mil
  ..verticalClick = 0.1
  ..horizontalClickUnitValue = Unit.mil
  ..horizontalClick = 0.1
  ..minMagnification = 4.0
  ..maxMagnification = 16.0
  ..reticleImage = 'reticle_1';

void main() {
  // ── isValid ──────────────────────────────────────────────────────────────────
  group('SightWizardState.isValid', () {
    SightWizardState base({
      String name = 'My Scope',
      double vClickRaw = 0.1,
      double hClickRaw = 0.1,
      double minMagRaw = 4.0,
      double maxMagRaw = 16.0,
    }) => SightWizardState(
      name: name,
      vClickRaw: vClickRaw,
      hClickRaw: hClickRaw,
      minMagRaw: minMagRaw,
      maxMagRaw: maxMagRaw,
    );

    test('empty name → false', () => expect(base(name: '').isValid, isFalse));
    test(
      'whitespace name → false',
      () => expect(base(name: '  ').isValid, isFalse),
    );
    test(
      'vClickRaw = 0 → false',
      () => expect(base(vClickRaw: 0.0).isValid, isFalse),
    );
    test(
      'hClickRaw = 0 → false',
      () => expect(base(hClickRaw: 0.0).isValid, isFalse),
    );
    test(
      'minMagRaw = 0 → false',
      () => expect(base(minMagRaw: 0.0).isValid, isFalse),
    );
    test(
      'maxMagRaw = 0 → false',
      () => expect(base(maxMagRaw: 0.0).isValid, isFalse),
    );
    test('all valid → true', () => expect(base().isValid, isTrue));
  });

  // ── fromSight ────────────────────────────────────────────────────────────────
  group('SightWizardState.fromSight', () {
    test('null → defaults', () {
      final st = SightWizardState.fromSight(null);
      expect(st.name, '');
      expect(st.vendor, '');
      expect(st.sightHeightRaw, 0.0);
      expect(st.horizontalOffsetRaw, 0.0);
      expect(st.focalPlane, FocalPlane.ffp);
      expect(
        st.vClickRaw,
        closeTo(Angular.mil(0.1).in_(FC.adjustment.rawUnit), 0.0001),
      );
      expect(st.vClickUnit, Unit.mil);
      expect(
        st.hClickRaw,
        closeTo(Angular.mil(0.1).in_(FC.adjustment.rawUnit), 0.0001),
      );
      expect(st.hClickUnit, Unit.mil);
      expect(st.minMagRaw, 1.0);
      expect(st.maxMagRaw, 1.0);
      expect(st.reticleImage, isNull);
      expect(st.initial, isNull);
    });

    test('existing sight → state matches', () {
      final s = _makeSight();
      final st = SightWizardState.fromSight(s);
      expect(st.name, 'Test Scope');
      expect(st.vendor, 'Vortex');
      expect(
        st.sightHeightRaw,
        closeTo(Distance.millimeter(50.0).in_(FC.sightHeight.rawUnit), 0.001),
      );
      expect(
        st.horizontalOffsetRaw,
        closeTo(Distance.millimeter(5.0).in_(FC.sightHeight.rawUnit), 0.001),
      );
      expect(st.focalPlane, FocalPlane.ffp);
      expect(st.vClickUnit, Unit.mil);
      expect(st.vClickRaw, closeTo(0.1, 0.0001));
      expect(st.hClickUnit, Unit.mil);
      expect(st.hClickRaw, closeTo(0.1, 0.0001));
      expect(st.minMagRaw, 4.0);
      expect(st.maxMagRaw, 16.0);
      expect(st.reticleImage, 'reticle_1');
      expect(st.initial, same(s));
    });

    test('minMagnification = 0 on entity → defaults to 1.0', () {
      final s = Sight()
        ..name = 'Scope'
        ..verticalClickUnitValue = Unit.mil
        ..verticalClick = 0.1
        ..horizontalClickUnitValue = Unit.mil
        ..horizontalClick = 0.1
        ..minMagnification = 0.0
        ..maxMagnification = 0.0;
      final st = SightWizardState.fromSight(s);
      expect(st.minMagRaw, 1.0);
      expect(st.maxMagRaw, 1.0);
    });
  });

  // ── buildSight ───────────────────────────────────────────────────────────────
  group('SightWizardState.buildSight', () {
    test('new sight — correct fields set via extension setters', () {
      final st = SightWizardState(
        name: 'New Scope',
        vendor: 'Vortex',
        sightHeightRaw: Distance.millimeter(50.0).in_(FC.sightHeight.rawUnit),
        horizontalOffsetRaw: Distance.millimeter(
          5.0,
        ).in_(FC.sightHeight.rawUnit),
        focalPlane: FocalPlane.sfp,
        vClickRaw: Angular.mil(0.1).in_(FC.adjustment.rawUnit),
        vClickUnit: Unit.mil,
        hClickRaw: Angular.mil(0.05).in_(FC.adjustment.rawUnit),
        hClickUnit: Unit.mil,
        minMagRaw: 4.0,
        maxMagRaw: 16.0,
        reticleImage: 'reticle_1',
      );
      final s = st.buildSight();
      expect(s.name, 'New Scope');
      expect(s.vendor, 'Vortex');
      expect(s.sightHeight.in_(Unit.millimeter), closeTo(50.0, 0.01));
      expect(s.horizontalOffset.in_(Unit.millimeter), closeTo(5.0, 0.01));
      expect(s.focalPlane, FocalPlane.sfp);
      expect(s.focalPlaneValue, 'sfp');
      expect(s.verticalClickUnitValue, Unit.mil);
      expect(s.verticalClick, closeTo(0.1, 0.0001));
      expect(s.horizontalClickUnitValue, Unit.mil);
      expect(s.horizontalClick, closeTo(0.05, 0.0001));
      expect(s.minMagnification, 4.0);
      expect(s.maxMagnification, 16.0);
      expect(s.reticleImage, 'reticle_1');
    });

    test('edit mode — returns same identity as initial', () {
      final original = _makeSight();
      final st = SightWizardState.fromSight(original);
      final result = st.buildSight();
      expect(identical(result, original), isTrue);
    });

    test('fromSight → buildSight roundtrip preserves click values', () {
      final original = _makeSight();
      final st = SightWizardState.fromSight(original);
      final rebuilt = st.buildSight();
      expect(rebuilt.verticalClick, closeTo(original.verticalClick, 0.0001));
      expect(
        rebuilt.horizontalClick,
        closeTo(original.horizontalClick, 0.0001),
      );
      expect(rebuilt.verticalClickUnit, original.verticalClickUnit);
    });

    test('LWIR focal plane stored correctly', () {
      final st = SightWizardState(
        name: 'Thermal',
        focalPlane: FocalPlane.lwir,
        vClickRaw: 0.1,
        hClickRaw: 0.1,
        minMagRaw: 2.0,
        maxMagRaw: 8.0,
      );
      final s = st.buildSight();
      expect(s.focalPlane, FocalPlane.lwir);
      expect(s.focalPlaneValue, 'lwir');
    });

    test('empty vendor → null on entity', () {
      final st = SightWizardState(
        name: 'Scope',
        vendor: '',
        vClickRaw: 0.1,
        hClickRaw: 0.1,
        minMagRaw: 4.0,
        maxMagRaw: 16.0,
      );
      expect(st.buildSight().vendor, isNull);
    });

    test('null reticleImage preserved', () {
      final st = SightWizardState(
        name: 'Scope',
        vClickRaw: 0.1,
        hClickRaw: 0.1,
        minMagRaw: 4.0,
        maxMagRaw: 16.0,
      );
      expect(st.buildSight().reticleImage, isNull);
    });
  });
}
