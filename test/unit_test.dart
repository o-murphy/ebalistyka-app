import 'package:test/test.dart';
import 'dart:math';

import 'package:test_app/src/unit.dart';

void main() {
  group('Angular', () {
    test('degree to radian', () {
      final a = Angular(180, Unit.degree);
      expect(a.in_(Unit.radian), closeTo(pi, 1e-10));
    });

    test('normalization > 2pi', () {
      final a = Angular(360, Unit.degree);
      expect(a.in_(Unit.radian), closeTo(0, 1e-10));
    });

    test('to() returns Angular', () {
      final a = Angular(90, Unit.degree);
      final b = a.to(Unit.moa);
      expect(b, isA<Angular>());
      expect(b.in_(Unit.degree), closeTo(90, 1e-6));
    });
  });
}