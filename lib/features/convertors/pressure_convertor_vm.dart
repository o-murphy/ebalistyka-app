import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

class PressureConvertorViewModel extends SimpleConvertorVm {
  @override
  Unit get baseUnit => Unit.mmHg;

  @override
  double getRawBase(ConvertorsState s) => s.pressureValueMmHg;

  @override
  Unit getInputUnit(ConvertorsState s) => s.pressureUnit;

  @override
  Future<void> saveRawBase(double? base) =>
      ref.read(convertorsProvider.notifier).updatePressureValue(base);

  @override
  Future<void> saveInputUnit(Unit unit) =>
      ref.read(convertorsProvider.notifier).updatePressureUnit(unit);

  @override
  FieldConstraints getConstraintsForUnit(Unit unit) => FieldConstraints(
    minRaw: 0.0.convert(Unit.mmHg, unit),
    maxRaw: 2000.0.convert(Unit.mmHg, unit),
    stepRaw: FC.convertorPressure.stepRaw.convert(Unit.mmHg, unit),
    rawUnit: unit,
    accuracy: FC.convertorPressure.accuracyFor(unit),
  );

  @override
  List<ConvertorSection> buildSections(double rawMmHg) => [
    ConvertorSection('Common', [
      fieldFor(
        rawMmHg,
        Unit.atm,
        'Atmosphere',
        FC.convertorPressure.accuracyFor(Unit.atm),
      ),
      fieldFor(
        rawMmHg,
        Unit.hPa,
        'hPa',
        FC.convertorPressure.accuracyFor(Unit.hPa),
      ),
      fieldFor(
        rawMmHg,
        Unit.bar,
        'Bar',
        FC.convertorPressure.accuracyFor(Unit.bar),
      ),
    ]),
    ConvertorSection('Imperial', [
      fieldFor(
        rawMmHg,
        Unit.psi,
        'PSI',
        FC.convertorPressure.accuracyFor(Unit.psi),
      ),
      fieldFor(
        rawMmHg,
        Unit.inHg,
        'inHg',
        FC.convertorPressure.accuracyFor(Unit.inHg),
      ),
      fieldFor(
        rawMmHg,
        Unit.mmHg,
        'mmHg',
        FC.convertorPressure.accuracyFor(Unit.mmHg),
      ),
    ]),
  ];
}

final pressureConvertorVmProvider =
    NotifierProvider<PressureConvertorViewModel, SimpleConvertorUiState>(
      PressureConvertorViewModel.new,
    );
