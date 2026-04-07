// Unit tests for BallisticsService (Phase 1).
//
// Requires the native FFI library to be built:
//   make native
//   dart test test/services/ballistics_service_test.dart

import 'package:test/test.dart';
import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/services/ballistics_service_impl.dart';
import 'package:ebalistyka/core/models/cartridge.dart';
import 'package:ebalistyka/core/models/rifle.dart';
import 'package:ebalistyka/core/models/conditions_data.dart';
import 'package:ebalistyka/core/models/shot_profile.dart';
import 'package:ebalistyka/core/models/sight.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Test fixtures ────────────────────────────────────────────────────────────

/// Realistic .308 Win profile for testing.
ShotProfile _makeProfile() {
  final cartridge = Cartridge(
    name: 'Test .308',
    projectileName: 'Test 175gr',
    dragType: DragModelType.g7,
    weight: Weight.grain(175),
    diameter: Distance.millimeter(7.62),
    length: Distance.millimeter(31.0),
    coefRows: [CoeficientRow(bcCd: 0.475, mv: 0.0)],
    mv: Velocity.mps(800.0),
    powderTemp: Temperature.celsius(15.0),
    powderSensitivity: Ratio.fraction(0.0),
    zeroConditions: Conditions.withDefaults(distance: Distance.meter(100.0)),
  );
  final rifle = Rifle(
    name: 'Test Rifle',
    sightHeight: Distance.millimeter(38.0),
    twist: Distance.inch(11.0),
  );
  final sight = Sight(name: 'Test Scope');
  return ShotProfile(
    name: 'Test Shot',
    rifle: rifle,
    cartridge: cartridge,
    sight: sight,
  );
}

Conditions _makeConditions({
  double targetM = 300.0,
  double tempC = 15.0,
  double altM = 0.0,
  double pressHPa = 1013.25,
  double humidity = 0.0,
  double powderTempC = 15.0,
  List<WindData> winds = const [],
}) {
  return Conditions(
    atmo: AtmoData(
      altitude: Distance.meter(altM),
      temperature: Temperature.celsius(tempC),
      pressure: Pressure.hPa(pressHPa),
      humidity: humidity,
      powderTemp: Temperature.celsius(powderTempC),
    ),
    winds: winds,
    lookAngle: Angular.degree(0),
    distance: Distance.meter(targetM),
    usePowderSensitivity: false,
    useDiffPowderTemp: false,
    useCoriolis: false,
    latitudeDeg: null,
    azimuthDeg: null,
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late BallisticsService service;

  setUp(() {
    service = BallisticsServiceImpl();
  });

  group('BallisticsService — calculateTable', () {
    test('returns non-empty trajectory for standard profile', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();
      final result = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
      );

      expect(result.hitResult.trajectory, isNotEmpty);
      expect(result.zeroElevationRad, isNot(0.0));
    });

    test('trajectory starts near zero distance', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();
      final result = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
      );

      final firstPoint = result.hitResult.trajectory.first;
      expect(firstPoint.distance.in_(Unit.meter), closeTo(0.0, 1.0));
    });

    test('trajectory extends to ~2000m', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();
      final result = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.distance.in_(Unit.meter), greaterThan(1900));
    });

    test('step size affects number of trajectory points', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();

      final fine = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 1.0),
      );
      final coarse = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100.0),
      );

      expect(
        fine.hitResult.trajectory.length,
        greaterThan(coarse.hitResult.trajectory.length),
      );
    });

    test('cached zero elevation skips re-zeroing', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();

      // First call — computes zero elevation
      final first = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
      );

      // Second call — uses cached zero elevation
      final second = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
        cachedZeroElevRad: first.zeroElevationRad,
      );

      // Results should be equivalent
      expect(
        second.hitResult.trajectory.length,
        equals(first.hitResult.trajectory.length),
      );
      expect(second.zeroElevationRad, closeTo(first.zeroElevationRad, 1e-9));
    });

    test('velocity decreases along trajectory', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();
      final result = await service.calculateTable(
        profile,
        conditions,
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
      final profile = _makeProfile();
      final conditions = _makeConditions();
      final result = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
      );

      // Zero elevation should be a small positive angle (bullet rises to zero)
      final zeroElev = result.zeroElevationRad;
      expect(zeroElev, greaterThan(0.0));
      expect(zeroElev, lessThan(0.01)); // less than ~0.57 degrees
    });
  });

  group('BallisticsService — calculateForTarget', () {
    test('returns non-empty trajectory', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions(targetM: 300.0);
      final result = await service.calculateForTarget(
        profile,
        conditions,
        const TargetCalcOptions(targetDistM: 300.0, stepM: 10.0),
      );

      expect(result.hitResult.trajectory, isNotEmpty);
      expect(result.zeroElevationRad, isNot(0.0));
    });

    test('trajectory extends to target distance', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions(targetM: 500.0);
      final result = await service.calculateForTarget(
        profile,
        conditions,
        const TargetCalcOptions(targetDistM: 500.0, stepM: 10.0),
      );

      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.distance.in_(Unit.meter), closeTo(500.0, 2.0));
    });

    test('target shot has hold applied (relative angle set)', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions(targetM: 300.0);
      final result = await service.calculateForTarget(
        profile,
        conditions,
        const TargetCalcOptions(targetDistM: 300.0, stepM: 10.0),
      );

      // The shot should have a relative angle set (hold for target)
      final shot = result.hitResult.shot;
      final holdRad = shot.relativeAngle.in_(Unit.radian);
      // For 300m target with 100m zero, hold should be negative (bullet drops)
      expect(holdRad, isNot(0.0));
    });

    test('cached zero elevation gives same results', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions(targetM: 300.0);
      final opts = const TargetCalcOptions(targetDistM: 300.0, stepM: 10.0);

      final first = await service.calculateForTarget(profile, conditions, opts);
      final second = await service.calculateForTarget(
        profile,
        conditions,
        opts,
        cachedZeroElevRad: first.zeroElevationRad,
      );

      expect(
        second.hitResult.trajectory.length,
        equals(first.hitResult.trajectory.length),
      );
      expect(second.zeroElevationRad, closeTo(first.zeroElevationRad, 1e-9));
    });

    test('different target distances produce different results', () async {
      final profile = _makeProfile();

      final short = await service.calculateForTarget(
        profile,
        _makeConditions(targetM: 200.0),
        const TargetCalcOptions(targetDistM: 200.0, stepM: 10.0),
      );
      final long = await service.calculateForTarget(
        profile,
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
      final profile = _makeProfile();
      final conditions = _makeConditions(
        winds: [
          WindData(
            velocity: Velocity.mps(5.0),
            directionFrom: Angular.degree(90.0),
            untilDistance: Distance.meter(2000.0),
          ),
        ],
      );

      final result = await service.calculateTable(
        profile,
        conditions,
        const TableCalcOptions(stepM: 100),
      );

      // At long range, windage should be non-zero
      final lastPoint = result.hitResult.trajectory.last;
      expect(lastPoint.windage.in_(Unit.centimeter).abs(), greaterThan(0.1));
    });

    test('no wind gives much less windage than with wind', () async {
      final profile = _makeProfile();
      final noWindConditions = _makeConditions(winds: const []);
      final windConditions = _makeConditions(
        winds: [
          WindData(
            velocity: Velocity.mps(10.0),
            directionFrom: Angular.degree(90.0),
            untilDistance: Distance.meter(2000.0),
          ),
        ],
      );

      final noWindResult = await service.calculateTable(
        profile,
        noWindConditions,
        const TableCalcOptions(stepM: 100),
      );
      final windResult = await service.calculateTable(
        profile,
        windConditions,
        const TableCalcOptions(stepM: 100),
      );

      // At long range, wind should cause significantly more windage
      // than spin drift alone
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
    test('throws CalculationException for invalid profile', () async {
      // BC must be positive, zero MV will cause issues in zeroing
      final cartridge = Cartridge(
        name: 'Bad',
        projectileName: 'Bad',
        dragType: DragModelType.g7,
        weight: Weight.grain(1),
        diameter: Distance.millimeter(7.62),
        length: Distance.millimeter(31.0),
        coefRows: [CoeficientRow(bcCd: 0.001, mv: 0.0)],
        mv: Velocity.mps(10.0), // extremely low velocity
        powderTemp: Temperature.celsius(15.0),
        powderSensitivity: Ratio.fraction(0.0),
        zeroConditions: Conditions.withDefaults(
          distance: Distance.meter(3000.0), // impossible zero
        ),
      );
      final rifle = Rifle(
        name: 'Bad',
        sightHeight: Distance.millimeter(38.0),
        twist: Distance.inch(0.0),
      );
      final sight = Sight(name: 'Bad');
      final badProfile = ShotProfile(
        name: 'Bad Shot',
        rifle: rifle,
        cartridge: cartridge,
        sight: sight,
      );
      final badConditions = _makeConditions();

      expect(
        () => service.calculateTable(
          badProfile,
          badConditions,
          const TableCalcOptions(stepM: 100),
        ),
        throwsA(isA<CalculationException>()),
      );
    });
  });

  group('BallisticsService — powder sensitivity', () {
    test('powder sensitivity changes trajectory', () async {
      final profile = _makeProfile();

      // Створюємо умови для обнулення (стандартні)
      final zeroConditions = AtmoData(
        temperature: Temperature.celsius(15.0),
        altitude: Distance.meter(0),
        pressure: Pressure.hPa(1013.25),
        humidity: 0.0,
        powderTemp: Temperature.celsius(15.0),
      );

      // Cartridge with powder sensitivity
      final sensitiveCartridge = Cartridge(
        name: 'Temp Sens',
        projectileName: profile.cartridge!.projectileName,
        dragType: profile.cartridge!.dragType,
        weight: profile.cartridge!.weight,
        length: profile.cartridge!.length,
        diameter: profile.cartridge!.diameter,
        coefRows: profile.cartridge!.coefRows,
        mv: Velocity.mps(800),
        powderTemp: Temperature.celsius(15),
        powderSensitivity: Ratio.fraction(1.0), // 1% per 15°C
        zeroConditions: Conditions.withDefaults(
          usePowderSensitivity: true,
          distance: Distance.meter(100),
          atmo: zeroConditions,
          useDiffPowderTemp: true, // ← додаємо умови обнулення
        ),
      );

      final sensitiveProfile = ShotProfile(
        name: profile.name,
        rifle: profile.rifle,
        cartridge: sensitiveCartridge,
        sight: profile.sight,
      );

      // Conditions with higher temperature (20°C above reference)
      final hotConditions = _makeConditions(tempC: 35.0, powderTempC: 35.0);

      final withSens = await service.calculateTable(
        sensitiveProfile.copyWith(
          cartridge: sensitiveCartridge.copyWith(
            zeroConditions: sensitiveCartridge.zeroConditions.copyWith(
              usePowderSensitivity: true,
            ),
          ),
        ),
        hotConditions,
        const TableCalcOptions(stepM: 100),
      );

      final withoutSens = await service.calculateTable(
        sensitiveProfile.copyWith(
          cartridge: sensitiveCartridge.copyWith(
            zeroConditions: sensitiveCartridge.zeroConditions.copyWith(
              usePowderSensitivity: false,
            ),
          ),
        ),
        hotConditions,
        const TableCalcOptions(stepM: 100),
      );

      // With powder sensitivity, zero elevation should be different
      // (higher MV means less elevation needed for zero)
      expect(
        withSens.zeroElevationRad,
        isNot(closeTo(withoutSens.zeroElevationRad, 1e-6)),
      );

      // Also verify that with sensitivity the zero elevation is smaller
      // (higher velocity = less drop = less elevation needed)
      expect(withSens.zeroElevationRad, lessThan(withoutSens.zeroElevationRad));
    });
  });

  group('BallisticsResult data class', () {
    test('stores hitResult and zeroElevationRad', () async {
      final profile = _makeProfile();
      final conditions = _makeConditions();
      final result = await service.calculateTable(
        profile,
        conditions,
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
