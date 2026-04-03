import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class LengthField {
  final String label;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const LengthField({
    required this.label,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}

class LengthConvertorUiState {
  final LengthField centimeters;
  final LengthField meters;
  final LengthField inches;
  final LengthField feet;
  final LengthField yards;
  final double? rawValue;
  final Unit inputUnit;

  const LengthConvertorUiState({
    required this.centimeters,
    required this.meters,
    required this.inches,
    required this.feet,
    required this.yards,
    required this.rawValue,
    required this.inputUnit,
  });
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LengthConvertorViewModel extends Notifier<LengthConvertorUiState> {
  double? _rawInches; // Завжди зберігаємо в дюймах (raw unit для Distance)
  Unit _inputUnit = Unit.centimeter;

  UnitFormatter get _formatter => ref.read(unitFormatterProvider);

  @override
  LengthConvertorUiState build() {
    // 100 см = 39.37 дюймів
    _rawInches = 100.0.convert(Unit.centimeter, Unit.inch);
    return _buildState();
  }

  void updateRawValue(double? rawValueInInputUnit) {
    if (rawValueInInputUnit == null) {
      _rawInches = null;
      state = _buildState();
      return;
    }

    // Конвертуємо з поточної одиниці вводу в дюйми
    final inchesValue = rawValueInInputUnit.convert(_inputUnit, Unit.inch);
    if (inchesValue >= 0) {
      _rawInches = inchesValue;
      state = _buildState();
    }
  }

  void changeInputUnit(Unit newUnit) {
    if (_inputUnit == newUnit) return;

    // Конвертуємо поточне значення зі старої одиниці в нову
    if (_rawInches != null) {
      final valueInNewUnit = _rawInches!.convert(Unit.inch, newUnit);
      // Залишаємо _rawInches незмінним
    }

    _inputUnit = newUnit;
    state = _buildState();
  }

  double? _getDisplayValue() {
    if (_rawInches == null) return null;
    return _rawInches!.convert(Unit.inch, _inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInInches = 0.0;
    final maxInInches = 1000000.0.convert(
      Unit.centimeter,
      Unit.inch,
    ); // 10 км в дюймах

    return FieldConstraints(
      minRaw: minInInches.convert(Unit.inch, unit),
      maxRaw: maxInInches.convert(Unit.inch, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: _getAccuracyForUnit(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    switch (unit) {
      case Unit.centimeter:
        return 0.1;
      case Unit.meter:
        return 0.01;
      case Unit.inch:
        return 0.1;
      case Unit.foot:
        return 0.1;
      case Unit.yard:
        return 0.1;
      default:
        return 1.0;
    }
  }

  int _getAccuracyForUnit(Unit unit) {
    switch (unit) {
      case Unit.centimeter:
        return 1;
      case Unit.meter:
        return 3;
      case Unit.inch:
        return 2;
      case Unit.foot:
        return 2;
      case Unit.yard:
        return 2;
      default:
        return 2;
    }
  }

  String _formatLength(double value, Unit unit) {
    final distance = Distance(value, unit);
    return _formatter.length(distance);
  }

  LengthConvertorUiState _buildState() {
    final inchesRaw = _rawInches ?? 0.0;

    final centimetersRaw = inchesRaw.convert(Unit.inch, Unit.centimeter);
    final metersRaw = inchesRaw.convert(Unit.inch, Unit.meter);
    final inchesRawValue = inchesRaw.convert(Unit.inch, Unit.inch);
    final feetRaw = inchesRaw.convert(Unit.inch, Unit.foot);
    final yardsRaw = inchesRaw.convert(Unit.inch, Unit.yard);

    return LengthConvertorUiState(
      rawValue: _getDisplayValue(),
      inputUnit: _inputUnit,
      centimeters: LengthField(
        label: 'Centimeters',
        formattedValue: _formatLength(centimetersRaw, Unit.centimeter),
        value: centimetersRaw,
        symbol: Unit.centimeter.symbol,
        decimals: FC.bulletLength.accuracyFor(Unit.centimeter),
      ),
      meters: LengthField(
        label: 'Meters',
        formattedValue: _formatLength(metersRaw, Unit.meter),
        value: metersRaw,
        symbol: Unit.meter.symbol,
        decimals: FC.bulletLength.accuracyFor(Unit.meter),
      ),
      inches: LengthField(
        label: 'Inches',
        formattedValue: _formatLength(inchesRawValue, Unit.inch),
        value: inchesRawValue,
        symbol: Unit.inch.symbol,
        decimals: FC.bulletLength.accuracyFor(Unit.inch),
      ),
      feet: LengthField(
        label: 'Feet',
        formattedValue: _formatLength(feetRaw, Unit.foot),
        value: feetRaw,
        symbol: Unit.foot.symbol,
        decimals: FC.bulletLength.accuracyFor(Unit.foot),
      ),
      yards: LengthField(
        label: 'Yards',
        formattedValue: _formatLength(yardsRaw, Unit.yard),
        value: yardsRaw,
        symbol: Unit.yard.symbol,
        decimals: FC.bulletLength.accuracyFor(Unit.yard),
      ),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final lengthConvertorVmProvider =
    NotifierProvider<LengthConvertorViewModel, LengthConvertorUiState>(
      LengthConvertorViewModel.new,
    );
