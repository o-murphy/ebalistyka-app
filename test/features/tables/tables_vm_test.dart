// Unit tests for TablesViewModel (Phase 2).
//
// Uses a fake BallisticsService with provider overrides.
// ObjectBox entities used directly (no old model classes).
//   flutter test test/features/tables/tables_vm_test.dart

import 'dart:async';

import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebalistyka/core/services/ballistics_service.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/tables/trajectory_tables_vm.dart';
import 'package:ebalistyka/features/tables/details_table_mv.dart';

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
    ..muzzleVelocityTemperatureC = 15.0
    ..zeroDistanceMeter = 100.0;

  final profile = Profile()..name = 'Test Shot';
  profile.weapon.target = weapon;
  profile.sight.target = sight;
  profile.ammo.target = ammo;
  return profile;
}

ShootingConditions _makeConditions({
  double tempC = 20.0,
  double altM = 150.0,
  double pressHPa = 1013.25,
  double humidity = 0.50,
  double powderTempC = 20.0,
  double windMps = 3.0,
  double windDeg = 90.0,
  bool usePowderSensitivity = false,
  bool useDiffPowderTemp = false,
}) {
  return ShootingConditions()
    ..temperatureC = tempC
    ..altitudeMeter = altM
    ..pressurehPa = pressHPa
    ..humidityFrac = humidity
    ..powderTemperatureC = powderTempC
    ..windSpeedMps = windMps
    ..windDirectionDeg = windDeg
    ..usePowderSensitivity = usePowderSensitivity
    ..useDiffPowderTemp = useDiffPowderTemp;
}

/// Creates trajectory data spanning 0–2000m with 1m step.
List<bclibc.TrajectoryData> _makeTraj({
  double startM = 0,
  double endM = 2000,
  double stepM = 1.0,
}) {
  final result = <bclibc.TrajectoryData>[];
  for (var d = startM; d <= endM; d += stepM) {
    final t = d / 800.0;
    final vFps = 2625.0 - d * 0.8;
    final hFt = -(d * d * 0.00003);
    final m = vFps / 1116.0;
    int flag = 0;
    if ((d - 100).abs() < 0.5) flag = bclibc.TrajFlag.zeroUp.value;
    if ((d - 300).abs() < 0.5) flag = bclibc.TrajFlag.zeroDown.value;

    result.add(
      bclibc.TrajectoryData(
        time: t,
        distance: Distance(d * 3.28084, Unit.foot),
        velocity: Velocity.fps(vFps),
        mach: m,
        height: Distance.foot(hFt),
        slantHeight: Distance.foot(hFt),
        dropAngle: Angular(d > 0 ? hFt / (d * 3.28084) * 1000 : 0, Unit.mil),
        windage: Distance(d * 0.0005, Unit.foot),
        windageAngle: Angular(
          d > 0 ? (d * 0.0005) / (d * 3.28084) * 1000 : 0,
          Unit.mil,
        ),
        slantDistance: Distance(d * 3.28084, Unit.foot),
        angle: Angular.mil(0),
        densityRatio: 1.0,
        drag: 0.3,
        energy: Energy(3000 - d * 1.2, Unit.footPound),
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
  TablesSettings? tablesSettings,
  UnitSettings? unitSettings,
}) {
  return ProviderContainer(
    overrides: [
      shotContextProvider.overrideWith(
        () => _FakeShotContextNotifier(profile, conditions),
      ),
      settingsProvider.overrideWith(
        () => _FakeSettingsNotifier(GeneralSettings()),
      ),
      unitSettingsProvider.overrideWith(
        (ref) => unitSettings ?? UnitSettings(),
      ),
      tablesSettingsProvider.overrideWith(
        (ref) => tablesSettings ?? TablesSettings(),
      ),
      ballisticsServiceProvider.overrideWithValue(service),
    ],
  );
}

/// Waits until the VM emits a state of type [T].
Future<T> _waitFor<T extends TrajectoryTablesUiState>(
  ProviderContainer container,
) {
  final completer = Completer<T>();
  late ProviderSubscription<AsyncValue<TrajectoryTablesUiState>> sub;
  sub = container.listen<AsyncValue<TrajectoryTablesUiState>>(
    trajectoryTablesVmProvider,
    (_, value) {
      if (value.value is T) {
        completer.complete(value.value! as T);
        sub.close();
      }
    },
    fireImmediately: true,
  );
  return completer.future;
}

// ── Helper to get details from provider ─────────────────────────────────────

DetailsTableData? _getDetails(ProviderContainer container) {
  return container.read(detailsTableMvProvider);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('TablesViewModel — basic ready state', () {
    late ProviderContainer container;
    late _FakeBallisticsService service;
    late TrajectoryTablesUiReady state;
    late DetailsTableData? details;

    setUp(() async {
      service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      state = await _waitFor<TrajectoryTablesUiReady>(container);
      details = _getDetails(container);
    });

    tearDown(() => container.dispose());

    test('spoiler has rifle name', () {
      expect(details?.weaponName, 'Test Rifle');
    });

    test('spoiler shows caliber', () {
      expect(details?.caliber, isNotNull);
    });

    test('spoiler shows twist', () {
      expect(details?.twist, isNotNull);
      expect(details?.twist, contains('1:'));
    });

    test('spoiler shows drag model', () {
      expect(details?.dragModel, 'G7');
    });

    test('spoiler shows BC', () {
      expect(details?.bc, isNotNull);
      expect(details?.bc, contains('0.475'));
    });

    test('spoiler shows zero MV', () {
      expect(details?.zeroMv, isNotNull);
      expect(details?.zeroMv, contains('m/s'));
    });

    test('spoiler shows current MV', () {
      expect(details?.currentMv, isNotNull);
    });

    test('spoiler shows zero distance', () {
      expect(details?.zeroDist, isNotNull);
      expect(details?.zeroDist, contains('m'));
    });

    test('spoiler shows temperature', () {
      expect(details?.temperature, isNotNull);
      expect(details?.temperature, contains('°C'));
    });

    test('spoiler shows humidity', () {
      expect(details?.humidity, isNotNull);
      expect(details?.humidity, contains('%'));
    });

    test('spoiler shows pressure', () {
      expect(details?.pressure, isNotNull);
      expect(details?.pressure, contains('hPa'));
    });

    test('spoiler shows wind speed', () {
      expect(details?.windSpeed, isNotNull);
    });

    test('spoiler shows wind direction', () {
      expect(details?.windDir, isNotNull);
      expect(details?.windDir, contains('90'));
    });

    test('main table has distance headers', () {
      expect(state.mainTable.distanceHeaders, isNotEmpty);
    });

    test('main table has rows', () {
      expect(state.mainTable.rows, isNotEmpty);
    });

    test('main table distance unit is set', () {
      expect(state.mainTable.distanceUnit, isNotEmpty);
    });

    test('ballistics service was called once', () {
      expect(service.callCount, 1);
    });
  });

  group('TablesViewModel — zero crossings', () {
    late ProviderContainer container;
    late TrajectoryTablesUiReady state;

    setUp(() async {
      final service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        tablesSettings: TablesSettings()..showZeros = true,
      );
      state = await _waitFor<TrajectoryTablesUiReady>(container);
    });

    tearDown(() => container.dispose());

    test('zero crossings table is present', () {
      expect(state.zeroCrossings, isNotNull);
    });

    test('zero crossings have arrow indicators', () {
      final headers = state.zeroCrossings!.distanceHeaders;
      final hasArrow = headers.any((h) => h.contains('↑') || h.contains('↓'));
      expect(hasArrow, isTrue);
    });
  });

  group('TablesViewModel — hidden columns', () {
    test('hiding columns reduces row count', () async {
      final service = _FakeBallisticsService(_makeResult());
      final containerAll = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
      );
      addTearDown(containerAll.dispose);
      final stateAll = await _waitFor<TrajectoryTablesUiReady>(containerAll);

      final service2 = _FakeBallisticsService(_makeResult());
      final containerHidden = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service2,
        tablesSettings: TablesSettings()
          ..hiddenCols = ['time', 'velocity', 'mach', 'energy'],
      );
      addTearDown(containerHidden.dispose);
      final stateHidden = await _waitFor<TrajectoryTablesUiReady>(
        containerHidden,
      );

      expect(
        stateHidden.mainTable.rows.length,
        lessThan(stateAll.mainTable.rows.length),
      );
    });
  });

  group('TablesViewModel — imperial units', () {
    late ProviderContainer container;
    late TrajectoryTablesUiReady state;
    late DetailsTableData? details;

    setUp(() async {
      final imperialUnits = UnitSettings()
        ..temperature = Unit.fahrenheit.name
        ..distance = Unit.yard.name
        ..velocity = Unit.fps.name
        ..pressure = Unit.mmHg.name
        ..drop = Unit.inch.name
        ..adjustment = Unit.moa.name
        ..energy = Unit.footPound.name;
      final service = _FakeBallisticsService(_makeResult());
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
        service: service,
        unitSettings: imperialUnits,
      );
      state = await _waitFor<TrajectoryTablesUiReady>(container);
      details = _getDetails(container);
    });

    tearDown(() => container.dispose());

    test('spoiler shows imperial temperature', () {
      expect(details?.temperature, isNotNull);
      expect(details?.temperature, contains('°F'));
    });

    test('spoiler shows imperial pressure', () {
      expect(details?.pressure, isNotNull);
      expect(details?.pressure, contains('mmHg'));
    });

    test('main table distance unit is yd', () {
      expect(state.mainTable.distanceUnit, contains('yd'));
    });
  });

  group('TablesViewModel — loading when context pending', () {
    test('remains loading when shot context never resolves', () async {
      final service = _FakeBallisticsService(_makeResult());
      final container = ProviderContainer(
        overrides: [
          shotContextProvider.overrideWith(() => _PendingShotContextNotifier()),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(GeneralSettings()),
          ),
          unitSettingsProvider.overrideWith((ref) => UnitSettings()),
          tablesSettingsProvider.overrideWith((ref) => TablesSettings()),
          ballisticsServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(trajectoryTablesVmProvider.future);
      expect(state, isA<TrajectoryTablesUiLoading>());
    });
  });

  group('TablesViewModel — error handling', () {
    test('returns error state on service failure', () async {
      final container = ProviderContainer(
        overrides: [
          shotContextProvider.overrideWith(
            () => _FakeShotContextNotifier(_makeProfile(), _makeConditions()),
          ),
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(GeneralSettings()),
          ),
          unitSettingsProvider.overrideWith((ref) => UnitSettings()),
          tablesSettingsProvider.overrideWith((ref) => TablesSettings()),
          ballisticsServiceProvider.overrideWithValue(
            _ThrowingBallisticsService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await _waitFor<TrajectoryTablesUiError>(container);
      expect(state.message, contains('Boom'));
    });
  });
}

/// ShotContext notifier that never completes — simulates "still loading" state.
class _PendingShotContextNotifier extends ShotContextNotifier {
  @override
  Future<ShotContext?> build() => Completer<ShotContext?>().future;
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
