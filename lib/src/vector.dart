import 'dart:math' as math;

class Vector {
  final double x;
  final double y;
  final double z;

  const Vector(this.x, this.y, this.z);

  /// Копіювання вектора (хоча в Dart ми частіше створюємо нові через final)
  Vector copy() => Vector(x, y, z);

  /// Магнітуда (довжина) вектора
  double mag() => math.sqrt(x * x + y * y + z * z);

  // --- Перевантаження операторів для зручності ---

  /// Множення на скаляр: vector * 2.0
  Vector operator *(double a) => Vector(x * a, y * a, z * a);

  /// Додавання векторів: v1 + v2
  Vector operator +(Vector b) => Vector(x + b.x, y + b.y, z + b.z);

  /// Віднімання векторів: v1 - v2
  Vector operator -(Vector b) => Vector(x - b.x, y - b.y, z - b.z);

  /// Унарний мінус (заперечення): -v1
  Vector operator -() => Vector(-x, -y, -z);

  // --- Математичні методи ---

  /// Скалярний добуток (dot product)
  double dot(Vector b) => x * b.x + y * b.y + z * b.z;

  /// Нормалізація вектора (приведення до одиничної довжини)
  Vector norm() {
    final double m = mag();
    if (m.abs() < 1e-10) {
      return Vector(x, y, z);
    }
    return this * (1.0 / m);
  }

  /// Статичний метод для суми довільної кількості векторів
  static Vector sum(Iterable<Vector> vectors) {
    double sumX = 0;
    double sumY = 0;
    double sumZ = 0;

    for (final v in vectors) {
      sumX += v.x;
      sumY += v.y;
      sumZ += v.z;
    }

    return Vector(sumX, sumY, sumZ);
  }

  @override
  String toString() =>
      'Vector(${x.toStringAsFixed(4)}, ${y.toStringAsFixed(4)}, ${z.toStringAsFixed(4)})';

  // Константи для зручності
  static const zero = Vector(0, 0, 0);
}
