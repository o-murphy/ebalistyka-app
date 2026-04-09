import 'dart:math' as math;

extension DoubleFormatExtension on double {
  /// Like [toStringAsFixed] but suppresses the negative sign when the value
  /// rounds to zero (e.g. -0.004 with 2 decimals → "0.00" not "-0.00").
  String toFixedSafe(int fractionDigits) {
    final factor = math.pow(10, fractionDigits);
    final rounded = (this * factor).roundToDouble() / factor;
    // Normalize -0.0 → 0.0 by adding positive zero (IEEE 754 rule).
    return (rounded + 0.0).toStringAsFixed(fractionDigits);
  }
}
