import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/convertors_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

class TemperatureConvertorViewModel extends SimpleConvertorVm {
  @override
  Unit get baseUnit => Unit.fahrenheit;

  @override
  double getRawBase(ConvertorsState s) => s.temperatureValueF;

  @override
  Unit getInputUnit(ConvertorsState s) => s.temperatureUnit;

  @override
  Future<void> saveRawBase(double? base) =>
      ref.read(convertorsProvider.notifier).updateTemperatureValue(base);

  @override
  Future<void> saveInputUnit(Unit unit) =>
      ref.read(convertorsProvider.notifier).updateTemperatureUnit(unit);

  @override
  FieldConstraints getConstraintsForUnit(Unit unit) {
    const minInFahrenheit = -459.67; // absolute zero
    const maxInFahrenheit = 10000.0;
    const step = 0.1;
    const decimals = 1;
    return FieldConstraints(
      minRaw: minInFahrenheit.convert(Unit.fahrenheit, unit),
      maxRaw: maxInFahrenheit.convert(Unit.fahrenheit, unit),
      stepRaw: step.convert(Unit.fahrenheit, unit),
      rawUnit: unit,
      accuracy: decimals,
    );
  }

  @override
  List<ConvertorSection> buildSections(double rawFahrenheit) => [
    ConvertorSection((l10n) => l10n.sectionMetric, [
      fieldFor(rawFahrenheit, Unit.celsius, (l10n) => l10n.unitCelsius, 1),
    ]),
    ConvertorSection((l10n) => l10n.sectionImperial, [
      fieldFor(
        rawFahrenheit,
        Unit.fahrenheit,
        (l10n) => l10n.unitFahrenheit,
        1,
      ),
    ]),
  ];
}

final temperatureConvertorVmProvider =
    NotifierProvider<TemperatureConvertorViewModel, SimpleConvertorUiState>(
      TemperatureConvertorViewModel.new,
    );
