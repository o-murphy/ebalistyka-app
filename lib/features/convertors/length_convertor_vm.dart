import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
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
  List<ConvertorSection> buildSections(double rawInch) => [
    ConvertorSection('Metric', [
      fieldFor(
        rawInch,
        Unit.centimeter,
        'Centimeters',
        FC.convertorLength.accuracyFor(Unit.centimeter),
      ),
      fieldFor(
        rawInch,
        Unit.meter,
        'Meters',
        FC.convertorLength.accuracyFor(Unit.meter),
      ),
    ]),
    ConvertorSection('Imperial', [
      fieldFor(
        rawInch,
        Unit.inch,
        'Inches',
        FC.convertorLength.accuracyFor(Unit.inch),
      ),
      fieldFor(
        rawInch,
        Unit.foot,
        'Feet',
        FC.convertorLength.accuracyFor(Unit.foot),
      ),
      fieldFor(
        rawInch,
        Unit.yard,
        'Yards',
        FC.convertorLength.accuracyFor(Unit.yard),
      ),
    ]),
  ];
}

final lengthConvertorVmProvider =
    NotifierProvider<LengthConvertorViewModel, SimpleConvertorUiState>(
      LengthConvertorViewModel.new,
    );
