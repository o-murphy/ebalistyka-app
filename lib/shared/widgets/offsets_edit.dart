import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/widgets/click_label.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';

const offsetUnits = [
  Unit.mil,
  Unit.moa,
  Unit.mRad,
  Unit.cmPer100m,
  Unit.inPer100Yd,
];

Widget offsetsTile({
  required BuildContext context,
  required String yLabel,
  required String xLabel,
  required String unitLabel,
  required double yRaw,
  required double xRaw,
  required Unit yUnits,
  required Unit xUnits,
  required void Function(double) onYChanged,
  required void Function(double) onXChanged,
  required void Function(Unit) onYUnitChanged,
  required void Function(Unit) onXUnitChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ── Zeroing offset ────────────────────────────────────────
      listInputLabel(context, 'Vertical offset'),
      UnitInputWithPicker(
        value: xRaw,
        constraints: FC.adjustment,
        displayUnit: yUnits,
        options: offsetUnits,
        unitLabel: unitLabel,
        onChanged: (v) {
          if (v != null) onYChanged(v);
        },
        onUnitChanged: onYUnitChanged,
      ),
      listInputLabel(context, 'Horizontal offset'),
      UnitInputWithPicker(
        value: xRaw,
        constraints: FC.adjustment,
        displayUnit: xUnits,
        options: offsetUnits,
        unitLabel: unitLabel,
        onChanged: (v) {
          if (v != null) onYChanged(v);
        },
        onUnitChanged: onXUnitChanged,
      ),
    ],
  );
}
