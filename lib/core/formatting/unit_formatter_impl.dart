import 'package:bclibc_ffi/bclibc_ffi.dart';
import 'package:ebalistyka/core/models/unit_settings.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';

class UnitFormatterImpl implements UnitFormatter {
  final UnitSettings _u;

  const UnitFormatterImpl(this._u);

  String _fmt(Dimension dim, FieldConstraints fc, Unit unit) {
    final value = dim.in_(unit);
    final accuracy = fc.accuracyFor(unit);
    return '${value.toStringAsFixed(accuracy)} ${unit.symbol}';
  }

  // --- Formatted strings ---

  @override
  String velocity(Velocity dim) => _fmt(dim, FC.velocity, _u.velocity);

  @override
  String distance(Distance dim) => _fmt(dim, FC.targetDistance, _u.distance);

  @override
  String temperature(Temperature dim) =>
      _fmt(dim, FC.temperature, _u.temperature);

  @override
  String pressure(Pressure dim) => _fmt(dim, FC.pressure, _u.pressure);

  @override
  String drop(Distance dim) => _fmt(dim, FC.drop, _u.drop);

  @override
  String windage(Distance dim) => drop(dim);

  @override
  String adjustment(Angular dim) => _fmt(dim, FC.adjustment, _u.adjustment);

  @override
  String energy(Energy dim) => _fmt(dim, FC.energy, _u.energy);

  @override
  String weight(Weight dim) => _fmt(dim, FC.bulletWeight, _u.weight);

  @override
  String length(Distance dim) => _fmt(dim, FC.bulletLength, _u.length);

  @override
  String diameter(Distance dim) => _fmt(dim, FC.bulletDiameter, _u.diameter);

  @override
  String sightHeight(Distance dim) => _fmt(dim, FC.sightHeight, _u.sightHeight);

  @override
  String twist(Distance dim) => '1:${_fmt(dim, FC.twist, _u.twist)}';

  @override
  String barrelLength(Distance dim) =>
      _fmt(dim, FC.barrelLength, _u.barrelLength);

  @override
  String humidity(Ratio dim) => _fmt(dim, FC.humidity, Unit.percent);

  @override
  String mach(double m) => '${m.toStringAsFixed(2)} M';

  @override
  String time(double seconds) => '${seconds.toStringAsFixed(3)} s';

  @override
  String powderSensitivity(Ratio dim) =>
      _fmt(dim, FC.powderSensitivity, Unit.percent);

  @override
  String torque(Torque dim) => _fmt(dim, FC.torque, _u.torque);

  // --- Raw numbers ---

  @override
  double rawVelocity(Velocity dim) => dim.in_(_u.velocity);
  @override
  double rawDistance(Distance dim) => dim.in_(_u.distance);
  @override
  double rawTemperature(Temperature dim) => dim.in_(_u.temperature);
  @override
  double rawPressure(Pressure dim) => dim.in_(_u.pressure);
  @override
  double rawDrop(Distance dim) => dim.in_(_u.drop);
  @override
  double rawAdjustment(Angular dim) => dim.in_(_u.adjustment);
  @override
  double rawEnergy(Energy dim) => dim.in_(_u.energy);
  @override
  double rawWeight(Weight dim) => dim.in_(_u.weight);
  @override
  double rawSightHeight(Distance dim) => dim.in_(_u.sightHeight);
  @override
  double rawTorque(Torque dim) => dim.in_(_u.torque);

  // --- Symbols ---

  @override
  String get velocitySymbol => _u.velocity.symbol;
  @override
  String get distanceSymbol => _u.distance.symbol;
  @override
  String get temperatureSymbol => _u.temperature.symbol;
  @override
  String get pressureSymbol => _u.pressure.symbol;
  @override
  String get dropSymbol => _u.drop.symbol;
  @override
  String get adjustmentSymbol => _u.adjustment.symbol;
  @override
  String get energySymbol => _u.energy.symbol;
  @override
  String get weightSymbol => _u.weight.symbol;
  @override
  String get sightHeightSymbol => _u.sightHeight.symbol;
  @override
  String get barrelLengthSymbol => _u.barrelLength.symbol;

  // --- Input conversion (for input dialogs) ---

  @override
  double inputToRaw(double displayValue, InputField field) {
    return switch (field) {
      InputField.velocity => displayValue.convert(_u.velocity, Unit.mps),
      InputField.distance => displayValue.convert(_u.distance, Unit.meter),
      InputField.targetDistance => displayValue.convert(
        _u.distance,
        Unit.meter,
      ),
      InputField.zeroDistance => displayValue.convert(_u.distance, .meter),
      InputField.temperature => displayValue.convert(
        _u.temperature,
        Unit.celsius,
      ),
      InputField.pressure => displayValue.convert(_u.pressure, Unit.hPa),
      InputField.humidity => displayValue / 100.0,
      InputField.windVelocity => displayValue.convert(_u.velocity, Unit.mps),
      InputField.lookAngle => displayValue,
      InputField.sightHeight => displayValue.convert(
        _u.sightHeight,
        Unit.millimeter,
      ),
      InputField.twist => displayValue.convert(_u.twist, Unit.inch),
      InputField.bulletWeight => displayValue.convert(_u.weight, Unit.grain),
      InputField.bulletLength => displayValue.convert(
        _u.length,
        Unit.millimeter,
      ),
      InputField.bulletDiameter => displayValue.convert(
        _u.diameter,
        Unit.millimeter,
      ),
      InputField.barrelLength => displayValue.convert(
        _u.barrelLength,
        Unit.inch,
      ),
      InputField.torque => displayValue.convert(_u.torque, Unit.newtonMeter),
      InputField.bc => displayValue,
    };
  }

  @override
  double rawToInput(double rawValue, InputField field) {
    return switch (field) {
      InputField.velocity => rawValue.convert(Unit.mps, _u.velocity),
      InputField.distance => rawValue.convert(Unit.meter, _u.distance),
      InputField.targetDistance => rawValue.convert(Unit.meter, _u.distance),
      InputField.zeroDistance => rawValue.convert(Unit.meter, _u.distance),
      InputField.temperature => rawValue.convert(Unit.celsius, _u.temperature),
      InputField.pressure => rawValue.convert(Unit.hPa, _u.pressure),
      InputField.humidity => rawValue * 100.0,
      InputField.windVelocity => rawValue.convert(Unit.mps, _u.velocity),
      InputField.lookAngle => rawValue,
      InputField.sightHeight => rawValue.convert(
        Unit.millimeter,
        _u.sightHeight,
      ),
      InputField.twist => rawValue.convert(Unit.inch, _u.twist),
      InputField.bulletWeight => rawValue.convert(Unit.grain, _u.weight),
      InputField.bulletLength => rawValue.convert(Unit.millimeter, _u.length),
      InputField.bulletDiameter => rawValue.convert(
        Unit.millimeter,
        _u.diameter,
      ),
      InputField.barrelLength => rawValue.convert(Unit.inch, _u.barrelLength),
      InputField.torque => rawValue.convert(Unit.newtonMeter, _u.torque),
      InputField.bc => rawValue,
    };
  }
}
