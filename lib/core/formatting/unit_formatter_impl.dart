import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';

class UnitFormatterImpl implements UnitFormatter {
  final UnitSettings _u;

  UnitFormatterImpl(this._u);

  String _fmt(Dimension dim, FieldConstraints fc, Unit unit) {
    final value = dim.in_(unit);
    final accuracy = fc.accuracyFor(unit);
    return '${value.toStringAsFixed(accuracy)} ${unit.symbol}';
  }

  // --- Formatted strings ---

  @override
  String velocity(Velocity dim) => _fmt(dim, FC.velocity, _u.velocityUnit);

  @override
  String distance(Distance dim) => _fmt(dim, FC.targetDistance, _u.distanceUnit);

  @override
  String temperature(Temperature dim) =>
      _fmt(dim, FC.temperature, _u.temperatureUnit);

  @override
  String pressure(Pressure dim) => _fmt(dim, FC.pressure, _u.pressureUnit);

  @override
  String drop(Distance dim) => _fmt(dim, FC.drop, _u.dropUnit);

  @override
  String windage(Distance dim) => drop(dim);

  @override
  String adjustment(Angular dim) => _fmt(dim, FC.adjustment, _u.adjustmentUnit);

  @override
  String energy(Energy dim) => _fmt(dim, FC.energy, _u.energyUnit);

  @override
  String weight(Weight dim) => _fmt(dim, FC.bulletWeight, _u.weightUnit);

  @override
  String length(Distance dim) => _fmt(dim, FC.bulletLength, _u.lengthUnit);

  @override
  String diameter(Distance dim) => _fmt(dim, FC.bulletDiameter, _u.diameterUnit);

  @override
  String sightHeight(Distance dim) =>
      _fmt(dim, FC.sightHeight, _u.sightHeightUnit);

  @override
  String twist(Distance dim) => '1:${_fmt(dim, FC.twist, _u.twistUnit)}';

  @override
  String barrelLength(Distance dim) =>
      _fmt(dim, FC.barrelLength, _u.barrelLengthUnit);

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
  String torque(Torque dim) => _fmt(dim, FC.torque, _u.torqueUnit);

  // --- Raw numbers ---

  @override
  double rawVelocity(Velocity dim) => dim.in_(_u.velocityUnit);
  @override
  double rawDistance(Distance dim) => dim.in_(_u.distanceUnit);
  @override
  double rawTemperature(Temperature dim) => dim.in_(_u.temperatureUnit);
  @override
  double rawPressure(Pressure dim) => dim.in_(_u.pressureUnit);
  @override
  double rawDrop(Distance dim) => dim.in_(_u.dropUnit);
  @override
  double rawAdjustment(Angular dim) => dim.in_(_u.adjustmentUnit);
  @override
  double rawEnergy(Energy dim) => dim.in_(_u.energyUnit);
  @override
  double rawWeight(Weight dim) => dim.in_(_u.weightUnit);
  @override
  double rawSightHeight(Distance dim) => dim.in_(_u.sightHeightUnit);
  @override
  double rawTorque(Torque dim) => dim.in_(_u.torqueUnit);

  // --- Symbols ---

  @override
  String get velocitySymbol => _u.velocityUnit.symbol;
  @override
  String get distanceSymbol => _u.distanceUnit.symbol;
  @override
  String get temperatureSymbol => _u.temperatureUnit.symbol;
  @override
  String get pressureSymbol => _u.pressureUnit.symbol;
  @override
  String get dropSymbol => _u.dropUnit.symbol;
  @override
  String get adjustmentSymbol => _u.adjustmentUnit.symbol;
  @override
  String get energySymbol => _u.energyUnit.symbol;
  @override
  String get weightSymbol => _u.weightUnit.symbol;
  @override
  String get sightHeightSymbol => _u.sightHeightUnit.symbol;
  @override
  String get barrelLengthSymbol => _u.barrelLengthUnit.symbol;

  // --- Input conversion (for input dialogs) ---

  @override
  double inputToRaw(double displayValue, InputField field) {
    return switch (field) {
      InputField.velocity => displayValue.convert(_u.velocityUnit, Unit.mps),
      InputField.distance => displayValue.convert(_u.distanceUnit, Unit.meter),
      InputField.targetDistance => displayValue.convert(_u.distanceUnit, Unit.meter),
      InputField.zeroDistance => displayValue.convert(_u.distanceUnit, Unit.meter),
      InputField.temperature => displayValue.convert(_u.temperatureUnit, Unit.celsius),
      InputField.pressure => displayValue.convert(_u.pressureUnit, Unit.hPa),
      InputField.humidity => displayValue / 100.0,
      InputField.windVelocity => displayValue.convert(_u.velocityUnit, Unit.mps),
      InputField.lookAngle => displayValue,
      InputField.sightHeight => displayValue.convert(_u.sightHeightUnit, Unit.millimeter),
      InputField.twist => displayValue.convert(_u.twistUnit, Unit.inch),
      InputField.bulletWeight => displayValue.convert(_u.weightUnit, Unit.grain),
      InputField.bulletLength => displayValue.convert(_u.lengthUnit, Unit.millimeter),
      InputField.bulletDiameter => displayValue.convert(_u.diameterUnit, Unit.millimeter),
      InputField.barrelLength => displayValue.convert(_u.barrelLengthUnit, Unit.inch),
      InputField.torque => displayValue.convert(_u.torqueUnit, Unit.newtonMeter),
      InputField.bc => displayValue,
    };
  }

  @override
  double rawToInput(double rawValue, InputField field) {
    return switch (field) {
      InputField.velocity => rawValue.convert(Unit.mps, _u.velocityUnit),
      InputField.distance => rawValue.convert(Unit.meter, _u.distanceUnit),
      InputField.targetDistance => rawValue.convert(Unit.meter, _u.distanceUnit),
      InputField.zeroDistance => rawValue.convert(Unit.meter, _u.distanceUnit),
      InputField.temperature => rawValue.convert(Unit.celsius, _u.temperatureUnit),
      InputField.pressure => rawValue.convert(Unit.hPa, _u.pressureUnit),
      InputField.humidity => rawValue * 100.0,
      InputField.windVelocity => rawValue.convert(Unit.mps, _u.velocityUnit),
      InputField.lookAngle => rawValue,
      InputField.sightHeight => rawValue.convert(Unit.millimeter, _u.sightHeightUnit),
      InputField.twist => rawValue.convert(Unit.inch, _u.twistUnit),
      InputField.bulletWeight => rawValue.convert(Unit.grain, _u.weightUnit),
      InputField.bulletLength => rawValue.convert(Unit.millimeter, _u.lengthUnit),
      InputField.bulletDiameter => rawValue.convert(Unit.millimeter, _u.diameterUnit),
      InputField.barrelLength => rawValue.convert(Unit.inch, _u.barrelLengthUnit),
      InputField.torque => rawValue.convert(Unit.newtonMeter, _u.torqueUnit),
      InputField.bc => rawValue,
    };
  }
}
