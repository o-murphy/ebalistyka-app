import 'dart:async';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/unit_dialog_input_field.dart';
import 'package:ebalistyka/shared/widgets/unit_wheel_picker_widget.dart';
import 'package:flutter/material.dart';

/// Hybrid widget combining Wheel Picker and text input at the same time
class UnitHybridPicker extends StatefulWidget {
  const UnitHybridPicker({
    super.key,
    required this.pickerContext,
    this.initialRawValue,
  });

  final UnitPickerContext pickerContext;
  final double? initialRawValue;

  @override
  State<UnitHybridPicker> createState() => _UnitHybridPickerState();
}

class _UnitHybridPickerState extends State<UnitHybridPicker> {
  late TextEditingController _textController;
  late UnitConversionHelper _helper;

  late double _currentRawValue;
  String? _errorText;
  bool _isNullValue = false;

  bool _isUpdatingFromWheel = false;
  bool _isUpdatingFromText = false;

  @override
  void initState() {
    super.initState();
    final ctx = widget.pickerContext;
    _helper = UnitConversionHelper(
      constraints: ctx.constraints,
      displayUnit: ctx.displayUnit,
    );

    _currentRawValue = widget.initialRawValue ?? ctx.constraints.minRaw;
    _isNullValue = widget.initialRawValue == null;

    final initialText = !_isNullValue
        ? _helper.formatDisplayValue(_helper.toDisplay(_currentRawValue))
        : '';
    _textController = TextEditingController(text: initialText);
  }

  // Processing text input
  void _onTextChanged(String text) {
    if (_isUpdatingFromWheel) return;

    final cursorPosition = _textController.selection.baseOffset;

    _isUpdatingFromText = true;
    final (raw, error) = _helper.parseAndValidate(text);

    bool needsUpdate = false;

    if (error != _errorText) {
      _errorText = error;
      needsUpdate = true;
    }

    if (error == null) {
      final newIsNullValue = raw == null;
      if (newIsNullValue != _isNullValue) {
        _isNullValue = newIsNullValue;
        needsUpdate = true;
      }

      if (raw != null && raw != _currentRawValue) {
        _currentRawValue = raw;
        needsUpdate = true;

        if (!_isUpdatingFromWheel) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isUpdatingFromWheel) {
              setState(() {});
            }
          });
        }
      }
    }

    if (needsUpdate && mounted) {
      setState(() {});
    }

    _isUpdatingFromText = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textController.selection.baseOffset != cursorPosition &&
          cursorPosition >= 0) {
        _textController.selection = TextSelection.collapsed(
          offset: cursorPosition.clamp(0, _textController.text.length),
        );
      }
    });
  }

  void _onWheelChanged(double rawValue) {
    if (_isUpdatingFromText) return;

    _isUpdatingFromWheel = true;

    final newText = _helper.formatDisplayValue(_helper.toDisplay(rawValue));

    if (_textController.text != newText) {
      _textController.text = newText;
    }

    setState(() {
      _currentRawValue = rawValue;
      _isNullValue = false;
      _errorText = null;
    });

    _isUpdatingFromWheel = false;
  }

  void _clearField() {
    if (widget.pickerContext.allowNull != true) return;

    _isUpdatingFromWheel = true;
    _textController.clear();
    setState(() {
      _isNullValue = true;
      _errorText = null;
    });
    _isUpdatingFromWheel = false;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctx = widget.pickerContext;
    final sym = ctx.symbol ?? ctx.displayUnit.symbol;

    final canSave =
        _errorText == null && (!_isNullValue || (ctx.allowNull == true));

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
          // Title
          Text(
            ctx.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          // INPUT FIELD (Keyboard)
          UnitDialogInputField(
            controller: _textController,
            constraints: ctx.constraints,
            displayUnit: ctx.displayUnit,
            onChanged: _onTextChanged,
            errorText: _errorText,
            symbol: sym,
            allowNull: ctx.allowNull == true,
            onClear: _clearField,
          ),

          const SizedBox(height: 4),

          // WHEEL (Visual selection)
          UnitWheelPickerWidget(
            constraints: ctx.constraints,
            initialRawValue: _currentRawValue,
            displayUnit: ctx.displayUnit,
            onChanged: _onWheelChanged,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: !canSave
                      ? null
                      : () {
                          ctx.onChanged(_isNullValue ? null : _currentRawValue);
                          Navigator.pop(context);
                        },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void showUnitHybridPickerDialog(UnitPickerContext pickerContext) {
  unawaited(
    showDialog(
      context: pickerContext.buildContext,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: UnitHybridPicker(
          pickerContext: pickerContext,
          initialRawValue: pickerContext.rawValue,
        ),
      ),
    ),
  );
}

Future<void> showNullableUnitHybridDialog(
  BuildContext context, {
  required String label,
  required double? rawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  String? symbol,
  required ValueChanged<double?> onChanged,
}) async {
  final ctx = UnitPickerContext(
    context,
    label: label,
    rawValue: rawValue ?? constraints.minRaw,
    constraints: constraints,
    displayUnit: displayUnit,
    onChanged: onChanged,
    symbol: symbol,
    allowNull: true,
  );

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: UnitHybridPicker(pickerContext: ctx, initialRawValue: rawValue),
    ),
  );
}
