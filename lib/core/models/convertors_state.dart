import 'package:eballistica/core/solver/unit.dart';

class ConvertorsState {
  final double lengthValueInch;
  final Unit lengthUnit;
  final double weightValueGrain;
  final Unit weightUnit;
  final double pressureValueMmHg; // Базова одиниця - mmHg
  final Unit pressureUnit;

  // Додаємо для температури
  final double temperatureValueFahrenheit; // Базова одиниця - Fahrenheit
  final Unit temperatureUnit;
  final double torqueValueNewtonMeter; // Базова одиниця - N·m
  final Unit torqueUnit;

  const ConvertorsState({
    this.lengthValueInch = 100.0,
    this.lengthUnit = Unit.inch,
    this.weightValueGrain = 100.0,
    this.weightUnit = Unit.grain,
    this.pressureValueMmHg = 1013.0,
    this.pressureUnit = Unit.hPa,
    this.temperatureValueFahrenheit = 68.0, // 68°F = 20°C
    this.temperatureUnit = Unit.celsius, // За замовчуванням показуємо в Celsius
    this.torqueValueNewtonMeter = 100.0, // 100 N·m за замовчуванням
    this.torqueUnit = Unit.newtonMeter,
  });

  ConvertorsState copyWith({
    double? lengthValueInch,
    Unit? lengthUnit,
    double? weightValueGrain,
    Unit? weightUnit,
    double? pressureValueMmHg,
    Unit? pressureUnit,
    double? temperatureValueFahrenheit,
    Unit? temperatureUnit,
    double? torqueValueNewtonMeter,
    Unit? torqueUnit,
  }) {
    return ConvertorsState(
      lengthValueInch: lengthValueInch ?? this.lengthValueInch,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      weightValueGrain: weightValueGrain ?? this.weightValueGrain,
      weightUnit: weightUnit ?? this.weightUnit,
      pressureValueMmHg: pressureValueMmHg ?? this.pressureValueMmHg,
      pressureUnit: pressureUnit ?? this.pressureUnit,
      temperatureValueFahrenheit:
          temperatureValueFahrenheit ?? this.temperatureValueFahrenheit,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      torqueValueNewtonMeter:
          torqueValueNewtonMeter ?? this.torqueValueNewtonMeter,
      torqueUnit: torqueUnit ?? this.torqueUnit,
    );
  }

  Map<String, dynamic> toJson() => {
    'lengthValue': lengthValueInch,
    'lengthUnit': lengthUnit.name,
    'weightValue': weightValueGrain,
    'weightUnit': weightUnit.name,
    'pressureValue': pressureValueMmHg,
    'pressureUnit': pressureUnit.name,
    'temperatureValue': temperatureValueFahrenheit,
    'temperatureUnit': temperatureUnit.name,
    'torqueValue': torqueValueNewtonMeter,
    'torqueUnit': torqueUnit.name,
  };

  factory ConvertorsState.fromJson(Map<String, dynamic> json) {
    double d(String key, double defaultValue) {
      return (json[key] as num?)?.toDouble() ?? defaultValue;
    }

    Unit u(String key, Unit fallback, bool Function(Unit) accepts) {
      final name = json[key] as String?;
      final unit = name != null ? Unit.fromName(name) : null;
      return (unit != null && accepts(unit)) ? unit : fallback;
    }

    return ConvertorsState(
      lengthValueInch: d('lengthValue', 100.0),
      lengthUnit: u('lengthUnit', Unit.inch, Distance.accepts),
      weightValueGrain: d('weightValue', 100.0),
      weightUnit: u('weightUnit', Unit.grain, Weight.accepts),
      pressureValueMmHg: d('pressureValue', 1013.0),
      pressureUnit: u('pressureUnit', Unit.hPa, Pressure.accepts),
      temperatureValueFahrenheit: d('temperatureValue', 68.0),
      temperatureUnit: u('temperatureUnit', Unit.celsius, Temperature.accepts),
      torqueValueNewtonMeter: d('torqueValue', 100.0),
      torqueUnit: u('torqueUnit', Unit.newtonMeter, Torque.accepts),
    );
  }
}
