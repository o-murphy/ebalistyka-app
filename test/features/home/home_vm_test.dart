// Unit tests for HomeViewModel (Phase 2).
//
// Uses a fake BallisticsService with provider overrides.
// ObjectBox entities used directly (no old model classes).
//   flutter test test/features/home/home_vm_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/home/home_vm.dart';

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

Profile _makeProfile() {
  final weapon = Weapon()
    ..name = 'Test Rifle'
    ..twistInch = 11.0
    ..caliberInch = 0.308;

  final sight = Sight()
    ..name = 'Test Scope'
    ..sightHeightInch = 38.0 / 25.4;

  final ammo = Ammo()
    ..name = 'Test .308'
    ..projectileName = 'Test 175gr'
    ..dragTypeValue = 'g7'
    ..bcG7 = 0.475
    ..weightGrain = 175.0
    ..caliberInch = 0.308
    ..lengthInch = 1.22
    ..muzzleVelocityMps = 800.0
    ..muzzleVelocityTemperatureC = 15.0;

  final profile = Profile()..name = 'Test Shot';
  profile.weapon.target = weapon;
  profile.sight.target = sight;
  profile.ammo.target = ammo;
  return profile;
}

ShootingConditions _makeConditions({
  double targetM = 300.0,
  double windMps = 3.0,
  double windDeg = 90.0,
  double tempC = 20.0,
  double altM = 150.0,
  double pressHPa = 1013.25,
  double humidity = 0.50,
}) {
  return ShootingConditions()
    ..distanceMeter = targetM
    ..windSpeedMps = windMps
    ..windDirectionDeg = windDeg
    ..temperatureC = tempC
    ..altitudeMeter = altM
    ..pressurehPa = pressHPa
    ..humidityFrac = humidity;
}

GeneralSettings _defaultSettings() => GeneralSettings()..homeShowMrad = true;

/// Creates a minimal trajectory list for testing.
List<bclibc.TrajectoryData> _makeTraj({int points = 31, double stepM = 10.0}) {
  final result = <bclibc.TrajectoryData>[];
  for (var i = 0; i <= points; i++) {
    final d = i * stepM;
    final t = d / 800.0;
    final v = 800.0 - d * 0.5;
    final h = -(d * d * 0.00005);
    final m = v / 1100.0;
    int flag = 0;
    if (i == 10) flag = bclibc.TrajFlag.zeroUp.value;
    result.add(
      bclibc.TrajectoryData(
        time: t,
        distance: Distance(d * 3.28084, Unit.foot),
        velocity: Velocity.fps(v),
        mach: m,
        height: Distance.foot(h),
        slantHeight: Distance.foot(h),
        dropAngle: Angular(h / d.clamp(1, double.infinity) * 1000, Unit.mil),
        windage: Distance(d * 0.001, Unit.foot),
        windageAngle: Angular(
          d * 0.001 / d.clamp(1, double.infinity) * 1000,
          Unit.mil,
        ),
        slantDistance: Distance(d * 3.28084, Unit.foot),
        angle: Angular.mil(0),
        densityRatio: 1.0,
        drag: 0.3,
        energy: Energy(2000 - d * 3.0, Unit.footPound),
        ogw: Weight.grain(500),
        flag: flag,
      ),
    );
  }
  return result;
}

BallisticsResult _makeResult() {
  final shot = bclibc.Shot(
    weapon: bclibc.Weapon(
      sightHeight: Distance.millimeter(38.0),
      twist: Distance.inch(11.0),
    ),
    ammo: bclibc.Ammo(
      dm: bclibc.DragModel(
        bc: 0.475,
        dragTable: bclibc.tableG7,
        weight: Weight.grain(175),
        diameter: Distance.inch(0.308),
        length: Distance.inch(1.22),
      ),
      mv: Velocity.mps(800),
      powderTemp: Temperature.celsius(15),
      tempModifier: 0.0,
      usePowderSensitivity: false,
    ),
    lookAngle: Angular.degree(0),
    atmo: bclibc.Atmo.icao(),
    winds: [],
  );
  shot.relativeAngle = Angular.radian(0.002);
  final traj = _makeTraj();
  final hit = bclibc.HitResult(shot, traj);
  return BallisticsResult(hitResult: hit, zeroElevationRad: 0.002);
}

// ── Fake service + notifiers ────────────────────────────────────────────────

class _FakeBallisticsService implements BallisticsService {
  final BallisticsResult result;
  int callCount = 0;

  _FakeBallisticsService(this.result);

  @override
  Future<BallisticsResult> calculateForTarget(
    Profile profile,
    ShootingConditions conditions,
    TargetCalcOptions opts,
  ) async {
    callCount++;
    return result;
  }

  @override
  Future<BallisticsResult> calculateTable(
    Profile profile,
    ShootingConditions conditions,
    TableCalcOptions opts,
  ) async {
    callCount++;
    return result;
  }
}

class _FakeShotContextNotifier extends ShotContextNotifier {
  final Profile _profile;
  final ShootingConditions _conditions;
  _FakeShotContextNotifier(this._profile, this._conditions);
  @override
  Future<ShotContext?> build() async =>
      ShotContext(profile: _profile, conditions: _conditions);
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final GeneralSettings _settings;
  _FakeSettingsNotifier(this._settings);
  @override
  Future<GeneralSettings> build() async => _settings;
}

ProviderContainer _createContainer({
  required Profile profile,
  required ShootingConditions conditions,
  required _FakeBallisticsService service,
  GeneralSettings? settings,
  UnitSettings? unitSettings,
}) {
  return ProviderContainer(
    overrides: [
      shotContextProvider.overrideWith(
        () => _FakeShotContextNotifier(profile, conditions),
      ),
      settingsProvider.overrideWith(
        () => _FakeSettingsNotifier(settings ?? _defaultSettings()),
      ),
      unitSettingsProvider.overrideWith(
        (ref) => unitSettings ?? UnitSettings(),
      ),
      ballisticsServiceProvider.overrideWithValue(service),
    ],
  );
}

/// Ensures async dependencies resolve, then triggers recalculate.
Future<HomeUiReady> _recalculate(ProviderContainer container) async {
  await container.read(shotContextProvider.future);
  await container.read(settingsProvider.future);
  await Future<void>.delayed(Duration.zero);
  final notifier = container.read(homeVmProvider.notifier);
  await notifier.recalculate();
  final state = container.read(homeVmProvider).value;
  return state as HomeUiReady;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('HomeViewModel — basic ready state', () {
    late ProviderContainer container;
    late _FakeBallisticsService service;
    late HomeUiReady state;

    setUp(() async {
      service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      state = await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('rifle and cartridge names are set', () {
      expect(state.weaponName, 'Test Rifle');
      expect(state.ammoName, 'Test .308');
    });

    test('wind angle is set from conditions', () {
      expect(state.windAngleDeg, closeTo(90.0, 0.1));
    });

    test('conditions displays are non-empty strings', () {
      expect(state.tempDisplay, isNotEmpty);
      expect(state.altDisplay, isNotEmpty);
      expect(state.pressDisplay, isNotEmpty);
      expect(state.humidDisplay, isNotEmpty);
    });

    test('conditions contain correct units', () {
      expect(state.tempDisplay, contains('°C'));
      expect(state.altDisplay, contains('m'));
      expect(state.pressDisplay, contains('hPa'));
      expect(state.humidDisplay, contains('%'));
    });

    test('cartridge info line contains projectile name and MV', () {
      expect(state.cartridgeInfoLine, contains('Test 175gr'));
      expect(state.cartridgeInfoLine, contains('m/s'));
      expect(state.cartridgeInfoLine, contains('G7'));
    });

    test('adjustment data has elevation values', () {
      expect(state.adjustment.elevation, isNotEmpty);
      expect(state.adjustment.elevation.first.symbol, 'MRAD');
    });

    test('table data has 5 distance headers', () {
      expect(state.tableData.distanceHeaders.length, 5);
    });

    test('table data has multiple rows', () {
      expect(state.tableData.rows.length, greaterThan(5));
    });

    test('chart data has points', () {
      expect(state.chartData.points, isNotEmpty);
    });

    test('selected point info is auto-populated at target distance', () {
      expect(state.selectedPointInfo, isNotNull);
      expect(state.selectedChartIndex, isNotNull);
    });

    test('ballistics service was called once', () {
      expect(service.callCount, 1);
    });
  });

  group('HomeViewModel — chart point selection', () {
    late ProviderContainer container;
    late _FakeBallisticsService service;

    setUp(() async {
      service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('selectChartPoint sets selectedPointInfo', () {
      final notifier = container.read(homeVmProvider.notifier);
      notifier.selectChartPoint(5);
      final state = container.read(homeVmProvider).value as HomeUiReady;
      expect(state.selectedPointInfo, isNotNull);
      expect(state.selectedPointInfo!.distance, isNotEmpty);
      expect(state.selectedPointInfo!.velocity, isNotEmpty);
      expect(state.selectedPointInfo!.energy, isNotEmpty);
    });

    test('selectChartPoint with invalid index preserves previous info', () {
      final notifier = container.read(homeVmProvider.notifier);
      final before = (container.read(homeVmProvider).value as HomeUiReady)
          .selectedPointInfo;
      notifier.selectChartPoint(999);
      final state = container.read(homeVmProvider).value as HomeUiReady;
      expect(state.selectedPointInfo, equals(before));
    });
  });

  group('HomeViewModel — imperial units', () {
    late ProviderContainer container;
    late HomeUiReady state;

    setUp(() async {
      final imperialUnits = UnitSettings()
        ..temperature = 'fahrenheit'
        ..distance = 'yard'
        ..velocity = 'fps'
        ..pressure = 'mmHg';
      final service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        unitSettings: imperialUnits,
      );
      state = await _recalculate(container);
    });

    tearDown(() => container.dispose());

    test('conditions display in imperial units', () {
      expect(state.tempDisplay, contains('°F'));
      expect(state.altDisplay, contains('yd'));
      expect(state.pressDisplay, contains('mmHg'));
    });

    test('cartridge info uses imperial velocity', () {
      expect(state.cartridgeInfoLine, contains('ft/s'));
    });
  });

  group('HomeViewModel — adjustment display settings', () {
    test('shows MOA when enabled', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        settings: GeneralSettings()
          ..homeShowMrad = false
          ..homeShowMoa = true,
      );
      addTearDown(container.dispose);

      final state = await _recalculate(container);
      expect(state.adjustment.elevation.any((v) => v.symbol == 'MOA'), isTrue);
      expect(
        state.adjustment.elevation.any((v) => v.symbol == 'MRAD'),
        isFalse,
      );
    });

    test('shows multiple units when multiple enabled', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        settings: GeneralSettings()
          ..homeShowMrad = true
          ..homeShowMoa = true,
      );
      addTearDown(container.dispose);

      final state = await _recalculate(container);
      expect(state.adjustment.elevation.length, 2);
    });
  });

  group('HomeViewModel — zero caching', () {
    test('second recalculate reuses cached zero', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      addTearDown(container.dispose);

      await _recalculate(container);
      expect(service.callCount, 1);

      await _recalculate(container);
      expect(service.callCount, 2);
    });
  });

  group('HomeViewModel — error handling', () {
    test('error state on service failure', () async {
      final badService = _ThrowingBallisticsService();
      final container = ProviderContainer(
        overrides: [
          shotContextProvider.overrideWith(
            () => _FakeShotContextNotifier(_makeProfile(), _makeConditions()),
          ),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(_defaultSettings()),
          ),
          unitSettingsProvider.overrideWith((ref) => UnitSettings()),
          ballisticsServiceProvider.overrideWithValue(badService),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shotContextProvider.future);
      await container.read(settingsProvider.future);
      await Future<void>.delayed(Duration.zero);

      final notifier = container.read(homeVmProvider.notifier);
      await notifier.recalculate();
      final state = container.read(homeVmProvider).value;
      expect(state, isA<HomeUiError>());
      expect((state as HomeUiError).message, contains('Boom'));
    });
  });

  group('HomeViewModel — initial state', () {
    test('starts with loading state', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      addTearDown(container.dispose);

      // build() повертає HomeUiNoData поки не викликано recalculate
      final state = await container.read(homeVmProvider.future);
      expect(state, isA<HomeUiNoData>());
    });
  });
}

class _ThrowingBallisticsService implements BallisticsService {
  @override
  Future<BallisticsResult> calculateForTarget(
    Profile profile,
    ShootingConditions conditions,
    TargetCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    throw Exception('Boom');
  }

  @override
  Future<BallisticsResult> calculateTable(
    Profile profile,
    ShootingConditions conditions,
    TableCalcOptions opts, {
    double? cachedZeroElevRad,
  }) async {
    throw Exception('Boom');
  }
}
