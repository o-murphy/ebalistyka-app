import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart' as fc;
import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/unit_value_header.dart';
import 'package:ebalistyka/shared/widgets/unit_wheel_picker_widget.dart';
import 'package:flutter/material.dart';

class UnitWheelPicker extends StatefulWidget {
  const UnitWheelPicker({
    super.key,
    required this.constraints,
    required this.initialRawValue,
    required this.displayUnit,
    required this.onSave,
    this.label,
  });

  final fc.Constraints constraints;
  final double initialRawValue;
  final Unit displayUnit;
  final ValueChanged<double> onSave;
  final String? label;

  @override
  State<UnitWheelPicker> createState() => _UnitWheelPickerState();
}

class _UnitWheelPickerState extends State<UnitWheelPicker> {
  late double _currentRawValue;
  late UnitConversionHelper _helper;

  @override
  void initState() {
    super.initState();
    _currentRawValue = widget.initialRawValue;
    _helper = UnitConversionHelper(
      constraints: widget.constraints,
      displayUnit: widget.displayUnit,
    );
  }

  void _onWheelChanged(double rawValue) {
    setState(() {
      _currentRawValue = rawValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = _helper.toDisplay(_currentRawValue);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      constraints: BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top: Title and Current Value
          if (widget.label != null)
            Text(
              widget.label!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),

          UnitValueHeader(
            isNullValue: false,
            displayValue: displayValue,
            unit: widget.displayUnit,
            symbol: widget.displayUnit.symbol,
            errorText: null,
            accuracy: _helper.accuracy,
          ),

          const SizedBox(height: 16),

          UnitWheelPickerWidget(
            constraints: widget.constraints,
            initialRawValue: _currentRawValue,
            displayUnit: widget.displayUnit,
            onChanged: _onWheelChanged,
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: () {
              widget.onSave(_currentRawValue);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

void showUnitWheelPickerDialog(UnitPickerContext pickerContext) {
  unawaited(
    showDialog(
      context: pickerContext.buildContext,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: UnitWheelPicker(
          label: pickerContext.label,
          constraints: pickerContext.constraints,
          initialRawValue: pickerContext.rawValue,
          displayUnit: pickerContext.displayUnit,
          onSave: pickerContext.onChanged,
        ),
      ),
    ),
  );
}
