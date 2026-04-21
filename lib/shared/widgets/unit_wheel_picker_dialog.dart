import 'dart:math';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnitWheelPicker extends StatefulWidget {
  const UnitWheelPicker({
    super.key,
    required this.constraints,
    required this.initialRawValue,
    required this.displayUnit,
    required this.onSave,
    this.label,
  });

  final FieldConstraints constraints;
  final double initialRawValue;
  final Unit displayUnit;
  final ValueChanged<double> onSave;
  final String? label;

  @override
  State<UnitWheelPicker> createState() => _UnitWheelPickerState();
}

class _UnitWheelPickerState extends State<UnitWheelPicker> {
  late FixedExtentScrollController _controller;
  List<double> _displayValues = [];
  late double _currentRawValue;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentRawValue = widget.initialRawValue;
    _generateDisplayValues();
    _currentIndex = _findClosestIndex(_currentRawValue);
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  void _generateDisplayValues() {
    final minDisplay = widget.constraints.minRaw.convert(
      widget.constraints.rawUnit,
      widget.displayUnit,
    );
    final maxDisplay = widget.constraints.maxRaw.convert(
      widget.constraints.rawUnit,
      widget.displayUnit,
    );

    double stepDisplay;
    if (widget.constraints is RulerConstraints) {
      final rc = widget.constraints as RulerConstraints;
      final val1 = rc.minRaw.convert(rc.rawUnit, widget.displayUnit);
      final val2 = (rc.minRaw + rc.stepRaw).convert(
        rc.rawUnit,
        widget.displayUnit,
      );
      stepDisplay = (val2 - val1).abs();
    } else {
      final accuracy = widget.constraints.accuracyFor(widget.displayUnit);
      stepDisplay = 1 / pow(10, accuracy);
    }

    if (stepDisplay <= 0) stepDisplay = 1.0;

    final List<double> values = [];
    double current = minDisplay;
    int safetyGuard = 0;
    while (current <= maxDisplay + (stepDisplay / 2) && safetyGuard < 5000) {
      values.add(current);
      current += stepDisplay;
      safetyGuard++;
    }
    _displayValues = values;
  }

  int _findClosestIndex(double rawValue) {
    if (_displayValues.isEmpty) return 0;
    final displayVal = rawValue.convert(
      widget.constraints.rawUnit,
      widget.displayUnit,
    );
    int closest = 0;
    double minDiff = double.maxFinite;
    for (int i = 0; i < _displayValues.length; i++) {
      final diff = (displayVal - _displayValues[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  void _handleSelectedItemChanged(int index) {
    if (index < 0 || index >= _displayValues.length) return;
    setState(() {
      _currentIndex = index;
      final displayValue = _displayValues[index];
      _currentRawValue = displayValue
          .convert(widget.displayUnit, widget.constraints.rawUnit)
          .clamp(widget.constraints.minRaw, widget.constraints.maxRaw);
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = widget.constraints.accuracyFor(widget.displayUnit);
    final currentDisplayValue = _currentRawValue.convert(
      widget.constraints.rawUnit,
      widget.displayUnit,
    );

    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 8),
          Text(
            '${currentDisplayValue.toStringAsFixed(accuracy)} ${widget.displayUnit.symbol}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          // Посередині: Колесо
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: 44,
                  perspective: 0.005,
                  diameterRatio: 1.2,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: _handleSelectedItemChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _displayValues.length,
                    builder: (context, index) {
                      final isSelected = _currentIndex == index;
                      return Center(
                        child: Text(
                          _displayValues[index].toStringAsFixed(accuracy),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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
  );
}
