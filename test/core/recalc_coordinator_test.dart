// Unit tests for RecalcCoordinator (Phase 3).
//
// No FFI required — uses only Riverpod container with provider overrides.
//   flutter test test/core/recalc_coordinator_test.dart

import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebalistyka/core/providers/recalc_coordinator.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_profile_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/shot_details_vm.dart';
import 'package:ebalistyka/features/tables/trajectory_tables_vm.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

Profile _makeProfile() => Profile()..name = 'Test Profile';

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

/// Profile notifier that can push new values without touching the DB.
class _ControllableProfileNotifier extends ShotProfileNotifier {
  @override
  Future<Profile?> build() async => _makeProfile();

  void push(Profile? p) => state = AsyncData(p);
}

/// Settings notifier that can push new values without touching the DB.
class _ControllableSettingsNotifier extends SettingsNotifier {
  @override
  Future<GeneralSettings> build() async => GeneralSettings();

  void push(GeneralSettings s) => state = AsyncData(s);
}

/// Conditions notifier that can push new values without touching the DB.
class _ControllableConditionsNotifier extends ShotConditionsNotifier {
  ShootingConditions _currentValue = ShootingConditions();

  @override
  Future<ShootingConditions> build() async => _currentValue;

  void push(ShootingConditions c) {
    _currentValue = c;
    state = AsyncData(c);
  }

  ShootingConditions get currentValue => _currentValue;
}

// ── Helpers ────────────────────────────────────────────────────────────────

class _TestContext {
  final ProviderContainer container;
  final _TrackingHomeVM homeVM;
  final _TrackingTablesVM tablesVM;
  final _TrackingShotDetailsVM shotDetailsVM;
  final _ControllableProfileNotifier profileNotifier;
  final _ControllableSettingsNotifier settingsNotifier;
  final _ControllableConditionsNotifier conditionsNotifier;

  _TestContext({
    required this.container,
    required this.homeVM,
    required this.tablesVM,
    required this.shotDetailsVM,
    required this.profileNotifier,
    required this.settingsNotifier,
    required this.conditionsNotifier,
  });
}

_TestContext _createTestContext() {
  final homeVM = _TrackingHomeVM();
  final tablesVM = _TrackingTablesVM();
  final shotDetailsVM = _TrackingShotDetailsVM();
  final profileNotifier = _ControllableProfileNotifier();
  final settingsNotifier = _ControllableSettingsNotifier();
  final conditionsNotifier = _ControllableConditionsNotifier();

  final container = ProviderContainer(
    overrides: [
      shotProfileProvider.overrideWith(() => profileNotifier),
      settingsProvider.overrideWith(() => settingsNotifier),
      shotConditionsProvider.overrideWith(() => conditionsNotifier),
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
    profileNotifier: profileNotifier,
    settingsNotifier: settingsNotifier,
    conditionsNotifier: conditionsNotifier,
  );
}

/// Initialise async providers and the coordinator.
Future<void> _initCoordinator(_TestContext ctx) async {
  await ctx.container.read(shotProfileProvider.future);
  await ctx.container.read(settingsProvider.future);
  await ctx.container.read(shotConditionsProvider.future);
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

  group('RecalcCoordinator — shotProfile changes', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('profile change triggers all providers', () async {
      ctx.profileNotifier.push(_makeProfile());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('multiple profile changes trigger multiple times', () async {
      ctx.profileNotifier.push(_makeProfile());
      await Future<void>.delayed(Duration.zero);
      ctx.profileNotifier.push(_makeProfile());
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 2);
      expect(ctx.tablesVM.recalcCount, 2);
      expect(ctx.shotDetailsVM.recalcCount, 2);
    });
  });

  group('RecalcCoordinator — conditions changes', () {
    late _TestContext ctx;

    setUp(() async {
      ctx = _createTestContext();
      await _initCoordinator(ctx);
    });

    tearDown(() => ctx.container.dispose());

    test('conditions change triggers all providers', () async {
      ctx.conditionsNotifier.push(ShootingConditions()..distanceMeter = 200);
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('conditions usePowderSensitivity change triggers recalc', () async {
      ctx.conditionsNotifier.push(
        ShootingConditions()..usePowderSensitivity = true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctx.homeVM.recalcCount, 1);
      expect(ctx.tablesVM.recalcCount, 1);
      expect(ctx.shotDetailsVM.recalcCount, 1);
    });

    test('conditions wind speed change triggers recalc', () async {
      ctx.conditionsNotifier.push(ShootingConditions()..windSpeedMps = 5.0);
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
      // Default is 10; push 50 to ensure a real change.
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
      // Default homeShowMrad = false; push true to differ from initial.
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

    test('profile change + tab activation accumulates calls', () async {
      ctx.profileNotifier.push(_makeProfile());
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
