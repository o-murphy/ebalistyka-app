import 'package:test/test.dart';
import 'package:bclibc_ffi/unit.dart';

void main() {
  group('Angular normalization', () {
    test('normalization (-pi, pi]', () {
      expect(Angular.degree(181).in_(Unit.degree), closeTo(-179, 1e-9));
      expect(Angular.degree(360).in_(Unit.degree), closeTo(0, 1e-9));
      expect(Angular.degree(-180).in_(Unit.degree), closeTo(180, 1e-9));
    });
  });

  group('Temperature (Non-linear & Delta logic)', () {
    test('Basic conversion', () {
      final c = Temperature.celsius(0);
      expect(c.in_(Unit.fahrenheit), 32.0);
      expect(c.in_(Unit.kelvin), 273.15);
    });
  });

  group('Error Handling', () {
    test('Unsupported unit throws', () {
      final d = Distance.meter(1);
      expect(() => d.in_(Unit.joule), throwsException);
    });
  });

  group('Utility methods', () {
    test('toDouble() returns value in current units', () {
      final p = Pressure.inHg(30);
      expect(p.toDouble(), 30.0);
    });
  });
}
