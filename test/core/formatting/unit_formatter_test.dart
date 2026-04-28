import 'package:test/test.dart';
import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/formatting/unit_formatter_impl.dart';
import 'package:ebalistyka/l10n/app_localizations_en.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:bclibc_ffi/unit.dart';

final _l10n = AppLocalizationsEn();

/// Metric UnitSettings: meter, mps, celsius, hPa, cm (drop), mil, joule, grain, mm (sightHeight)
UnitSettings _metricSettings() =>
    UnitSettings()..sightHeight = Unit.millimeter.name;

/// Imperial UnitSettings
UnitSettings _imperialSettings() => UnitSettings()
  ..velocity = Unit.fps.name
  ..distance = Unit.yard.name
  ..temperature = Unit.fahrenheit.name
  ..pressure = Unit.inHg.name
  ..drop = Unit.inch.name
  ..adjustment = Unit.moa.name
  ..energy = Unit.footPound.name
  ..weight = Unit.gram.name
  ..sightHeight = Unit.inch.name
  ..twist = Unit.inch.name;

void main() {
  group('UnitFormatterImpl — metric defaults', () {
    late UnitFormatter fmt;

    setUp(() {
      fmt = UnitFormatterImpl(_metricSettings(), _l10n);
    });

    // ── Formatted strings ──────────────────────────────────────────────────

    test('velocity() formats m/s', () {
      final v = Velocity.mps(800.0);
      final s = fmt.velocity(v);
      expect(s, contains('m/s'));
      expect(s, contains('800'));
    });

    test('distance() formats meters', () {
      final d = Distance.meter(300.0);
      final s = fmt.distance(d);
      expect(s, contains('m'));
      expect(s, contains('300'));
    });

    test('temperature() formats celsius', () {
      final t = Temperature.celsius(15.0);
      final s = fmt.temperature(t);
      expect(s, contains('°C'));
      expect(s, contains('15'));
    });

    test('temperature() converts from fahrenheit', () {
      final t = Temperature.fahrenheit(32.0);
      final s = fmt.temperature(t);
      // 32°F = 0°C
      expect(s, contains('0'));
      expect(s, contains('°C'));
    });

    test('pressure() formats hPa', () {
      final p = Pressure.hPa(1013.25);
      final s = fmt.pressure(p);
      expect(s, contains('hPa'));
      expect(s, contains('1013'));
    });

    test('drop() formats centimeters', () {
      final d = Distance.foot(-0.5);
      final s = fmt.drop(d);
      expect(s, contains('cm'));
    });

    test('windage() delegates to drop()', () {
      final d = Distance.foot(0.3);
      expect(fmt.windage(d), equals(fmt.drop(d)));
    });

    test('adjustment() formats MIL', () {
      final a = Angular.mil(1.5);
      final s = fmt.adjustment(a);
      expect(s, contains('MIL'));
      expect(s, contains('1.5'));
    });

    test('energy() formats joules', () {
      final e = Energy.joule(3000.0);
      final s = fmt.energy(e);
      expect(s, contains('J'));
      expect(s, contains('3000'));
    });

    test('weight() formats grains', () {
      final w = Weight.grain(175.0);
      final s = fmt.weight(w);
      expect(s, contains('gr'));
      expect(s, contains('175'));
    });

    test('sightHeight() formats millimeters', () {
      final d = Distance.millimeter(38.0);
      final s = fmt.sightHeight(d);
      expect(s, contains('mm'));
      expect(s, contains('38'));
    });

    test('twist() formats with 1: prefix', () {
      final d = Distance.inch(10.0);
      final s = fmt.twist(d);
      expect(s, startsWith('1:'));
      expect(s, contains('in'));
    });

    test('humidity() formats percentage from fraction', () {
      expect(fmt.humidity(Ratio.fraction(0.5)), '50 %');
      expect(fmt.humidity(Ratio.fraction(1.0)), '100 %');
      expect(fmt.humidity(Ratio.fraction(0.0)), '0 %');
    });

    test('mach() formats with 2 decimals', () {
      expect(fmt.mach(0.85), '0.85 Mach');
      expect(fmt.mach(1.0), '1.00 Mach');
    });

    test('time() formats with 3 decimals', () {
      expect(fmt.time(1.234), '1.234 s');
      expect(fmt.time(0.0), '0.000 s');
    });

    // ── Symbols ────────────────────────────────────────────────────────────

    test('symbols return correct unit symbols', () {
      expect(fmt.velocitySymbol, Unit.mps.symbol);
      expect(fmt.distanceSymbol, Unit.meter.symbol);
      expect(fmt.temperatureSymbol, Unit.celsius.symbol);
      expect(fmt.pressureSymbol, Unit.hPa.symbol);
      expect(fmt.dropSymbol, Unit.centimeter.symbol);
      expect(fmt.adjustmentSymbol, Unit.mil.symbol);
      expect(fmt.energySymbol, Unit.joule.symbol);
      expect(fmt.weightSymbol, Unit.grain.symbol);
      expect(fmt.sightHeightSymbol, Unit.millimeter.symbol);
    });
  });

  // ── Imperial settings ──────────────────────────────────────────────────────

  group('UnitFormatterImpl — imperial settings', () {
    late UnitFormatter fmt;

    setUp(() {
      fmt = UnitFormatterImpl(_imperialSettings(), _l10n);
    });

    test('velocity() formats fps', () {
      final v = Velocity.mps(800.0);
      final s = fmt.velocity(v);
      expect(s, contains('ft/s'));
    });

    test('distance() formats yards', () {
      final d = Distance.meter(100.0);
      final s = fmt.distance(d);
      expect(s, contains('yd'));
    });

    test('temperature() formats fahrenheit', () {
      final t = Temperature.celsius(0.0);
      final s = fmt.temperature(t);
      expect(s, contains('°F'));
      expect(s, contains('32'));
    });

    test('pressure() formats inHg', () {
      final p = Pressure.hPa(1013.25);
      final s = fmt.pressure(p);
      expect(s, contains('inHg'));
    });

    test('drop() formats inches', () {
      final d = Distance.foot(1.0);
      final s = fmt.drop(d);
      expect(s, contains('in'));
    });

    test('adjustment() formats MOA', () {
      final a = Angular.mil(1.0);
      final s = fmt.adjustment(a);
      expect(s, contains('MOA'));
    });

    test('energy() formats foot-pounds', () {
      final e = Energy.joule(1000.0);
      final s = fmt.energy(e);
      expect(s, contains('ft·lb'));
    });

    test('symbols reflect imperial settings', () {
      expect(fmt.velocitySymbol, Unit.fps.symbol);
      expect(fmt.distanceSymbol, Unit.yard.symbol);
      expect(fmt.temperatureSymbol, Unit.fahrenheit.symbol);
      expect(fmt.pressureSymbol, Unit.inHg.symbol);
      expect(fmt.dropSymbol, Unit.inch.symbol);
      expect(fmt.adjustmentSymbol, Unit.moa.symbol);
    });
  });

  // ── Input conversion ───────────────────────────────────────────────────────

  group('UnitFormatterImpl — inputToRaw / rawToInput', () {
    late UnitFormatterImpl fmt;

    setUp(() {
      fmt = UnitFormatterImpl(_metricSettings(), _l10n);
    });

    test('velocity: round-trip mps → raw → mps', () {
      const display = 800.0;
      final raw = fmt.inputToRaw(display, InputField.velocity);
      final back = fmt.rawToInput(raw, InputField.velocity);
      expect(back, closeTo(display, 1e-6));
    });

    test('distance: round-trip meter → raw → meter', () {
      const display = 300.0;
      final raw = fmt.inputToRaw(display, InputField.distance);
      final back = fmt.rawToInput(raw, InputField.distance);
      expect(back, closeTo(display, 1e-6));
    });

    test('temperature: round-trip celsius → raw → celsius', () {
      const display = 25.0;
      final raw = fmt.inputToRaw(display, InputField.temperature);
      final back = fmt.rawToInput(raw, InputField.temperature);
      expect(back, closeTo(display, 1e-6));
    });

    test('pressure: round-trip hPa → raw → hPa', () {
      const display = 1013.0;
      final raw = fmt.inputToRaw(display, InputField.pressure);
      final back = fmt.rawToInput(raw, InputField.pressure);
      expect(back, closeTo(display, 1e-6));
    });

    test('humidity: display 50% → raw 0.5', () {
      expect(fmt.inputToRaw(50.0, InputField.humidity), 0.5);
      expect(fmt.rawToInput(0.5, InputField.humidity), 50.0);
    });

    test('bc: passthrough (dimensionless)', () {
      expect(fmt.inputToRaw(0.308, InputField.bc), 0.308);
      expect(fmt.rawToInput(0.308, InputField.bc), 0.308);
    });

    test('lookAngle: passthrough (always degrees)', () {
      expect(fmt.inputToRaw(5.0, InputField.lookAngle), 5.0);
      expect(fmt.rawToInput(5.0, InputField.lookAngle), 5.0);
    });

    test('targetDistance: same as distance round-trip', () {
      const display = 500.0;
      final raw = fmt.inputToRaw(display, InputField.targetDistance);
      final back = fmt.rawToInput(raw, InputField.targetDistance);
      expect(back, closeTo(display, 1e-6));
    });

    test('zeroDistance: same as distance round-trip', () {
      const display = 100.0;
      final raw = fmt.inputToRaw(display, InputField.zeroDistance);
      final back = fmt.rawToInput(raw, InputField.zeroDistance);
      expect(back, closeTo(display, 1e-6));
    });

    test('sightHeight: mm round-trip', () {
      const display = 38.0;
      final raw = fmt.inputToRaw(display, InputField.sightHeight);
      // raw is in millimeters (same as display unit for metric settings)
      expect(raw, closeTo(38.0, 1e-6));
      expect(
        fmt.rawToInput(raw, InputField.sightHeight),
        closeTo(display, 1e-6),
      );
    });

    test('twist: inch round-trip', () {
      const display = 10.0;
      final raw = fmt.inputToRaw(display, InputField.twist);
      expect(raw, closeTo(10.0, 1e-6));
      expect(fmt.rawToInput(raw, InputField.twist), closeTo(display, 1e-6));
    });

    test('bulletWeight: grain round-trip', () {
      const display = 175.0;
      final raw = fmt.inputToRaw(display, InputField.bulletWeight);
      expect(raw, closeTo(175.0, 1e-6));
      expect(
        fmt.rawToInput(raw, InputField.bulletWeight),
        closeTo(display, 1e-6),
      );
    });
  });

  // ── Imperial input conversion ──────────────────────────────────────────────

  group('UnitFormatterImpl — imperial inputToRaw / rawToInput', () {
    late UnitFormatterImpl fmt;

    setUp(() {
      fmt = UnitFormatterImpl(
        UnitSettings()
          ..velocity = Unit.fps.name
          ..distance = Unit.yard.name
          ..temperature = Unit.fahrenheit.name
          ..pressure = Unit.inHg.name
          ..sightHeight = Unit.inch.name,
        _l10n,
      );
    });

    test('velocity: fps display → mps raw', () {
      // 3280.84 fps ≈ 1000 m/s
      final raw = fmt.inputToRaw(3280.84, InputField.velocity);
      expect(raw, closeTo(1000.0, 0.1));
    });

    test('distance: yards display → meters raw', () {
      // 109.36 yd ≈ 100 m
      final raw = fmt.inputToRaw(109.36, InputField.distance);
      expect(raw, closeTo(100.0, 0.1));
    });

    test('temperature: fahrenheit display → celsius raw', () {
      final raw = fmt.inputToRaw(68.0, InputField.temperature);
      expect(raw, closeTo(20.0, 0.1));
    });

    test('pressure: inHg display → hPa raw', () {
      final raw = fmt.inputToRaw(29.92, InputField.pressure);
      expect(raw, closeTo(1013.21, 0.5));
    });

    test('sightHeight: inch display → mm raw', () {
      final raw = fmt.inputToRaw(1.5, InputField.sightHeight);
      // 1.5 in = 38.1 mm
      expect(raw, closeTo(38.1, 0.1));
    });

    test('round-trip for all imperial fields', () {
      for (final field in [
        InputField.velocity,
        InputField.distance,
        InputField.temperature,
        InputField.pressure,
        InputField.sightHeight,
      ]) {
        final display = 100.0;
        final raw = fmt.inputToRaw(display, field);
        final back = fmt.rawToInput(raw, field);
        expect(
          back,
          closeTo(display, 1e-4),
          reason: 'Round-trip failed for $field',
        );
      }
    });
  });

  // ── Edge cases ─────────────────────────────────────────────────────────────

  group('UnitFormatterImpl — edge cases', () {
    late UnitFormatter fmt;

    setUp(() {
      fmt = UnitFormatterImpl(_metricSettings(), _l10n);
    });

    test('zero velocity returns no-data placeholder', () {
      // velocity(0) is intentionally '—' — zero MV has no ballistic meaning.
      expect(fmt.velocity(Velocity.mps(0)), '—');
    });

    test('zero distance and energy format as numeric zero', () {
      expect(fmt.distance(Distance.meter(0)), contains('0'));
      expect(fmt.energy(Energy.joule(0)), contains('0'));
    });

    test('negative drop formats correctly', () {
      final d = Distance.foot(-2.0);
      final s = fmt.drop(d);
      expect(s, contains('-'));
      expect(s, contains('cm'));
    });

    test('default constructor works', () {
      final formatter = UnitFormatterImpl(
        UnitSettings()..sightHeight = Unit.millimeter.name,
        _l10n,
      );
      expect(formatter.velocitySymbol, Unit.mps.symbol);
    });
  });
}
