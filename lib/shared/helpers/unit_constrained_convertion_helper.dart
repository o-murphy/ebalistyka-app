// ── Core conversion & validation logic ──────────────────────────────────────

import 'dart:math' as math;

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';

class UnitConversionHelper {
  final Constraints constraints;
  final Unit displayUnit;

  UnitConversionHelper({required this.constraints, required this.displayUnit});

  Unit get _rawUnit => constraints.rawUnit;

  double toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return raw.convert(_rawUnit, displayUnit);
  }

  double toRaw(double display) {
    if (_rawUnit == displayUnit) return display;
    return display.convert(displayUnit, _rawUnit);
  }

  /// Priority is given to accuracyFor from the model, otherwise it calculates dynamically.
  int get accuracy {
    try {
      return constraints.accuracyFor(displayUnit);
    } catch (_) {
      if (_rawUnit == displayUnit) return constraints.accuracy;
      final stepDisplay =
          (toDisplay(constraints.minRaw + constraints.stepRaw) -
                  toDisplay(constraints.minRaw))
              .abs();
      if (stepDisplay <= 0) return constraints.accuracy;
      final digits = (-math.log(stepDisplay) / math.ln10).ceil();
      return digits < 0 ? 0 : digits;
    }
  }

  double get displayMin => toDisplay(constraints.minRaw);
  double get displayMax => toDisplay(constraints.maxRaw);
  double get stepRaw => constraints.stepRaw;

  String formatDisplayValue(double value) =>
      (value == 0.0 ? 0.0 : value).toStringAsFixed(accuracy);

  /// Validates a double value and returns raw.
  double? validateDisplayValue(double displayValue) {
    if (displayValue < displayMin - 1e-10 ||
        displayValue > displayMax + 1e-10) {
      return null;
    }
    return toRaw(displayValue).clamp(constraints.minRaw, constraints.maxRaw);
  }

  /// Parses the string. Returns (rawValue, errorText).
  (double?, String?) parseAndValidate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return (null, null);

    final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
    if (parsed == null) return (null, 'Invalid number');

    if (parsed < displayMin - 1e-10 || parsed > displayMax + 1e-10) {
      return (
        null,
        'Range error: ${formatDisplayValue(displayMin)} — ${formatDisplayValue(displayMax)}',
      );
    }

    final rawValue = toRaw(
      parsed,
    ).clamp(constraints.minRaw, constraints.maxRaw);
    return (rawValue, null);
  }
}
