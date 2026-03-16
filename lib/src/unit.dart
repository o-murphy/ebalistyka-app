import 'dart:math';

enum Unit {
  radian(0, "radian", 6, "rad"),
  degree(1, "degree", 4, "°"),
  moa(2, "MOA", 2, "MOA"),
  mil(3, "mil", 3, "mil"),
  mRad(4, "mrad", 2, "mrad"),
  thousandth(5, "thousandth", 2, "ths"),
  inchesPer100Yd(6, "inch/100yd", 2, "in/100yd"),
  cmPer100m(7, "cm/100m", 2, "cm/100m"),
  oClock(8, "hour", 2, "h"),
  inch(10, "inch", 1, "inch"),
  foot(11, "foot", 2, "ft"),
  yard(12, "yard", 1, "yd"),
  mile(13, "mile", 3, "mi"),
  nauticalMile(14, "nautical mile", 3, "nm"),
  millimeter(15, "millimeter", 3, "mm"),
  centimeter(16, "centimeter", 3, "cm"),
  meter(17, "meter", 1, "m"),
  kilometer(18, "kilometer", 3, "km"),
  line(19, "line", 3, "ln"),
  footPound(30, "foot-pound", 0, "ft·lb"),
  joule(31, "joule", 0, "J"),
  mmHg(40, "mmHg", 0, "mmHg"),
  inHg(41, "inHg", 6, "inHg"),
  bar(42, "bar", 2, "bar"),
  hPa(43, "hPa", 4, "hPa"),
  psi(44, "psi", 4, "psi"),
  fahrenheit(50, "fahrenheit", 1, "°F"),
  celsius(51, "celsius", 1, "°C"),
  kelvin(52, "kelvin", 1, "°K"),
  rankin(53, "rankin", 1, "°R"),
  mps(60, "mps", 0, "m/s"),
  kmh(61, "kmh", 1, "km/h"),
  fps(62, "fps", 1, "ft/s"),
  mph(63, "mph", 1, "mph"),
  kt(64, "knot", 1, "kt"),
  grain(70, "grain", 1, "gr"),
  ounce(71, "ounce", 1, "oz"),
  gram(72, "gram", 1, "g"),
  pound(73, "pound", 0, "lb"),
  kilogram(74, "kilogram", 3, "kg"),
  newton(75, "newton", 3, "N"),
  minute(80, "minute", 0, "min"),
  second(81, "second", 1, "s"),
  millisecond(82, "millisecond", 3, "ms"),
  microsecond(83, "microsecond", 6, "µs"),
  nanosecond(84, "nanosecond", 9, "ns"),
  picosecond(85, "picosecond", 12, "ps");

  const Unit(this.id, this.label, this.accuracy, this.symbol);
  final int id;
  final String label;
  final int accuracy;
  final String symbol;
}

abstract interface class Measurable<T extends Measurable<T>> {
  T create(double value, Unit unit);
  double in_(Unit unit);
  T to(Unit unit);
  double toRaw(double value, Unit unit);
  double fromRaw(double value, Unit unit);
  double get rawValue;
  Unit get units;
  Map<Unit, double> get conversionFactors;
}

abstract class Dimension<T extends Dimension<T>> implements Measurable<T> {
  Dimension(double value, this._definedUnits) {
    _rawValue = toRaw(value, _definedUnits);
  }

  Map<Unit, double> get conversionFactors;

  late double _rawValue;
  final Unit _definedUnits;

  double get rawValue => _rawValue;
  Unit get units => _definedUnits;

  @override
  String toString() {
    final v = fromRaw(_rawValue, _definedUnits);
    final rounded = v.toStringAsFixed(_definedUnits.accuracy);
    return '$rounded${_definedUnits.symbol}';
  }

  @override
  double in_(Unit unit) {
    return fromRaw(_rawValue, unit);
  }

  @override
  T create(double value, Unit unit);

  @override
  T to(Unit unit) {
    return create(in_(unit), unit);
  }

  @override
  double toRaw(double value, Unit unit) {
    final factor = conversionFactors[unit];
    if (factor == null) throw Exception('$runtimeType: $unit is not supported');
    return value * factor;
  }

  @override
  double fromRaw(double value, Unit unit) {
    final factor = conversionFactors[unit];
    if (factor == null) throw Exception('$runtimeType: $unit is not supported');
    return value / factor;
  }
}

class Angular extends Dimension<Angular> {
  Angular(double value, Unit unit) : super(value, unit);

  static final _factors = <Unit, double>{
    Unit.radian: 1.0,
    Unit.degree: pi / 180,
    Unit.moa: pi / (60 * 180),
    Unit.mil: pi / 3200,
    Unit.mRad: 1.0 / 1000,
    Unit.thousandth: pi / 3000,
    Unit.inchesPer100Yd: 1.0 / 3600,
    Unit.cmPer100m: 1.0 / 10000,
    Unit.oClock: pi / 6,
  };

  @override
  Map<Unit, double> get conversionFactors => _factors;

  @override
  Angular create(double value, Unit unit) => Angular(value, unit);

  @override
  double toRaw(double value, Unit unit) {
    final radians = super.toRaw(value, unit);
    final r = (radians + pi) % (2.0 * pi) - pi;
    return r > -pi ? r : pi;
  }
}
