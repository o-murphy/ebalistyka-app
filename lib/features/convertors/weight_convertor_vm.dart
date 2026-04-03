// В файлі weight_convertor_vm.dart

import 'package:eballistica/core/providers/convertors_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/formatting/unit_formatter.dart';
import 'package:eballistica/core/providers/formatter_provider.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

// В файлі weight_convertor_vm.dart

class WeightField {
  final String label;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const WeightField({
    required this.label,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}

class WeightConvertorUiState {
  final WeightField grams;
  final WeightField kilograms;
  final WeightField grains;
  final WeightField pounds;
  final WeightField ounces; // Додаємо унції
  final double? rawValue;
  final Unit inputUnit;

  const WeightConvertorUiState({
    required this.grams,
    required this.kilograms,
    required this.grains,
    required this.pounds,
    required this.ounces, // Додаємо
    required this.rawValue,
    required this.inputUnit,
  });
}

class WeightConvertorViewModel extends Notifier<WeightConvertorUiState> {
  UnitFormatter get _formatter => ref.read(unitFormatterProvider);

  @override
  WeightConvertorUiState build() {
    final convertorsState = ref.watch(convertorStateProvider);
    return _buildState(
      convertorsState.weightValueGrain,
      convertorsState.weightUnit,
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    final convertorsState = ref.read(convertorStateProvider);

    if (rawValueInInputUnit == null) {
      ref.read(convertorsProvider.notifier).updateWeightValue(null);
      return;
    }

    final grainsValue = rawValueInInputUnit.convert(
      convertorsState.weightUnit,
      Unit.grain,
    );
    if (grainsValue >= 0) {
      ref.read(convertorsProvider.notifier).updateWeightValue(grainsValue);
    }
  }

  void changeInputUnit(Unit newUnit) {
    ref.read(convertorsProvider.notifier).updateWeightUnit(newUnit);
  }

  double? _getDisplayValue(double? rawGrains, Unit inputUnit) {
    if (rawGrains == null) return null;
    return rawGrains.convert(Unit.grain, inputUnit);
  }

  FieldConstraints getConstraintsForUnit(Unit unit) {
    final minInGrains = 0.0;
    final maxInGrains = 100000.0;

    return FieldConstraints(
      minRaw: minInGrains.convert(Unit.grain, unit),
      maxRaw: maxInGrains.convert(Unit.grain, unit),
      stepRaw: _getStepForUnit(unit),
      rawUnit: unit,
      accuracy: FC.bulletWeight.accuracyFor(unit),
    );
  }

  double _getStepForUnit(Unit unit) {
    final baseStep = FC.bulletWeight.stepRaw;
    return baseStep.convert(Unit.grain, unit);
  }

  String _formatWeight(double value, Unit unit) {
    final weight = Weight(value, unit);
    return _formatter.weight(weight);
  }

  WeightConvertorUiState _buildState(double rawGrains, Unit inputUnit) {
    final grainsRaw = rawGrains;

    final gramsRaw = grainsRaw.convert(Unit.grain, Unit.gram);
    final kilogramsRaw = grainsRaw.convert(Unit.grain, Unit.kilogram);
    final grainsRawValue = grainsRaw.convert(Unit.grain, Unit.grain);
    final poundsRaw = grainsRaw.convert(Unit.grain, Unit.pound);
    final ouncesRaw = grainsRaw.convert(
      Unit.grain,
      Unit.ounce,
    ); // Додаємо конвертацію в унції

    return WeightConvertorUiState(
      rawValue: _getDisplayValue(rawGrains, inputUnit),
      inputUnit: inputUnit,
      grams: WeightField(
        label: 'Grams',
        formattedValue: _formatWeight(gramsRaw, Unit.gram),
        value: gramsRaw,
        symbol: Unit.gram.symbol,
        decimals: FC.bulletWeight.accuracyFor(Unit.gram),
      ),
      kilograms: WeightField(
        label: 'Kilograms',
        formattedValue: _formatWeight(kilogramsRaw, Unit.kilogram),
        value: kilogramsRaw,
        symbol: Unit.kilogram.symbol,
        decimals: FC.bulletWeight.accuracyFor(Unit.kilogram),
      ),
      grains: WeightField(
        label: 'Grains',
        formattedValue: _formatWeight(grainsRawValue, Unit.grain),
        value: grainsRawValue,
        symbol: Unit.grain.symbol,
        decimals: FC.bulletWeight.accuracyFor(Unit.grain),
      ),
      pounds: WeightField(
        label: 'Pounds',
        formattedValue: _formatWeight(poundsRaw, Unit.pound),
        value: poundsRaw,
        symbol: Unit.pound.symbol,
        decimals: FC.bulletWeight.accuracyFor(Unit.pound),
      ),
      ounces: WeightField(
        // Додаємо поле для унцій
        label: 'Ounces',
        formattedValue: _formatWeight(ouncesRaw, Unit.ounce),
        value: ouncesRaw,
        symbol: Unit.ounce.symbol,
        decimals: FC.bulletWeight.accuracyFor(Unit.ounce),
      ),
    );
  }
}

final weightConvertorVmProvider =
    NotifierProvider<WeightConvertorViewModel, WeightConvertorUiState>(
      WeightConvertorViewModel.new,
    );
