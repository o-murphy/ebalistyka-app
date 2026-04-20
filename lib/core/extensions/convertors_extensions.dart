import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

extension ConvertorsStateExtension on ConvertorsState {
  Distance get lengthValue => Distance.inch(lengthValueInch);
  set lengthValue(Distance v) => lengthValueInch = v.in_(Unit.inch);

  Unit get lengthUnit => Unit.values.firstWhere(
    (u) => u.name == lengthLastUnit,
    orElse: () => Unit.inch,
  );
  set lengthUnit(Unit v) => lengthLastUnit = v.name;

  Weight get weightValue => Weight.grain(weightValueGrain);
  set weightValue(Weight v) => weightValueGrain = v.in_(Unit.grain);

  Unit get weightUnit => Unit.values.firstWhere(
    (u) => u.name == weightLastUnit,
    orElse: () => Unit.grain,
  );
  set weightUnit(Unit v) => weightLastUnit = v.name;

  Pressure get pressureValue => Pressure.mmHg(pressureValueMmHg);
  set pressureValue(Pressure v) => pressureValueMmHg = v.in_(Unit.mmHg);

  Unit get pressureUnit => Unit.values.firstWhere(
    (u) => u.name == pressureLastUnit,
    orElse: () => Unit.hPa,
  );
  set pressureUnit(Unit v) => pressureLastUnit = v.name;

  Temperature get temperatureValue => Temperature.fahrenheit(temperatureValueF);
  set temperatureValue(Temperature v) =>
      temperatureValueF = v.in_(Unit.fahrenheit);

  Unit get temperatureUnit => Unit.values.firstWhere(
    (u) => u.name == temperatureLastUnit,
    orElse: () => Unit.celsius,
  );
  set temperatureUnit(Unit v) => temperatureLastUnit = v.name;

  Torque get torqueValue => Torque.newtonMeter(torqueValueNewtonMeter);
  set torqueValue(Torque v) => torqueValueNewtonMeter = v.in_(Unit.newtonMeter);

  Unit get torqueUnit => Unit.values.firstWhere(
    (u) => u.name == torqueLastUnit,
    orElse: () => Unit.newtonMeter,
  );
  set torqueUnit(Unit v) => torqueLastUnit = v.name;

  Distance get anglesConvDistanceValue =>
      Distance.meter(anglesConvDistanceValueMeter);
  set anglesConvDistanceValue(Distance v) =>
      anglesConvDistanceValueMeter = v.in_(Unit.meter);

  Unit get anglesConvDistanceUnit => Unit.values.firstWhere(
    (u) => u.name == anglesConvDistanceLastUnit,
    orElse: () => Unit.meter,
  );
  set anglesConvDistanceUnit(Unit v) => anglesConvDistanceLastUnit = v.name;

  Angular get anglesConvAngularValue => Angular.mil(anglesConvAngularValueMil);
  set anglesConvAngularValue(Angular v) =>
      anglesConvAngularValueMil = v.in_(Unit.mil);

  Unit get anglesConvAngularUnit => Unit.values.firstWhere(
    (u) => u.name == anglesConvAngularLastUnit,
    orElse: () => Unit.mil,
  );
  set anglesConvAngularUnit(Unit v) => anglesConvAngularLastUnit = v.name;

  Unit get anglesConvOutputUnit => Unit.values.firstWhere(
    (u) => u.name == anglesConvOutputLastUnit,
    orElse: () => Unit.centimeter,
  );
  set anglesConvOutputUnit(Unit v) => anglesConvOutputLastUnit = v.name;

  Velocity get velocityValue => Velocity.mps(velocityValueMps);
  set velocityValue(Velocity v) => velocityValueMps = v.in_(Unit.mps);

  Unit get velocityUnit => Unit.values.firstWhere(
    (u) => u.name == velocityLastUnit,
    orElse: () => Unit.mps,
  );
  set velocityUnit(Unit v) => velocityLastUnit = v.name;
}
