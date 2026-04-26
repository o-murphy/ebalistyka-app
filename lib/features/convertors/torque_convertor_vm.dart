import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

class TorqueConvertorViewModel extends SimpleConvertorVm {
  @override
  Unit get baseUnit => Unit.newtonMeter;

  @override
  double getRawBase(ConvertorsState s) => s.torqueValueNewtonMeter;

  @override
  Unit getInputUnit(ConvertorsState s) => s.torqueUnit;

  @override
  Future<void> saveRawBase(double? base) =>
      ref.read(convertorsProvider.notifier).updateTorqueValue(base);

  @override
  Future<void> saveInputUnit(Unit unit) =>
      ref.read(convertorsProvider.notifier).updateTorqueUnit(unit);

  @override
  FieldConstraints getConstraintsForUnit(Unit unit) => FieldConstraints(
    minRaw: FC.convertorTorque.minRaw.convert(Unit.newtonMeter, unit),
    maxRaw: FC.convertorTorque.maxRaw.convert(Unit.newtonMeter, unit),
    stepRaw: FC.convertorTorque.stepRaw.convert(Unit.newtonMeter, unit),
    rawUnit: unit,
    accuracy: FC.convertorTorque.accuracyFor(unit),
  );

  @override
  List<ConvertorSection> buildSections(double rawNm) => [
    ConvertorSection('Metric', [
      fieldFor(
        rawNm,
        Unit.newtonMeter,
        'Newton-meter',
        FC.convertorTorque.accuracyFor(Unit.newtonMeter),
      ),
    ]),
    ConvertorSection('Imperial', [
      fieldFor(
        rawNm,
        Unit.footPoundTorque,
        'Foot-pound',
        FC.convertorTorque.accuracyFor(Unit.footPoundTorque),
      ),
      fieldFor(
        rawNm,
        Unit.inchPound,
        'Inch-pound',
        FC.convertorTorque.accuracyFor(Unit.inchPound),
      ),
    ]),
  ];
}

final torqueConvertorVmProvider =
    NotifierProvider<TorqueConvertorViewModel, SimpleConvertorUiState>(
      TorqueConvertorViewModel.new,
    );
