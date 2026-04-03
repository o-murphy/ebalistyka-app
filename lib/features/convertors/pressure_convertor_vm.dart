import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

class PressureField {
  final String label;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const PressureField({
    required this.label,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}

class PressureConvertorUiState {
  final PressureField mmHg;
  final PressureField inHg;
  final PressureField bar;
  final PressureField hPa;
  final PressureField psi;
  final PressureField atm;
  final double? rawValue;
  final Unit inputUnit;

  const PressureConvertorUiState({
    required this.mmHg,
    required this.inHg,
    required this.bar,
    required this.hPa,
    required this.psi,
    required this.atm,
    required this.rawValue,
    required this.inputUnit,
  });
}

class PressureConvertorViewModel extends Notifier<PressureConvertorUiState> {
  @override
  PressureConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.pressureValueMmHg,
      convertorsState.pressureUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updatePressureValue(null);
      return;
    }

    final mmHgValue = rawValueInInputUnit.convert(
      convertorsState.pressureUnit,
      Unit.mmHg,
    );
    if (mmHgValue >= 0) {
      ref.read(convertorsProvider.notifier).updatePressureValue(mmHgValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updatePressureUnit(newUnit);
  }

  double? _getDisplayValue(double? rawMmHg, Unit inputUnit) {
    if (rawMmHg == null) return null;
    return rawMmHg.convert(Unit.mmHg, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInMmHg = 0.0;
    final maxInMmHg = 2000.0;

    return FieldConstraints(
      minRaw: minInMmHg.convert(Unit.mmHg, unit),
      maxRaw: maxInMmHg.convert(Unit.mmHg, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.convertorPressure.accuracyFor(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    final baseStep = FC.convertorPressure.stepRaw;
    return baseStep.convert(Unit.mmHg, unit);
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }

  PressureConvertorUiState _buildState(double rawMmHg, Unit inputUnit) {
    final mmHgRaw = rawMmHg;

    final mmHgAccuracy = FC.convertorPressure.accuracyFor(Unit.mmHg);
    final inHgAccuracy = FC.convertorPressure.accuracyFor(Unit.inHg);
    final barAccuracy = FC.convertorPressure.accuracyFor(Unit.bar);
    final hPaAccuracy = FC.convertorPressure.accuracyFor(Unit.hPa);
    final psiAccuracy = FC.convertorPressure.accuracyFor(Unit.psi);
    final atmAccuracy = FC.convertorPressure.accuracyFor(Unit.atm);

    return PressureConvertorUiState(
      rawValue: _getDisplayValue(rawMmHg, inputUnit),
      inputUnit: inputUnit,
      mmHg: PressureField(
        label: 'mmHg',
        formattedValue: _formatValue(mmHgRaw, mmHgAccuracy, Unit.mmHg.symbol),
        value: mmHgRaw,
        symbol: Unit.mmHg.symbol,
        decimals: mmHgAccuracy,
      ),
      inHg: PressureField(
        label: 'inHg',
        formattedValue: _formatValue(
          mmHgRaw.convert(Unit.mmHg, Unit.inHg),
          inHgAccuracy,
          Unit.inHg.symbol,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.inHg),
        symbol: Unit.inHg.symbol,
        decimals: inHgAccuracy,
      ),
      bar: PressureField(
        label: 'Bar',
        formattedValue: _formatValue(
          mmHgRaw.convert(Unit.mmHg, Unit.bar),
          barAccuracy,
          Unit.bar.symbol,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.bar),
        symbol: Unit.bar.symbol,
        decimals: barAccuracy,
      ),
      hPa: PressureField(
        label: 'hPa',
        formattedValue: _formatValue(
          mmHgRaw.convert(Unit.mmHg, Unit.hPa),
          hPaAccuracy,
          Unit.hPa.symbol,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.hPa),
        symbol: Unit.hPa.symbol,
        decimals: hPaAccuracy,
      ),
      psi: PressureField(
        label: 'PSI',
        formattedValue: _formatValue(
          mmHgRaw.convert(Unit.mmHg, Unit.psi),
          psiAccuracy,
          Unit.psi.symbol,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.psi),
        symbol: Unit.psi.symbol,
        decimals: psiAccuracy,
      ),
      atm: PressureField(
        label: 'Atmosphere',
        formattedValue: _formatValue(
          mmHgRaw.convert(Unit.mmHg, Unit.atm),
          atmAccuracy,
          Unit.atm.symbol,
        ),
        value: mmHgRaw.convert(Unit.mmHg, Unit.atm),
        symbol: Unit.atm.symbol,
        decimals: atmAccuracy,
      ),
    );
  }
}

final pressureConvertorVmProvider =
    NotifierProvider<PressureConvertorViewModel, PressureConvertorUiState>(
      PressureConvertorViewModel.new,
    );
