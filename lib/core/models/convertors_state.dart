import 'package:eballistica/core/solver/unit.dart';

class ConvertorsState {
  final double lengthValueInch;
  final Unit lengthUnit;

  // Вага - зберігаємо в гранах (базова одиниця)
  final double weightValueGrain;
  final Unit weightUnit;

  const ConvertorsState({
    this.lengthValueInch = 100.0,
    this.lengthUnit = Unit.inch,
    this.weightValueGrain = 100.0, // 100 гран за замовчуванням
    this.weightUnit = Unit.grain,
  });

  ConvertorsState copyWith({
    double? lengthValueInch,
    Unit? lengthUnit,
    double? weightValueGrain,
    Unit? weightUnit,
  }) {
    return ConvertorsState(
      lengthValueInch: lengthValueInch ?? this.lengthValueInch,
      lengthUnit: lengthUnit ?? this.lengthUnit,
      weightValueGrain: weightValueGrain ?? this.weightValueGrain,
      weightUnit: weightUnit ?? this.weightUnit,
    );
  }

  Map<String, dynamic> toJson() => {
    'lengthValue': lengthValueInch,
    'lengthUnit': lengthUnit.name,
    'weightValue': weightValueGrain,
    'weightUnit': weightUnit.name,
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
    );
  }
}
