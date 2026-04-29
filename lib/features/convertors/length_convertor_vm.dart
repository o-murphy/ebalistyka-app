import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

class LengthConvertorViewModel extends SimpleConvertorVm {
  @override
  Unit get baseUnit => Unit.inch;

  @override
  double getRawBase(ConvertorsState s) => s.lengthValueInch;

  @override
  Unit getInputUnit(ConvertorsState s) => s.lengthUnit;

  @override
  Future<void> saveRawBase(double? base) =>
      ref.read(convertorsProvider.notifier).updateLengthValue(base);

  @override
  Future<void> saveInputUnit(Unit unit) =>
      ref.read(convertorsProvider.notifier).updateLengthUnit(unit);

  @override
  FieldConstraints getConstraintsForUnit(Unit unit) => FieldConstraints(
    minRaw: FC.convertorLength.minRaw.convert(Unit.inch, unit),
    maxRaw: FC.convertorLength.maxRaw.convert(Unit.inch, unit),
    stepRaw: FC.convertorLength.stepRaw.convert(Unit.inch, unit),
    rawUnit: unit,
    accuracy: FC.convertorLength.accuracyFor(unit),
  );

  @override
  List<ConvertorSection> buildSections(double rawInch, AppLocalizations l10n) => [
    ConvertorSection((l10n) => l10n.sectionMetric, [
      fieldFor(rawInch, Unit.centimeter, (l10n) => l10n.unitCentimeters, FC.convertorLength.accuracyFor(Unit.centimeter), l10n),
      fieldFor(rawInch, Unit.meter, (l10n) => l10n.unitMeters, FC.convertorLength.accuracyFor(Unit.meter), l10n),
    ]),
    ConvertorSection((l10n) => l10n.sectionImperial, [
      fieldFor(rawInch, Unit.inch, (l10n) => l10n.unitInches, FC.convertorLength.accuracyFor(Unit.inch), l10n),
      fieldFor(rawInch, Unit.foot, (l10n) => l10n.unitFeet, FC.convertorLength.accuracyFor(Unit.foot), l10n),
      fieldFor(rawInch, Unit.yard, (l10n) => l10n.unitYards, FC.convertorLength.accuracyFor(Unit.yard), l10n),
    ]),
  ];
}

final lengthConvertorVmProvider =
    NotifierProvider<LengthConvertorViewModel, SimpleConvertorUiState>(
      LengthConvertorViewModel.new,
    );
