import 'package:eballistica/core/providers/convertors_notifier.dart';
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
  UnitFormatter get _formatter => ref.read(unitFormatterProvider);

  @override
  LengthConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.lengthValueInch,
      convertorsState.lengthUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateLengthValue(null);
      return;
    }

    final inchesValue = rawValueInInputUnit.convert(
      convertorsState.lengthUnit,
      Unit.inch,
    );
    if (inchesValue >= 0) {
      ref.read(convertorsProvider.notifier).updateLengthValue(inchesValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateLengthUnit(newUnit);
  }

  double? _getDisplayValue(double? rawInches, Unit inputUnit) {
    if (rawInches == null) return null;
    return rawInches.convert(Unit.inch, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInInches = 0.0;
    final maxInInches = 1000000.0.convert(Unit.centimeter, Unit.inch);

    return FieldConstraints(
      minRaw: minInInches.convert(Unit.inch, unit),
      maxRaw: maxInInches.convert(Unit.inch, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.convertorLength.accuracyFor(unit), // Використовуємо FC
    );
  }

  double _getStepForUnit(Unit unit) {
    // Використовуємо крок з FC як основу
    final baseStep = FC.convertorLength.stepRaw;
    return baseStep.convert(Unit.inch, unit);
  }

  String _formatLength(double value, Unit unit) {
    final distance = Distance(value, unit);
    return _formatter.length(distance);
  }

  LengthConvertorUiState _buildState(double rawInches, Unit inputUnit) {
    final inchesRaw = rawInches;

    final centimetersRaw = inchesRaw.convert(Unit.inch, Unit.centimeter);
    final metersRaw = inchesRaw.convert(Unit.inch, Unit.meter);
    final inchesRawValue = inchesRaw.convert(Unit.inch, Unit.inch);
    final feetRaw = inchesRaw.convert(Unit.inch, Unit.foot);
    final yardsRaw = inchesRaw.convert(Unit.inch, Unit.yard);

    return LengthConvertorUiState(
      rawValue: _getDisplayValue(rawInches, inputUnit),
      inputUnit: inputUnit,
      centimeters: LengthField(
        label: 'Centimeters',
        formattedValue: _formatLength(centimetersRaw, Unit.centimeter),
        value: centimetersRaw,
        symbol: Unit.centimeter.symbol,
        decimals: FC.convertorLength.accuracyFor(Unit.centimeter),
      ),
      meters: LengthField(
        label: 'Meters',
        formattedValue: _formatLength(metersRaw, Unit.meter),
        value: metersRaw,
        symbol: Unit.meter.symbol,
        decimals: FC.convertorLength.accuracyFor(Unit.meter),
      ),
      inches: LengthField(
        label: 'Inches',
        formattedValue: _formatLength(inchesRawValue, Unit.inch),
        value: inchesRawValue,
        symbol: Unit.inch.symbol,
        decimals: FC.convertorLength.accuracyFor(Unit.inch),
      ),
      feet: LengthField(
        label: 'Feet',
        formattedValue: _formatLength(feetRaw, Unit.foot),
        value: feetRaw,
        symbol: Unit.foot.symbol,
        decimals: FC.convertorLength.accuracyFor(Unit.foot),
      ),
      yards: LengthField(
        label: 'Yards',
        formattedValue: _formatLength(yardsRaw, Unit.yard),
        value: yardsRaw,
        symbol: Unit.yard.symbol,
        decimals: FC.convertorLength.accuracyFor(Unit.yard),
      ),
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final lengthConvertorVmProvider =
    NotifierProvider<LengthConvertorViewModel, LengthConvertorUiState>(
      LengthConvertorViewModel.new,
    );
