import 'package:eballistica/core/solver/unit.dart';

class ConvertorsState {
  final double lengthValueInch;
  final Unit lengthUnit;

  const ConvertorsState({
    this.lengthValueInch = 100.0,
    this.lengthUnit = Unit.inch,
  });

  ConvertorsState copyWith({double? lengthValueInch, Unit? lengthUnit}) =>
      ConvertorsState(
        lengthValueInch: lengthValueInch ?? this.lengthValueInch,
        lengthUnit: lengthUnit ?? this.lengthUnit,
      );

  Map<String, dynamic> toJson() => {
    'lengthValue': lengthValueInch,
    'lengthUnit': lengthUnit.name,
  };

  factory ConvertorsState.fromJson(Map<String, dynamic> json) {
    double d(String key, double default_) {
      return (json[key] as num?)?.toDouble() ?? default_;
    }

    Unit u(String key, Unit fallback, bool Function(Unit) accepts) {
      final name = json[key] as String?;
      final unit = name != null ? Unit.fromName(name) : null;
      return (unit != null && accepts(unit)) ? unit : fallback;
    }

    return ConvertorsState(
      lengthValueInch: d('lengthValue', 100.0),
      lengthUnit: u('lengthUnit', Distance.rawUnit, Distance.accepts),
    );
  }
}
