import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
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
  List<ConvertorSection> buildSections(double rawMmHg, AppLocalizations l10n) =>
      [
        ConvertorSection((l10n) => l10n.sectionCommon, [
          fieldFor(
            rawMmHg,
            Unit.atm,
            (l10n) => l10n.unitAtmosphere,
            FC.convertorPressure.accuracyFor(Unit.atm),
            l10n,
          ),
          fieldFor(
            rawMmHg,
            Unit.hPa,
            (l10n) => l10n.unitHPa,
            FC.convertorPressure.accuracyFor(Unit.hPa),
            l10n,
          ),
          fieldFor(
            rawMmHg,
            Unit.bar,
            (l10n) => l10n.unitBar,
            FC.convertorPressure.accuracyFor(Unit.bar),
            l10n,
          ),
        ]),
        ConvertorSection((l10n) => l10n.sectionImperial, [
          fieldFor(
            rawMmHg,
            Unit.psi,
            (l10n) => l10n.unitPsi,
            FC.convertorPressure.accuracyFor(Unit.psi),
            l10n,
          ),
          fieldFor(
            rawMmHg,
            Unit.inHg,
            (l10n) => l10n.unitInHg,
            FC.convertorPressure.accuracyFor(Unit.inHg),
            l10n,
          ),
          fieldFor(
            rawMmHg,
            Unit.mmHg,
            (l10n) => l10n.unitMmHg,
            FC.convertorPressure.accuracyFor(Unit.mmHg),
            l10n,
          ),
        ]),
      ];
}

final pressureConvertorVmProvider =
    NotifierProvider<PressureConvertorViewModel, SimpleConvertorUiState>(
      PressureConvertorViewModel.new,
    );
