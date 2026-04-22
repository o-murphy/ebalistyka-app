import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:flutter/material.dart';

class UnitPickerContext {
  const UnitPickerContext(
    this.buildContext, {
    required this.label,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    this.symbol,
    this.allowNull,
  });

  final BuildContext buildContext;
  final String label;
  final double rawValue;
  final Constraints constraints;
  final Unit displayUnit;
  final String? symbol;
  final bool? allowNull;
  final ValueChanged<double?> onChanged;
}
