import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/convertors_notifier.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:riverpod/riverpod.dart';

class ConvertorSection {
  final String Function(AppLocalizations) titleBuilder;
  final List<GenericConvertorField> fields;

  const ConvertorSection(this.titleBuilder, this.fields);
}

class SimpleConvertorUiState {
  final List<ConvertorSection> sections;
  final double rawValue;
  final Unit inputUnit;

  const SimpleConvertorUiState({
    required this.sections,
    required this.rawValue,
    required this.inputUnit,
  });
}

abstract class SimpleConvertorVm extends Notifier<SimpleConvertorUiState> {
  Unit get baseUnit;

  double getRawBase(ConvertorsState s);
  Unit getInputUnit(ConvertorsState s);

  Future<void> saveRawBase(double? base);
  Future<void> saveInputUnit(Unit unit);

  FieldConstraints getConstraintsForUnit(Unit unit);
  List<ConvertorSection> buildSections(double rawBase);

  @override
  SimpleConvertorUiState build() {
    final s = ref.watch(convertorStateProvider);
    final rawBase = getRawBase(s);
    final inputUnit = getInputUnit(s);
    return SimpleConvertorUiState(
      rawValue: rawBase.convert(baseUnit, inputUnit),
      inputUnit: inputUnit,
      sections: buildSections(rawBase),
    );
  }

  void updateRawValue(double? rawValueInInputUnit) {
    if (rawValueInInputUnit == null) {
      unawaited(saveRawBase(null));
      return;
    }
    final inputUnit = getInputUnit(ref.read(convertorStateProvider));
    final baseValue = rawValueInInputUnit.convert(inputUnit, baseUnit);
    unawaited(saveRawBase(baseValue));
  }

  void changeInputUnit(Unit newUnit) {
    unawaited(saveInputUnit(newUnit));
  }

  GenericConvertorField fieldFor(
    double rawBase,
    Unit toUnit,
    String Function(AppLocalizations) labelBuilder,
    int decimals,
  ) {
    final value = rawBase.convert(baseUnit, toUnit);
    return GenericConvertorField(
      labelBuilder: labelBuilder,
      formattedValue: _fmt(value, decimals, toUnit.symbol),
      value: value,
      symbol: toUnit.symbol,
      decimals: decimals,
    );
  }

  static String _fmt(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }
}
