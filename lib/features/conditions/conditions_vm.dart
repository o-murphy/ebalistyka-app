import 'package:bclibc_ffi/bclibc.dart' as bclibc;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/profile_extensions.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/core/providers/shot_profile_provider.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class ConditionsField {
  final String label;
  final double displayValue;
  final double rawValue;
  final String symbol;
  final double displayMin;
  final double displayMax;
  final double displayStep;
  final int decimals;
  final InputField inputField;
  final Unit displayUnit;

  const ConditionsField({
    required this.label,
    required this.displayValue,
    required this.rawValue,
    required this.symbol,
    required this.displayMin,
    required this.displayMax,
    required this.displayStep,
    required this.decimals,
    required this.inputField,
    required this.displayUnit,
  });
}

class ConditionsUiState {
  final ConditionsField temperature;
  final ConditionsField altitude;
  final ConditionsField humidity;
  final ConditionsField pressure;
  final ConditionsField? powderTemperature;

  final bool powderSensOn;
  final bool useDiffPowderTemp;
  final bool coriolisOn;

  final double? latitudeDeg;
  final double? azimuthDeg;

  final String? mvAtPowderTemp;
  final String? powderSensitivity;

  const ConditionsUiState({
    required this.temperature,
    required this.altitude,
    required this.humidity,
    required this.pressure,
    this.powderTemperature,
    required this.powderSensOn,
    required this.useDiffPowderTemp,
    required this.coriolisOn,
    this.latitudeDeg,
    this.azimuthDeg,
    this.mvAtPowderTemp,
    this.powderSensitivity,
  });
}

// ── ViewModel ────────────────────────────────────────────────────────────────

class ConditionsViewModel extends AsyncNotifier<ConditionsUiState> {
  @override
  Future<ConditionsUiState> build() async {
    final conditions = await ref.watch(shotConditionsProvider.future);
    final profile = await ref.watch(shotProfileProvider.future);
    final units = ref.watch(unitSettingsProvider);
    final formatter = ref.watch(unitFormatterProvider);

    return _buildState(profile, conditions, units, formatter);
  }

  Future<void> updateTemperature(double rawCelsius) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateTemperature(rawCelsius);
  }

  Future<void> updateAltitude(double rawMeters) async {
    await ref.read(shotConditionsProvider.notifier).updateAltitude(rawMeters);
  }

  Future<void> updateHumidity(double rawPercent) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateHumidity(rawPercent / 100.0);
  }

  Future<void> updatePressure(double rawHPa) async {
    await ref.read(shotConditionsProvider.notifier).updatePressure(rawHPa);
  }

  Future<void> updatePowderTemp(double rawCelsius) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updatePowderTemperature(rawCelsius);
  }

  Future<void> setPowderSensitivity(bool value) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateUsePowderSensitivity(value);
  }

  Future<void> setDiffPowderTemp(bool value) async {
    await ref
        .read(shotConditionsProvider.notifier)
        .updateUseDiffPowderTemp(value);
  }

  Future<void> setCoriolis(bool value) async {
    await ref.read(shotConditionsProvider.notifier).updateUseCoriolis(value);
  }

  Future<void> updateLatitude(double? degrees) async {
    await ref.read(shotConditionsProvider.notifier).updateLatitude(degrees);
  }

  Future<void> updateAzimuth(double? degrees) async {
    await ref.read(shotConditionsProvider.notifier).updateAzimuth(degrees);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  ConditionsUiState _buildState(
    Profile? profile,
    ShootingConditions conditions,
    UnitSettings units,
    UnitFormatter formatter,
  ) {
    final tempUnit = units.temperatureUnit;
    final distUnit = units.distanceUnit;
    final pressUnit = units.pressureUnit;

    final tempRaw = conditions.temperatureC;
    final altRaw = conditions.altitudeMeter;
    final pressRaw = conditions.pressurehPa;
    final humRaw = conditions.humidityFrac * 100.0;

    final powderSensOn = conditions.usePowderSensitivity;
    final useDiffPowderTemp = powderSensOn && conditions.useDiffPowderTemp;
    final powderTempRaw = useDiffPowderTemp
        ? conditions.powderTemperatureC
        : tempRaw;

    final curVelocity = profile?.getCalculatedCurrentVelocity(conditions);
    final mvStr = curVelocity != null ? formatter.velocity(curVelocity) : "";

    String sensStr = "";
    final ammo = profile?.ammo.target;
    if (ammo != null) {
      sensStr = formatter.powderSensitivity(ammo.powderSensitivity);
    }

    return ConditionsUiState(
      temperature: _field(
        label: 'Temperature',
        rawValue: tempRaw,
        fc: FC.temperature,
        displayUnit: tempUnit,
        inputField: InputField.temperature,
        formatter: formatter,
      ),
      altitude: _field(
        label: 'Altitude',
        rawValue: altRaw,
        fc: FC.altitude,
        displayUnit: distUnit,
        inputField: InputField.distance,
        formatter: formatter,
      ),
      humidity: _field(
        label: 'Humidity',
        rawValue: humRaw,
        fc: FC.humidity,
        displayUnit: Unit.percent,
        inputField: InputField.humidity,
        formatter: formatter,
      ),
      pressure: _field(
        label: 'Pressure',
        rawValue: pressRaw,
        fc: FC.pressure,
        displayUnit: pressUnit,
        inputField: InputField.pressure,
        formatter: formatter,
      ),
      powderTemperature: (powderSensOn && useDiffPowderTemp)
          ? _field(
              label: 'Powder temperature',
              rawValue: powderTempRaw,
              fc: FC.temperature,
              displayUnit: tempUnit,
              inputField: InputField.temperature,
              formatter: formatter,
            )
          : null,
      powderSensOn: powderSensOn,
      useDiffPowderTemp: useDiffPowderTemp,
      coriolisOn: conditions.useCoriolis,
      latitudeDeg: conditions.latitudeDeg,
      azimuthDeg: conditions.azimuthDeg,
      mvAtPowderTemp: powderSensOn ? mvStr : null,
      powderSensitivity: powderSensOn ? sensStr : null,
    );
  }

  ConditionsField _field({
    required String label,
    required double rawValue,
    required FieldConstraints fc,
    required Unit displayUnit,
    required InputField inputField,
    required UnitFormatter formatter,
  }) {
    final displayValue = formatter.rawToInput(rawValue, inputField);
    final displayMin = _convertFcBound(fc.minRaw, fc.rawUnit, displayUnit);
    final displayMax = _convertFcBound(fc.maxRaw, fc.rawUnit, displayUnit);
    final displayStep = _convertFcStep(fc.stepRaw, fc.rawUnit, displayUnit);
    final decimals = fc.accuracyFor(displayUnit);

    return ConditionsField(
      label: label,
      displayValue: displayValue,
      rawValue: rawValue,
      symbol: displayUnit.symbol,
      displayMin: displayMin,
      displayMax: displayMax,
      displayStep: displayStep,
      decimals: decimals,
      inputField: inputField,
      displayUnit: displayUnit,
    );
  }

  double _convertFcBound(double rawVal, Unit rawUnit, Unit dispUnit) {
    return rawVal.convert(rawUnit, dispUnit);
  }

  double _convertFcStep(double rawStep, Unit rawUnit, Unit dispUnit) {
    final lo = (0.0).convert(rawUnit, dispUnit);
    final hi = rawStep.convert(rawUnit, dispUnit);
    return (hi - lo).abs();
  }
}

final conditionsVmProvider =
    AsyncNotifierProvider<ConditionsViewModel, ConditionsUiState>(
      ConditionsViewModel.new,
    );
