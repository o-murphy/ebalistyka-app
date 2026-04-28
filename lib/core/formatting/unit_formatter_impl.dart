import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';

class UnitFormatterImpl implements UnitFormatter {
  final UnitSettings _u;
  final AppLocalizations _l10n;

  UnitFormatterImpl(this._u, this._l10n);

  String _fmt(
    Dimension? dim,
    FieldConstraints fc,
    Unit unit, [
    bool Function(Dimension)? condition,
  ]) {
    if (dim == null || condition?.call(dim) == false) return nullStr;
    final accuracy = fc.accuracyFor(unit);
    return '${dim.in_(unit).toFixedSafe(accuracy)} ${unit.localizedSymbol(_l10n)}';
  }

  // --- Formatted strings ---

  @override
  String velocity(Velocity? dim) =>
      _fmt(dim, FC.velocity, _u.velocityUnit, (dim) => dim.raw > 0.0);

  @override
  String distance(Distance? dim) =>
      _fmt(dim, FC.targetDistance, _u.distanceUnit);

  @override
  String temperature(Temperature dim) =>
      _fmt(dim, FC.temperature, _u.temperatureUnit);

  @override
  String pressure(Pressure dim) => _fmt(dim, FC.pressure, _u.pressureUnit);

  @override
  String drop(Distance? dim) => _fmt(dim, FC.drop, _u.dropUnit);

  @override
  String windage(Distance dim) => drop(dim);

  @override
  String adjustment(Angular dim) => _fmt(dim, FC.adjustment, _u.adjustmentUnit);

  @override
  String energy(Energy? dim) => _fmt(dim, FC.energy, _u.energyUnit);

  @override
  String weight(Weight? dim) =>
      _fmt(dim, FC.projectileWeight, _u.weightUnit, (dim) => dim.raw > 0.0);

  @override
  String length(Distance? dim) =>
      _fmt(dim, FC.projectileLength, _u.lengthUnit, (dim) => dim.raw > 0.0);

  @override
  String diameter(Distance? dim) =>
      _fmt(dim, FC.projectileDiameter, _u.diameterUnit, (dim) => dim.raw > 0.0);

  @override
  String sightHeight(Distance? dim) =>
      _fmt(dim, FC.sightHeight, _u.sightHeightUnit);

  @override
  String twist(Distance? dim) => '1:${_fmt(dim, FC.twist, _u.twistUnit)}';

  @override
  String barrelLength(Distance dim) =>
      _fmt(dim, FC.barrelLength, _u.barrelLengthUnit);

  @override
  String humidity(Ratio dim) => _fmt(dim, FC.humidity, Unit.percent);

  @override
  String mach(double m) => '${m.toFixedSafe(2)} ${_l10n.unitMachSym}';

  @override
  String time(double seconds) => '${seconds.toFixedSafe(3)} s';

  @override
  String powderSensitivity(Ratio dim) {
    final accuracy = FC.powderSensitivity.accuracyFor(Unit.percent);
    return '${dim.in_(Unit.percent).toFixedSafe(accuracy)} ${_l10n.powderSensUnit}';
  }

  @override
  String torque(Torque dim) => _fmt(dim, FC.torque, _u.torqueUnit);

  @override
  String targetSize(Angular dim) =>
      _fmt(dim, FC.targetSize, _u.targetSizeUnit, (dim) => dim.raw >= 0.0);

  @override
  String windSpeed(Velocity dim) => _fmt(dim, FC.windSpeed, _u.velocityUnit);

  @override
  String windDirection(Angular dim) => _fmt(dim, FC.windDirection, Unit.degree);

  @override
  String magnificationRange(double? min, double? max) =>
      "${min?.toFixedSafe(0) ?? "?"}-${max?.toFixedSafe(0) ?? "?"}x";

  @override
  String click(double? value, Unit? unit) => value == null || unit == null
      ? nullStr
      : adjustment(Angular(value, unit));
  // --- Symbols ---

  @override
  String get velocitySymbol => _u.velocityUnit.localizedSymbol(_l10n);
  @override
  String get distanceSymbol => _u.distanceUnit.localizedSymbol(_l10n);
  @override
  String get temperatureSymbol => _u.temperatureUnit.localizedSymbol(_l10n);
  @override
  String get pressureSymbol => _u.pressureUnit.localizedSymbol(_l10n);
  @override
  String get dropSymbol => _u.dropUnit.localizedSymbol(_l10n);
  @override
  String get adjustmentSymbol => _u.adjustmentUnit.localizedSymbol(_l10n);
  @override
  String get energySymbol => _u.energyUnit.localizedSymbol(_l10n);
  @override
  String get weightSymbol => _u.weightUnit.localizedSymbol(_l10n);
  @override
  String get sightHeightSymbol => _u.sightHeightUnit.localizedSymbol(_l10n);
  @override
  String get barrelLengthSymbol => _u.barrelLengthUnit.localizedSymbol(_l10n);

  // --- Input conversion (for input dialogs) ---

  @override
  double inputToRaw(double displayValue, InputField field) {
    return switch (field) {
      InputField.velocity => displayValue.convert(_u.velocityUnit, Unit.mps),
      InputField.distance => displayValue.convert(_u.distanceUnit, Unit.meter),
      InputField.targetDistance => displayValue.convert(
        _u.distanceUnit,
        Unit.meter,
      ),
      InputField.zeroDistance => displayValue.convert(
        _u.distanceUnit,
        Unit.meter,
      ),
      InputField.temperature => displayValue.convert(
        _u.temperatureUnit,
        Unit.celsius,
      ),
      InputField.pressure => displayValue.convert(_u.pressureUnit, Unit.hPa),
      InputField.humidity => displayValue / 100.0,
      InputField.windVelocity => displayValue.convert(
        _u.velocityUnit,
        Unit.mps,
      ),
      InputField.lookAngle => displayValue,
      InputField.sightHeight => displayValue.convert(
        _u.sightHeightUnit,
        Unit.millimeter,
      ),
      InputField.twist => displayValue.convert(_u.twistUnit, Unit.inch),
      InputField.bulletWeight => displayValue.convert(
        _u.weightUnit,
        Unit.grain,
      ),
      InputField.bulletLength => displayValue.convert(
        _u.lengthUnit,
        Unit.millimeter,
      ),
      InputField.bulletDiameter => displayValue.convert(
        _u.diameterUnit,
        Unit.millimeter,
      ),
      InputField.barrelLength => displayValue.convert(
        _u.barrelLengthUnit,
        Unit.inch,
      ),
      InputField.torque => displayValue.convert(
        _u.torqueUnit,
        Unit.newtonMeter,
      ),
      InputField.bc => displayValue,
    };
  }

  @override
  double rawToInput(double rawValue, InputField field) {
    return switch (field) {
      InputField.velocity => rawValue.convert(Unit.mps, _u.velocityUnit),
      InputField.distance => rawValue.convert(Unit.meter, _u.distanceUnit),
      InputField.targetDistance => rawValue.convert(
        Unit.meter,
        _u.distanceUnit,
      ),
      InputField.zeroDistance => rawValue.convert(Unit.meter, _u.distanceUnit),
      InputField.temperature => rawValue.convert(
        Unit.celsius,
        _u.temperatureUnit,
      ),
      InputField.pressure => rawValue.convert(Unit.hPa, _u.pressureUnit),
      InputField.humidity => rawValue * 100.0,
      InputField.windVelocity => rawValue.convert(Unit.mps, _u.velocityUnit),
      InputField.lookAngle => rawValue,
      InputField.sightHeight => rawValue.convert(
        Unit.millimeter,
        _u.sightHeightUnit,
      ),
      InputField.twist => rawValue.convert(Unit.inch, _u.twistUnit),
      InputField.bulletWeight => rawValue.convert(Unit.grain, _u.weightUnit),
      InputField.bulletLength => rawValue.convert(
        Unit.millimeter,
        _u.lengthUnit,
      ),
      InputField.bulletDiameter => rawValue.convert(
        Unit.millimeter,
        _u.diameterUnit,
      ),
      InputField.barrelLength => rawValue.convert(
        Unit.inch,
        _u.barrelLengthUnit,
      ),
      InputField.torque => rawValue.convert(Unit.newtonMeter, _u.torqueUnit),
      InputField.bc => rawValue,
    };
  }
}
