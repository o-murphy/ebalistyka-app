import 'package:test/test.dart';
import 'package:eballistica/core/solver/unit.dart';

void main() {
  group('Angular normalization', () {
    test('normalization (-pi, pi]', () {
      expect(Angular(181, Unit.degree).in_(Unit.degree), closeTo(-179, 1e-9));
      expect(Angular(360, Unit.degree).in_(Unit.degree), closeTo(0, 1e-9));
      expect(Angular(-180, Unit.degree).in_(Unit.degree), closeTo(180, 1e-9));
    });
  });

  group('Temperature (Non-linear & Delta logic)', () {
    test('Basic conversion', () {
      final c = Temperature(0, Unit.celsius);
      expect(c.in_(Unit.fahrenheit), 32.0);
      expect(c.in_(Unit.kelvin), 273.15);
    });
  });

  group('Error Handling', () {
    test('Unsupported unit throws', () {
      final d = Distance(1, Unit.meter);
      expect(() => d.in_(Unit.joule), throwsException);
    });
  });

  group('Utility methods', () {
    test('toDouble() returns value in current units', () {
      final p = Pressure(30, Unit.inHg);
      expect(p.toDouble(), 30.0);
    });
  });
}
