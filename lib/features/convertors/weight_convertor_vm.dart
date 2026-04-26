import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

class WeightConvertorViewModel extends SimpleConvertorVm {
  @override
  Unit get baseUnit => Unit.grain;

  @override
  double getRawBase(ConvertorsState s) => s.weightValueGrain;

  @override
  Unit getInputUnit(ConvertorsState s) => s.weightUnit;

  @override
  Future<void> saveRawBase(double? base) =>
      ref.read(convertorsProvider.notifier).updateWeightValue(base);

  @override
  Future<void> saveInputUnit(Unit unit) =>
      ref.read(convertorsProvider.notifier).updateWeightUnit(unit);

  @override
  FieldConstraints getConstraintsForUnit(Unit unit) => FieldConstraints(
    minRaw: FC.convertorWeight.minRaw.convert(Unit.grain, unit),
    maxRaw: FC.convertorWeight.maxRaw.convert(Unit.grain, unit),
    stepRaw: FC.convertorWeight.stepRaw.convert(Unit.grain, unit),
    rawUnit: unit,
    accuracy: FC.convertorWeight.accuracyFor(unit),
  );

  @override
  List<ConvertorSection> buildSections(double rawGrain) => [
    ConvertorSection('Metric', [
      fieldFor(
        rawGrain,
        Unit.gram,
        'Grams',
        FC.convertorWeight.accuracyFor(Unit.gram),
      ),
      fieldFor(
        rawGrain,
        Unit.kilogram,
        'Kilograms',
        FC.convertorWeight.accuracyFor(Unit.kilogram),
      ),
    ]),
    ConvertorSection('Imperial', [
      fieldFor(
        rawGrain,
        Unit.grain,
        'Grains',
        FC.convertorWeight.accuracyFor(Unit.grain),
      ),
      fieldFor(
        rawGrain,
        Unit.pound,
        'Pounds',
        FC.convertorWeight.accuracyFor(Unit.pound),
      ),
      fieldFor(
        rawGrain,
        Unit.ounce,
        'Ounces',
        FC.convertorWeight.accuracyFor(Unit.ounce),
      ),
    ]),
  ];
}

final weightConvertorVmProvider =
    NotifierProvider<WeightConvertorViewModel, SimpleConvertorUiState>(
      WeightConvertorViewModel.new,
    );
