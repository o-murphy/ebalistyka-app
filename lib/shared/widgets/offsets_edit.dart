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

class OffsetsTiles extends StatelessWidget {
  const OffsetsTiles({
    required this.yLabel,
    required this.xLabel,
    required this.unitLabel,
    required this.yRaw,
    required this.xRaw,
    required this.yUnits,
    required this.xUnits,
    required this.onYChanged,
    required this.onXChanged,
    required this.onYUnitChanged,
    required this.onXUnitChanged,
    super.key,
  });

  final String yLabel;
  final String xLabel;
  final String unitLabel;
  final double yRaw;
  final double xRaw;
  final Unit yUnits;
  final Unit xUnits;
  final void Function(double) onYChanged;
  final void Function(double) onXChanged;
  final void Function(Unit) onYUnitChanged;
  final void Function(Unit) onXUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Zeroing offset ────────────────────────────────────────
        listInputLabel(context, yLabel),
        UnitInputWithPicker(
          value: yRaw,
          constraints: FC.adjustment,
          displayUnit: yUnits,
          options: offsetUnits,
          unitLabel: unitLabel,
          onChanged: (v) {
            if (v != null) onYChanged(v);
          },
          onUnitChanged: onYUnitChanged,
        ),
        listInputLabel(context, xLabel),
        UnitInputWithPicker(
          value: xRaw,
          constraints: FC.adjustment,
          displayUnit: xUnits,
          options: offsetUnits,
          unitLabel: unitLabel,
          onChanged: (v) {
            if (v != null) onXChanged(v);
          },
          onUnitChanged: onXUnitChanged,
        ),
      ],
    );
  }
}
