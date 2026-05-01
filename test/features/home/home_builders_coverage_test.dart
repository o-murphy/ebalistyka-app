// Coverage tests for HomeViewModel builder logic.
// These tests verify the behavior of the private builder methods so that
// extracting them to home_builders.dart does not silently change output.
//
//   flutter test test/features/home/home_builders_coverage_test.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/services/ballistics_service.dart';
import 'package:ebalistyka/core/providers/service_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/home/home_vm.dart';

import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

Profile _makeProfile({
  double sightClickMil = 0.1,
  double zeroOffsetYMil = 0.0,
  double zeroOffsetXMil = 0.0,
}) {
  final weapon = Weapon()
    ..name = 'Test Rifle'
    ..twistInch = 11.0
    ..caliberInch = 0.308;

  final sight = Sight()
    ..name = 'Test Scope'
    ..sightHeightInch = 38.0 / 25.4
    ..verticalClickUnitValue = Unit.mil
    ..verticalClick = sightClickMil
    ..horizontalClickUnitValue = Unit.mil
    ..horizontalClick = sightClickMil;

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
    ..zeroOffsetYUnitValue = Unit.mil
    ..zeroOffsetY = zeroOffsetYMil
    ..zeroOffsetXUnitValue = Unit.mil
    ..zeroOffsetX = zeroOffsetXMil;

  final profile = Profile()..name = 'Test Shot';
  profile.weapon.target = weapon;
  profile.sight.target = sight;
  profile.ammo.target = ammo;
  return profile;
}

ShootingConditions _makeConditions({double targetM = 300.0}) =>
    ShootingConditions()
      ..distanceMeter = targetM
      ..windSpeedMps = 3.0
      ..windDirectionDeg = 90.0
      ..temperatureC = 20.0
      ..altitudeMeter = 150.0
      ..pressurehPa = 1013.25
      ..humidityFrac = 0.50;

List<bclibc.TrajectoryData> _makeTraj({int points = 31, double stepM = 10.0}) {
  final result = <bclibc.TrajectoryData>[];
  for (var i = 0; i <= points; i++) {
    final d = i * stepM;
    final v = 800.0 - d * 0.5;
    final h = -(d * d * 0.00005);
    final m = v / 1100.0;
    int flag = 0;
    if (i == 10) flag = bclibc.TrajFlag.zeroUp.value;
    result.add(
      bclibc.TrajectoryData(
        time: d / 800.0,
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

BallisticsResult _makeResult({int points = 31, double stepM = 10.0}) {
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
  final traj = _makeTraj(points: points, stepM: stepM);
  final hit = bclibc.HitResult(shot, traj);
  return BallisticsResult(hitResult: hit, zeroElevationRad: 0.002);
}

class _FakeBallisticsService implements BallisticsService {
  final BallisticsResult result;
  _FakeBallisticsService(this.result);

  @override
  Future<BallisticsResult> calculateForTarget(
    Profile p,
    ShootingConditions c,
    TargetCalcOptions opts,
  ) async => result;

  @override
  Future<BallisticsResult> calculateTable(
    Profile p,
    ShootingConditions c,
    TableCalcOptions opts,
  ) async => result;
}

class _FakeShotContextNotifier extends ShotContextNotifier {
  final Profile _p;
  final ShootingConditions _c;
  _FakeShotContextNotifier(this._p, this._c);
  @override
  Future<ShotContext?> build() async =>
      ShotContext(profile: _p, conditions: _c);
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final GeneralSettings _s;
  _FakeSettingsNotifier(this._s);
  @override
  Future<GeneralSettings> build() async => _s;
}

ProviderContainer _makeContainer({
  required Profile profile,
  ShootingConditions? conditions,
  GeneralSettings? settings,
  UnitSettings? units,
  ReticleSettings? reticle,
  BallisticsResult? result,
}) {
  return ProviderContainer(
    overrides: [
      shotContextProvider.overrideWith(
        () =>
            _FakeShotContextNotifier(profile, conditions ?? _makeConditions()),
      ),
      settingsProvider.overrideWith(
        () => _FakeSettingsNotifier(
          settings ?? (GeneralSettings()..homeShowMrad = true),
        ),
      ),
      unitSettingsProvider.overrideWith((ref) => units ?? UnitSettings()),
      ballisticsServiceProvider.overrideWithValue(
        _FakeBallisticsService(result ?? _makeResult()),
      ),
      appLocalizationsProvider.overrideWithValue(
        lookupAppLocalizations(const Locale('en')),
      ),
      if (reticle != null)
        reticleSettingsProvider.overrideWith((ref) => reticle),
    ],
  );
}

Future<HomeUiReady> _waitReady(ProviderContainer c) {
  final completer = Completer<HomeUiReady>();
  late ProviderSubscription<AsyncValue<HomeUiState>> sub;
  sub = c.listen<AsyncValue<HomeUiState>>(homeVmProvider, (_, v) {
    if (v.value is HomeUiReady) {
      completer.complete(v.value! as HomeUiReady);
      sub.close();
    }
  }, fireImmediately: true);
  return completer.future;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── _buildHomeTable ─────────────────────────────────────────────────────────

  group('_buildHomeTable — row labels', () {
    late HomeUiReady state;

    setUp(() async {
      final c = _makeContainer(profile: _makeProfile());
      addTearDown(c.dispose);
      state = await _waitReady(c);
    });

    test('has 5 distance columns', () {
      expect(state.tableData.distanceHeaders.length, 5);
    });

    test('target column (index 2) matches target distance', () {
      final targetM = 300.0;
      final header = state.tableData.distanceHeaders[2];
      expect(double.parse(header), closeTo(targetM, 1.0));
    });

    test('contains Height row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Height'), isTrue);
    });

    test('contains Elev row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Elevation'), isTrue);
    });

    test('contains Drop row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Drop'), isTrue);
    });

    test('contains Windage row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Wind°'), isTrue);
    });

    test('contains Velocity row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Velocity'), isTrue);
    });

    test('contains Energy row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Energy'), isTrue);
    });

    test('contains Time row', () {
      expect(state.tableData.rows.any((r) => r.label == 'Time'), isTrue);
    });

    test('target column cells are marked isTargetColumn', () {
      for (final row in state.tableData.rows) {
        expect(row.cells[2].isTargetColumn, isTrue);
      }
    });

    test('non-target columns are not marked isTargetColumn', () {
      for (final row in state.tableData.rows) {
        expect(row.cells[0].isTargetColumn, isFalse);
        expect(row.cells[4].isTargetColumn, isFalse);
      }
    });
  });

  group('_buildHomeTable — drop columns follow homeTableDistanceStep', () {
    test('columns span ±2 steps around target', () async {
      final settings = GeneralSettings()
        ..homeShowMrad = true
        ..homeTableDistanceStep = 50.0
        ..homeChartDistanceStep = 10.0;
      final c = _makeContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(targetM: 300.0),
        settings: settings,
        result: _makeResult(points: 60, stepM: 5.0),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);

      final headers = state.tableData.distanceHeaders
          .map(double.parse)
          .toList();
      expect(headers[0], closeTo(200.0, 1.0)); // 300 - 2*50
      expect(headers[2], closeTo(300.0, 1.0)); // target
      expect(headers[4], closeTo(400.0, 1.0)); // 300 + 2*50
    });
  });

  // ── _buildChartData ─────────────────────────────────────────────────────────

  group('_buildChartData', () {
    late HomeUiReady state;

    setUp(() async {
      final c = _makeContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(targetM: 300.0),
        settings: GeneralSettings()
          ..homeShowMrad = true
          ..homeChartDistanceStep = 25.0
          ..homeTableDistanceStep = 50.0,
        result: _makeResult(points: 60, stepM: 5.0),
      );
      addTearDown(c.dispose);
      state = await _waitReady(c);
    });

    test('chart points cover 0..targetM', () {
      final pts = state.chartState.chartData.points;
      expect(pts.first.distanceM, closeTo(0.0, 1.0));
      expect(pts.last.distanceM, lessThanOrEqualTo(300.0 + 1.0));
    });

    test('chart points are spaced by homeChartDistanceStep', () {
      final pts = state.chartState.chartData.points;
      if (pts.length >= 2) {
        final gap = pts[1].distanceM - pts[0].distanceM;
        expect(gap, closeTo(25.0, 1.0));
      }
    });

    test('all chart points have non-negative distance', () {
      for (final p in state.chartState.chartData.points) {
        expect(p.distanceM, greaterThanOrEqualTo(0.0));
      }
    });

    test('auto-selected index is closest to target distance', () {
      final idx = state.chartState.selectedChartIndex;
      final pts = state.chartState.chartData.points;
      expect(idx, isNotNull);
      final selectedDist = pts[idx!].distanceM;
      for (final p in pts) {
        expect(
          (selectedDist - 300.0).abs(),
          lessThanOrEqualTo((p.distanceM - 300.0).abs() + 0.01),
        );
      }
    });
  });

  // ── _buildPointInfo ─────────────────────────────────────────────────────────

  group('_buildPointInfo', () {
    late HomeUiReady state;

    setUp(() async {
      final c = _makeContainer(
        profile: _makeProfile(),
        result: _makeResult(points: 60, stepM: 5.0),
      );
      addTearDown(c.dispose);
      state = await _waitReady(c);
    });

    test('all point info fields are non-empty after auto-selection', () {
      final info = state.chartState.selectedPointInfo!;
      expect(info.distance, isNotEmpty);
      expect(info.velocity, isNotEmpty);
      expect(info.energy, isNotEmpty);
      expect(info.time, isNotEmpty);
      expect(info.height, isNotEmpty);
      expect(info.drop, isNotEmpty);
      expect(info.windage, isNotEmpty);
      expect(info.mach, isNotEmpty);
    });

    test('selectChartPoint — point info updates to selected index', () async {
      final c = _makeContainer(
        profile: _makeProfile(),
        result: _makeResult(points: 60, stepM: 5.0),
      );
      addTearDown(c.dispose);
      await _waitReady(c);

      c.read(homeVmProvider.notifier).selectChartPoint(0);
      final updated = c.read(homeVmProvider).value as HomeUiReady;
      expect(updated.chartState.selectedChartIndex, 0);
      expect(updated.chartState.selectedPointInfo, isNotNull);
    });

    test('selectChartPoint — distance at index 0 is near 0m', () async {
      final c = _makeContainer(
        profile: _makeProfile(),
        result: _makeResult(points: 60, stepM: 5.0),
      );
      addTearDown(c.dispose);
      await _waitReady(c);

      c.read(homeVmProvider.notifier).selectChartPoint(0);
      final updated = c.read(homeVmProvider).value as HomeUiReady;
      // distance string for 0m should contain "0"
      expect(updated.chartState.selectedPointInfo!.distance, contains('0'));
    });
  });

  // ── _buildAdjustment — clicks ───────────────────────────────────────────────

  group('_buildAdjustment — clicks unit', () {
    test('includes Clicks row when homeShowInClicks is true', () async {
      final settings = GeneralSettings()
        ..homeShowMrad = false
        ..homeShowInClicks = true;
      final c = _makeContainer(
        profile: _makeProfile(sightClickMil: 0.1),
        settings: settings,
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);

      expect(
        state.reticleState.adjustment.elevation.any(
          (v) => v.symbol == 'Clicks',
        ),
        isTrue,
      );
      expect(
        state.reticleState.adjustment.windage.any((v) => v.symbol == 'Clicks'),
        isTrue,
      );
    });

    test('Clicks value is 0 when click size is 0', () async {
      final settings = GeneralSettings()
        ..homeShowMrad = false
        ..homeShowInClicks = true;
      final c = _makeContainer(
        profile: _makeProfile(sightClickMil: 0.0),
        settings: settings,
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);

      final clickRow = state.reticleState.adjustment.elevation.firstWhere(
        (v) => v.symbol == 'Clicks',
      );
      expect(clickRow.absValue, closeTo(0.0, 0.001));
    });

    test('does not include Clicks when homeShowInClicks is false', () async {
      final settings = GeneralSettings()
        ..homeShowMrad = true
        ..homeShowInClicks = false;
      final c = _makeContainer(profile: _makeProfile(), settings: settings);
      addTearDown(c.dispose);
      final state = await _waitReady(c);

      expect(
        state.reticleState.adjustment.elevation.any(
          (v) => v.symbol == 'Clicks',
        ),
        isFalse,
      );
    });
  });

  // ── _buildZeroOffsetMessageLine ─────────────────────────────────────────────

  group('_buildZeroOffsetMessageLine', () {
    test('is null when ammo has zero offset = 0', () async {
      final c = _makeContainer(
        profile: _makeProfile(zeroOffsetYMil: 0.0, zeroOffsetXMil: 0.0),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.zeroOffsetMessageLine, isNull);
    });

    test('is non-null when ammo has non-zero vertical offset', () async {
      final c = _makeContainer(
        profile: _makeProfile(zeroOffsetYMil: 0.5, zeroOffsetXMil: 0.0),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.zeroOffsetMessageLine, isNotNull);
      expect(state.reticleState.zeroOffsetMessageLine, contains('Zero offset'));
    });

    test('is non-null when ammo has non-zero horizontal offset', () async {
      final c = _makeContainer(
        profile: _makeProfile(zeroOffsetYMil: 0.0, zeroOffsetXMil: -0.3),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.zeroOffsetMessageLine, isNotNull);
    });

    test('mentions vertical when Y offset is set', () async {
      final c = _makeContainer(
        profile: _makeProfile(zeroOffsetYMil: 0.2, zeroOffsetXMil: 0.0),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.zeroOffsetMessageLine, contains('vertical'));
    });

    test('mentions horizontal when X offset is set', () async {
      final c = _makeContainer(
        profile: _makeProfile(zeroOffsetYMil: 0.0, zeroOffsetXMil: 0.2),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.zeroOffsetMessageLine, contains('horizontal'));
    });
  });

  // ── _buildCartridgeInfoLine ─────────────────────────────────────────────────

  group('_buildCartridgeInfoLine', () {
    test('contains projectile name', () async {
      final c = _makeContainer(profile: _makeProfile());
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.cartridgeInfoLine, contains('Test 175gr'));
    });

    test('contains muzzle velocity with unit', () async {
      final c = _makeContainer(profile: _makeProfile());
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.cartridgeInfoLine, contains('m/s'));
    });

    test('contains drag model info', () async {
      final c = _makeContainer(profile: _makeProfile());
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.cartridgeInfoLine, contains('G7'));
    });

    test('contains Sg when weapon has twist data', () async {
      final c = _makeContainer(
        profile: _makeProfile(),
        result: _makeResult(points: 60, stepM: 5.0),
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.cartridgeInfoLine, contains('Sg'));
    });

    test('uses fps in imperial mode', () async {
      final c = _makeContainer(
        profile: _makeProfile(),
        units: UnitSettings()..velocity = 'fps',
      );
      addTearDown(c.dispose);
      final state = await _waitReady(c);
      expect(state.reticleState.cartridgeInfoLine, contains('ft/s'));
    });
  });
}
