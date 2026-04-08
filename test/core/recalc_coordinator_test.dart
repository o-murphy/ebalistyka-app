// Unit tests for RecalcCoordinator (Phase 3).
//
// No FFI required — uses only Riverpod container with provider overrides.
//   flutter test test/core/recalc_coordinator_test.dart

import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebalistyka/core/providers/recalc_coordinator.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/shot_details_vm.dart';
import 'package:ebalistyka/features/tables/trajectory_tables_vm.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

ShotContext _makeContext() => ShotContext(
  profile: Profile()..name = 'Test Profile',
  conditions: ShootingConditions(),
);

// ── Fake notifiers that track calls ────────────────────────────────────────

class _TrackingHomeVM extends HomeViewModel {
  int recalcCount = 0;

  @override
  Future<HomeUiState> build() async => const HomeUiLoading();

  @override
  Future<void> recalculate() async {
    recalcCount++;
  }
}

class _TrackingShotDetailsVM extends ShotDetailsViewModel {
  int recalcCount = 0;

  @override
  Future<ShotDetailsUiState> build() async => const ShotDetailsLoading();

  @override
  Future<void> recalculate() async {
    recalcCount++;
  }
}

class _TrackingTablesVM extends TrajectoryTablesViewModel {
  int recalcCount = 0;

  @override
  Future<TrajectoryTablesUiState> build() async =>
      const TrajectoryTablesUiLoading();

  @override
  Future<void> recalculate() async {
    recalcCount++;
  }
}

/// ShotContext notifier that can push new values without touching the DB.
class _ControllableShotContextNotifier extends ShotContextNotifier {
  @override
  Future<ShotContext?> build() async => _makeContext();

  void push(ShotContext? ctx) => state = AsyncData(ctx);
}

/// Settings notifier that can push new values without touching the DB.
class _ControllableSettingsNotifier extends SettingsNotifier {
  @override
  Future<GeneralSettings> build() async => GeneralSettings();

  void push(GeneralSettings s) => state = AsyncData(s);
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _TestContext {
  final ProviderContainer container;
  final _TrackingHomeVM homeVM;
  final _TrackingTablesVM tablesVM;
  final _TrackingShotDetailsVM shotDetailsVM;
  final _ControllableShotContextNotifier shotContextNotifier;
  final _ControllableSettingsNotifier settingsNotifier;

  _TestContext({
    required this.container,
    required this.homeVM,
    required this.tablesVM,
    required this.shotDetailsVM,
    required this.shotContextNotifier,
    required this.settingsNotifier,
  });
}

_TestContext _createTestContext() {
  final homeVM = _TrackingHomeVM();
  final tablesVM = _TrackingTablesVM();
  final shotDetailsVM = _TrackingShotDetailsVM();
  final shotContextNotifier = _ControllableShotContextNotifier();
  final settingsNotifier = _ControllableSettingsNotifier();

  final container = ProviderContainer(
    overrides: [
      shotContextProvider.overrideWith(() => shotContextNotifier),
      settingsProvider.overrideWith(() => settingsNotifier),
      homeVmProvider.overrideWith(() => homeVM),
      trajectoryTablesVmProvider.overrideWith(() => tablesVM),
      shotDetailsVmProvider.overrideWith(() => shotDetailsVM),
    ],
  );

  return _TestContext(
    container: container,
    homeVM: homeVM,
    tablesVM: tablesVM,
    shotDetailsVM: shotDetailsVM,
    shotContextNotifier: shotContextNotifier,
    settingsNotifier: settingsNotifier,
  );
}

/// Initialise async providers and the coordinator.
Future<void> _initCoordinator(_TestContext ctx) async {
  await ctx.container.read(shotContextProvider.future);
  await ctx.container.read(settingsProvider.future);
  await Future<void>.delayed(Duration.zero);
  // Reading the coordinator triggers its build() which sets up listeners
  ctx.container.read(recalcCoordinatorProvider);
  await Future<void>.delayed(Duration.zero);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('RecalcCoordinator — onTabActivated', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('tab 0 (Home) triggers homeVM + shotDetailsVM', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(0);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 0);
    });

    test('tab 2 (Tables) triggers tablesVM only', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(2);

      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.homeVM.recalcCount, 0);
      expect(ctx.shotDetailsVM.recalcCount, 0);
    });

    test('tab 4 (Settings) triggers nothing', () {
      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(4);

      expect(ctx.homeVM.recalcCount, 0);
      expect(ctx.tablesVM.recalcCount, 0);
      expect(ctx.shotDetailsVM.recalcCount, 0);
    });
  });

  group('RecalcCoordinator — shotContext changes', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('context change triggers all providers', () async {
      ctx.shotContextNotifier.push(_makeContext());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('multiple context changes trigger multiple times', () async {
      ctx.shotContextNotifier.push(_makeContext());
      await Future<void>.delayed(Duration.zero);
      ctx.shotContextNotifier.push(_makeContext());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 2);
      expect(ctx.tablesVM.recalcCount, 2);
      expect(ctx.shotDetailsVM.recalcCount, 2);
    });

    test('conditions change (via context) triggers all providers', () async {
      ctx.shotContextNotifier.push(
        ShotContext(
          profile: Profile()..name = 'Test',
          conditions: ShootingConditions()..distanceMeter = 200,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });
  });

  group('RecalcCoordinator — settings changes that trigger recalc', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('chartDistanceStep change triggers recalc', () async {
      ctx.settingsNotifier.push(GeneralSettings()..homeChartDistanceStep = 50);
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('tableDistanceStep change triggers recalc', () async {
      ctx.settingsNotifier.push(GeneralSettings()..homeTableDistanceStep = 50);
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });
  });

  group('RecalcCoordinator — unit display toggles trigger recalc', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('showMrad change triggers recalc', () async {
      ctx.settingsNotifier.push(GeneralSettings()..homeShowMrad = true);
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('showMoa change triggers recalc', () async {
      ctx.settingsNotifier.push(GeneralSettings()..homeShowMoa = true);
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });
  });

  group('RecalcCoordinator — combined scenarios', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('context change + tab activation accumulates calls', () async {
      ctx.shotContextNotifier.push(_makeContext());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);

      ctx.container.read(recalcCoordinatorProvider.notifier).onTabActivated(0);

      expect(ctx.homeVM.recalcCount, 2);
      expect(ctx.shotDetailsVM.recalcCount, 2);
    });

    test(
      'settings change with multiple relevant fields triggers once',
      () async {
        ctx.settingsNotifier.push(
          GeneralSettings()
            ..homeChartDistanceStep = 50
            ..homeTableDistanceStep = 50,
        );
        await Future<void>.delayed(Duration.zero);

        expect(ctx.homeVM.recalcCount, 1);
        expect(ctx.tablesVM.recalcCount, 1);
        expect(ctx.shotDetailsVM.recalcCount, 1);
      },
    );
  });
}
