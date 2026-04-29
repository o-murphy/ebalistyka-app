import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
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
  List<ConvertorSection> buildSections(double rawGrain, AppLocalizations l10n) => [
    ConvertorSection((l10n) => l10n.sectionMetric, [
      fieldFor(rawGrain, Unit.gram, (l10n) => l10n.unitGrams, FC.convertorWeight.accuracyFor(Unit.gram), l10n),
      fieldFor(rawGrain, Unit.kilogram, (l10n) => l10n.unitKilograms, FC.convertorWeight.accuracyFor(Unit.kilogram), l10n),
    ]),
    ConvertorSection((l10n) => l10n.sectionImperial, [
      fieldFor(rawGrain, Unit.grain, (l10n) => l10n.unitGrains, FC.convertorWeight.accuracyFor(Unit.grain), l10n),
      fieldFor(rawGrain, Unit.pound, (l10n) => l10n.unitPounds, FC.convertorWeight.accuracyFor(Unit.pound), l10n),
      fieldFor(rawGrain, Unit.ounce, (l10n) => l10n.unitOunces, FC.convertorWeight.accuracyFor(Unit.ounce), l10n),
    ]),
  ];
}

final weightConvertorVmProvider =
    NotifierProvider<WeightConvertorViewModel, SimpleConvertorUiState>(
      WeightConvertorViewModel.new,
    );
