// Unit tests for BallisticsService (Phase 1).
//
// Requires the native FFI library to be built:
//   make native
//   flutter test test/core/services/ballistics_service_test.dart

import 'package:test/test.dart';
import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/services/ballistics_service_impl.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Test fixtures ────────────────────────────────────────────────────────────

/// Builds an in-memory Ammo entity — no OB store required.
Ammo _makeAmmo({
  double muzzleVelocityMps = 800.0,
  double zeroDistanceMeter = 100.0,
  double powderSensitivityFrac = 0.0,
  bool usePowderSensitivity = false,
  bool zeroUseDiffPowderTemperature = false,
  double zeroPowderTemperatureC = 15.0,
}) => Ammo()
  ..name = 'Test .308 175gr'
  ..dragTypeValue = 'g7'
  ..weightGrain = 175.0
  ..caliberInch = 0.308
  ..lengthInch = 1.220
  ..bcG7 = 0.475
  ..muzzleVelocityMps = muzzleVelocityMps
  ..muzzleVelocityTemperatureC = 15.0
  ..powderSensitivityFrac = powderSensitivityFrac
  ..usePowderSensitivity = usePowderSensitivity
  ..zeroDistanceMeter = zeroDistanceMeter
  ..zeroTemperatureC = 15.0
  ..zeroPressurehPa = 1013.25
  ..zeroAltitudeMeter = 0.0
  ..zeroHumidityFrac = 0.0
  ..zeroPowderTemperatureC = zeroPowderTemperatureC
  ..zeroUseDiffPowderTemperature = zeroUseDiffPowderTemperature;

/// Builds an in-memory Weapon entity.
Weapon _makeWeapon() => Weapon()
  ..name = 'Test Rifle'
  ..caliberInch = 0.308
  ..twistInch = 11.0;

/// Builds an in-memory Sight entity.
Sight _makeSight() => Sight()
  ..name = 'Test Scope'
  ..sightHeightInch = 1.496; // 38 mm ≈ 1.496 in

/// Assembles a Profile with in-memory ToOne relations.
Profile _makeProfile({Ammo? ammo, Weapon? weapon, Sight? sight}) {
  final p = Profile()..name = 'Test Profile';
  p.ammo.target = ammo ?? _makeAmmo();
  p.weapon.target = weapon ?? _makeWeapon();
  p.sight.target = sight ?? _makeSight();
  return p;
}

/// Builds a ShootingConditions entity with sensible defaults.
ShootingConditions _makeConditions({
  double targetM = 300.0,
  double tempC = 15.0,
  double altM = 0.0,
  double pressHPa = 1013.25,
  double humidity = 0.0,
  double powderTempC = 15.0,
  double windSpeedMps = 0.0,
  double windDirectionDeg = 0.0,
}) => ShootingConditions()
  ..distanceMeter = targetM
  ..temperatureC = tempC
  ..altitudeMeter = altM
  ..pressurehPa = pressHPa
  ..humidityFrac = humidity
  ..powderTemperatureC = powderTempC
  ..windSpeedMps = windSpeedMps
  ..windDirectionDeg = windDirectionDeg
  ..lookAngleRad = 0.0
  ..usePowderSensitivity = false
  ..useDiffPowderTemp = false
  ..useCoriolis = false;

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late BallisticsService service;

  setUp(() {
    service = BallisticsServiceImpl();
  });

  group('BallisticsService — calculateTable', () {
    test('returns non-empty trajectory for standard profile', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(),
        const TableCalcOptions(stepM: 100),
      );

      expect(result.hitResult.trajectory, isNotEmpty);
      expect(result.zeroElevationRad, isNot(0.0));
    });

    test('trajectory starts near zero distance', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(),
        const TableCalcOptions(stepM: 100),
      );

      final firstPoint = result.hitResult.trajectory.first;
      expect(firstPoint.distance.in_(Unit.meter), closeTo(0.0, 1.0));
    });

    test('trajectory extends to ~2000m', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(),
        const TableCalcOptions(stepM: 100),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.distance.in_(Unit.meter), greaterThan(1900));
    });

    test('step size affects number of trajectory points', () async {
      final profile = _makeProfile();
      final cond = _makeConditions();

      final fine = await service.calculateTable(
        profile,
        cond,
        const TableCalcOptions(stepM: 1.0),
      );
      final coarse = await service.calculateTable(
        profile,
        cond,
        const TableCalcOptions(stepM: 100.0),
      );

      expect(
        fine.hitResult.trajectory.length,
        greaterThan(coarse.hitResult.trajectory.length),
      );
    });

    test('repeated call with same profile reuses cached zero', () async {
      final profile = _makeProfile();
      final cond = _makeConditions();

      final first = await service.calculateTable(
        profile,
        cond,
        const TableCalcOptions(stepM: 100),
      );
      final second = await service.calculateTable(
        profile,
        cond,
        const TableCalcOptions(stepM: 100),
      );

      expect(
        second.hitResult.trajectory.length,
        equals(first.hitResult.trajectory.length),
      );
      expect(second.zeroElevationRad, closeTo(first.zeroElevationRad, 1e-9));
    });

    test('velocity decreases along trajectory', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(),
        const TableCalcOptions(stepM: 100),
      );

      final traj = result.hitResult.trajectory;
      for (var i = 1; i < traj.length; i++) {
        expect(
          traj[i].velocity.in_(Unit.mps),
          lessThan(traj[i - 1].velocity.in_(Unit.mps)),
          reason: 'Velocity should decrease at point $i',
        );
      }
    });

    test('zero elevation is reasonable for 100m zero', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(),
        const TableCalcOptions(stepM: 100),
      );

      expect(result.zeroElevationRad, greaterThan(0.0));
      expect(result.zeroElevationRad, lessThan(0.01));
    });
  });

  group('BallisticsService — calculateForTarget', () {
    test('returns non-empty trajectory', () async {
      final result = await service.calculateForTarget(
        _makeProfile(),
        _makeConditions(targetM: 300.0),
        const TargetCalcOptions(targetDistM: 300.0, stepM: 10.0),
      );

      expect(result.hitResult.trajectory, isNotEmpty);
      expect(result.zeroElevationRad, isNot(0.0));
    });

    test('trajectory extends to target distance', () async {
      final result = await service.calculateForTarget(
        _makeProfile(),
        _makeConditions(targetM: 500.0),
        const TargetCalcOptions(targetDistM: 500.0, stepM: 10.0),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.distance.in_(Unit.meter), closeTo(500.0, 2.0));
    });

    test('target shot has hold applied (relative angle set)', () async {
      final result = await service.calculateForTarget(
        _makeProfile(),
        _makeConditions(targetM: 300.0),
        const TargetCalcOptions(targetDistM: 300.0, stepM: 10.0),
      );

      final holdRad = result.hitResult.shot.relativeAngle.in_(Unit.radian);
      expect(holdRad, isNot(0.0));
    });

    test('repeated call with same profile reuses cached zero', () async {
      final profile = _makeProfile();
      final cond = _makeConditions(targetM: 300.0);
      const opts = TargetCalcOptions(targetDistM: 300.0, stepM: 10.0);

      final first = await service.calculateForTarget(profile, cond, opts);
      final second = await service.calculateForTarget(profile, cond, opts);

      expect(
        second.hitResult.trajectory.length,
        equals(first.hitResult.trajectory.length),
      );
      expect(second.zeroElevationRad, closeTo(first.zeroElevationRad, 1e-9));
    });

    test('different target distances produce different results', () async {
      final short = await service.calculateForTarget(
        _makeProfile(),
        _makeConditions(targetM: 200.0),
        const TargetCalcOptions(targetDistM: 200.0, stepM: 10.0),
      );
      final long = await service.calculateForTarget(
        _makeProfile(),
        _makeConditions(targetM: 800.0),
        const TargetCalcOptions(targetDistM: 800.0, stepM: 10.0),
      );

      expect(
        long.hitResult.trajectory.length,
        greaterThan(short.hitResult.trajectory.length),
      );
    });
  });

  group('BallisticsService — wind effects', () {
    test('wind produces non-zero windage', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(windSpeedMps: 5.0, windDirectionDeg: 90.0),
        const TableCalcOptions(stepM: 100),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.windage.in_(Unit.centimeter).abs(), greaterThan(0.1));
    });

    test('no wind gives much less windage than with wind', () async {
      final profile = _makeProfile();

      final noWindResult = await service.calculateTable(
        profile,
        _makeConditions(windSpeedMps: 0.0),
        const TableCalcOptions(stepM: 100),
      );
      final windResult = await service.calculateTable(
        profile,
        _makeConditions(windSpeedMps: 10.0, windDirectionDeg: 90.0),
        const TableCalcOptions(stepM: 100),
      );

      final noWindLast = noWindResult.hitResult.trajectory.last;
      final windLast = windResult.hitResult.trajectory.last;
      expect(
        windLast.windage.in_(Unit.centimeter).abs(),
        greaterThan(noWindLast.windage.in_(Unit.centimeter).abs() * 5),
        reason: 'Wind should cause much more windage than spin drift alone',
      );
    });
  });

  group('BallisticsService — error handling', () {
    test('throws CalculationException for impossible zero distance', () async {
      final badAmmo = _makeAmmo(
        muzzleVelocityMps: 10.0, // extremely low
        zeroDistanceMeter: 3000.0, // impossible zero
      );

      expect(
        () => service.calculateTable(
          _makeProfile(ammo: badAmmo),
          _makeConditions(),
          const TableCalcOptions(stepM: 100),
        ),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('BallisticsService — powder sensitivity', () {
    test('powder sensitivity changes zero elevation', () async {
      final withSens = _makeAmmo(
        powderSensitivityFrac: 0.02,
        usePowderSensitivity: true,
        zeroUseDiffPowderTemperature: true,
        zeroPowderTemperatureC: 35.0, // hot powder at zero
      );
      final withoutSens = _makeAmmo(
        powderSensitivityFrac: 0.02,
        usePowderSensitivity: false,
        zeroPowderTemperatureC: 15.0,
      );

      final hotCond = _makeConditions(tempC: 35.0, powderTempC: 35.0);

      final r1 = await service.calculateTable(
        _makeProfile(ammo: withSens),
        hotCond,
        const TableCalcOptions(stepM: 100),
      );
      final r2 = await service.calculateTable(
        _makeProfile(ammo: withoutSens),
        hotCond,
        const TableCalcOptions(stepM: 100),
      );

      expect(r1.zeroElevationRad, isNot(closeTo(r2.zeroElevationRad, 1e-6)));
    });
  });

  group('BallisticsResult data class', () {
    test('stores hitResult and zeroElevationRad', () async {
      final result = await service.calculateTable(
        _makeProfile(),
        _makeConditions(),
        const TableCalcOptions(stepM: 100),
      );

      expect(result.hitResult, isNotNull);
      expect(result.zeroElevationRad, isA<double>());
      expect(result.zeroElevationRad.isFinite, isTrue);
    });
  });

  group('TableCalcOptions / TargetCalcOptions', () {
    test('TableCalcOptions defaults', () {
      const opts = TableCalcOptions();
      expect(opts.startM, 0);
      expect(opts.endM, 2000);
      expect(opts.stepM, 100);
    });

    test('TargetCalcOptions required targetDistM', () {
      const opts = TargetCalcOptions(targetDistM: 500.0);
      expect(opts.targetDistM, 500.0);
      expect(opts.stepM, 10.0);
    });
  });
}
