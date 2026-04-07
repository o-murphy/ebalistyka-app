// Unit tests for ConditionsViewModel (Phase 2).
//
// Uses Riverpod container with provider overrides.
// ObjectBox entities used directly (no old model classes).
//   flutter test test/features/conditions/conditions_vm_test.dart

import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_profile_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/conditions/conditions_vm.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

Profile _makeProfile() {
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
    ..powderTemperatureC = 15.0
    ..powderSensitivityFrac = 0.001
    ..usePowderSensitivity = true;

  final profile = Profile()..name = 'Test Shot';
  profile.ammo.target = ammo;
  return profile;
}

ShootingConditions _makeConditions({
  double tempC = 20.0,
  double altM = 150.0,
  double pressHPa = 1013.25,
  double humidity = 0.50,
  double powderTempC = 20.0,
  bool usePowderSensitivity = false,
  bool useDiffPowderTemp = false,
}) {
  return ShootingConditions()
    ..temperatureC = tempC
    ..altitudeMeter = altM
    ..pressurehPa = pressHPa
    ..humidityFrac = humidity
    ..powderTemperatureC = powderTempC
    ..usePowderSensitivity = usePowderSensitivity
    ..useDiffPowderTemp = useDiffPowderTemp;
}

// ── Fake notifiers for provider overrides ────────────────────────────────────

class _FakeProfileNotifier extends ShotProfileNotifier {
  final Profile? _profile;
  _FakeProfileNotifier(this._profile);
  @override
  Future<Profile?> build() async => _profile;
}

class _FakeConditionsNotifier extends ShotConditionsNotifier {
  ShootingConditions _conditions;
  _FakeConditionsNotifier(this._conditions);

  @override
  Future<ShootingConditions> build() async => _conditions;

  void push(ShootingConditions c) {
    _conditions = c;
    state = AsyncData(c);
  }

  ShootingConditions get currentValue => _conditions;
}

/// Creates a ProviderContainer with the given profile, conditions and unit settings.
ProviderContainer _createContainer({
  required Profile? profile,
  required ShootingConditions conditions,
  UnitSettings? settings,
}) {
  return ProviderContainer(
    overrides: [
      shotProfileProvider.overrideWith(() => _FakeProfileNotifier(profile)),
      unitSettingsProvider.overrideWith((ref) => settings ?? UnitSettings()),
      shotConditionsProvider.overrideWith(
        () => _FakeConditionsNotifier(conditions),
      ),
    ],
  );
}

/// Waits for async dependencies to resolve, then reads the VM state.
Future<ConditionsUiState> _waitForConditions(
  ProviderContainer container,
) async {
  await container.read(shotProfileProvider.future);
  await container.read(shotConditionsProvider.future);
  await Future<void>.delayed(Duration.zero);
  return container.read(conditionsVmProvider.future);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ConditionsViewModel — metric units (defaults)', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 20.0,
          altM: 150.0,
          pressHPa: 1013.25,
          humidity: 0.50,
        ),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('temperature displays in Celsius', () {
      expect(state.temperature.displayValue, closeTo(20.0, 0.01));
      expect(state.temperature.symbol, '°C');
      expect(state.temperature.rawValue, closeTo(20.0, 0.01));
    });

    test('altitude displays in meters', () {
      expect(state.altitude.displayValue, closeTo(150.0, 0.1));
      expect(state.altitude.symbol, 'm');
    });

    test('pressure displays in hPa', () {
      expect(state.pressure.displayValue, closeTo(1013.25, 0.5));
      expect(state.pressure.symbol, 'hPa');
    });

    test('humidity displays as percentage', () {
      // rawValue is stored in percent (UI uses rawValue directly via UnitValueFieldTile)
      expect(state.humidity.rawValue, closeTo(50.0, 0.1));
      expect(state.humidity.symbol, '%');
    });

    test('temperature constraints are correct', () {
      expect(state.temperature.displayMin, -100.0);
      expect(state.temperature.displayMax, 100.0);
      expect(state.temperature.displayStep, 1.0);
      expect(state.temperature.decimals, 0);
    });

    test('altitude constraints are correct for metric', () {
      expect(state.altitude.displayMin, closeTo(-500.0, 0.1));
      expect(state.altitude.displayMax, closeTo(15000.0, 0.1));
    });

    test('powder sensitivity is off by default', () {
      expect(state.powderSensOn, false);
      expect(state.useDiffPowderTemp, false);
      expect(state.powderTemperature, isNull);
      expect(state.mvAtPowderTemp, isNull);
      expect(state.powderSensitivity, isNull);
    });

    test('coriolis and derivation are off by default', () {
      expect(state.coriolisOn, false);
    });
  });

  group('ConditionsViewModel — imperial units', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      final imperial = UnitSettings()
        ..temperature = 'fahrenheit'
        ..distance = 'yard'
        ..velocity = 'fps'
        ..pressure = 'mmHg';
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 20.0,
          altM: 150.0,
          pressHPa: 1013.25,
        ),
        settings: imperial,
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('temperature converts to Fahrenheit', () {
      expect(state.temperature.displayValue, closeTo(68.0, 0.5));
      expect(state.temperature.symbol, '°F');
    });

    test('altitude converts to yards', () {
      expect(state.altitude.displayValue, closeTo(164.0, 1.0));
      expect(state.altitude.symbol, 'yd');
    });

    test('pressure converts to mmHg', () {
      expect(state.pressure.displayValue, closeTo(760.0, 1.0));
      expect(state.pressure.symbol, 'mmHg');
    });

    test('temperature constraints convert properly', () {
      expect(state.temperature.displayMin, closeTo(-148.0, 1.0));
      expect(state.temperature.displayMax, closeTo(212.0, 1.0));
    });
  });

  group('ConditionsViewModel — powder sensitivity', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 25.0,
          powderTempC: 25.0,
          usePowderSensitivity: true,
          useDiffPowderTemp: false,
        ),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('powderSensOn reflects settings', () {
      expect(state.powderSensOn, true);
    });

    test('MV at powder temp is computed', () {
      expect(state.mvAtPowderTemp, isNotNull);
      expect(state.mvAtPowderTemp, contains('m/s'));
    });

    test('powder sensitivity string is shown', () {
      expect(state.powderSensitivity, isNotNull);
      expect(state.powderSensitivity, contains('%'));
    });

    test('separate powder temp field is null when useDiffPowderTemp=false', () {
      expect(state.useDiffPowderTemp, false);
      expect(state.powderTemperature, isNull);
    });
  });

  group('ConditionsViewModel — separate powder temperature', () {
    late ProviderContainer container;
    late ConditionsUiState state;

    setUp(() async {
      container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(
          tempC: 25.0,
          powderTempC: 30.0,
          usePowderSensitivity: true,
          useDiffPowderTemp: true,
        ),
      );
      state = await _waitForConditions(container);
    });

    tearDown(() => container.dispose());

    test('separate powder temp field is shown', () {
      expect(state.useDiffPowderTemp, true);
      expect(state.powderTemperature, isNotNull);
    });

    test('powder temp has correct value', () {
      expect(state.powderTemperature!.displayValue, closeTo(30.0, 0.5));
      expect(state.powderTemperature!.symbol, '°C');
    });
  });

  group('ConditionsViewModel — empty state', () {
    test('provides default values when conditions not loaded', () async {
      final container = ProviderContainer(
        overrides: [
          shotProfileProvider.overrideWith(
            () => _FakeProfileNotifier(_makeProfile()),
          ),
          unitSettingsProvider.overrideWith((ref) => UnitSettings()),
          shotConditionsProvider.overrideWith(
            () => _FakeConditionsNotifier(ShootingConditions()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shotProfileProvider.future);
      await container.read(shotConditionsProvider.future);
      await Future<void>.delayed(Duration.zero);

      final state = await container.read(conditionsVmProvider.future);
      expect(state.temperature.label, 'Temperature');
      expect(state.humidity.label, 'Humidity');
      expect(state.powderSensOn, false);
    });
  });

  group('ConditionsViewModel — inputField types', () {
    test('each field has correct inputField', () async {
      final container = _createContainer(
        profile: _makeProfile(),
        conditions: _makeConditions(),
      );
      addTearDown(container.dispose);
      final state = await _waitForConditions(container);

      expect(state.temperature.inputField, InputField.temperature);
      expect(state.altitude.inputField, InputField.distance);
      expect(state.humidity.inputField, InputField.humidity);
      expect(state.pressure.inputField, InputField.pressure);
    });
  });

  group('ConditionsField — data class', () {
    test('stores all values correctly', () {
      const f = ConditionsField(
        label: 'Test',
        displayValue: 42.0,
        rawValue: 315.15,
        symbol: 'K',
        displayMin: 0,
        displayMax: 500,
        displayStep: 1,
        decimals: 2,
        inputField: InputField.temperature,
        displayUnit: Unit.celsius,
      );
      expect(f.label, 'Test');
      expect(f.displayValue, 42.0);
      expect(f.rawValue, 315.15);
      expect(f.symbol, 'K');
      expect(f.displayMin, 0);
      expect(f.displayMax, 500);
      expect(f.displayStep, 1);
      expect(f.decimals, 2);
      expect(f.inputField, InputField.temperature);
    });
  });
}
