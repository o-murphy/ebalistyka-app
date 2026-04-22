import 'dart:math';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart' as fc;
import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable wheel picker widget
class UnitWheelPickerWidget extends StatefulWidget {
  const UnitWheelPickerWidget({
    super.key,
    required this.constraints,
    required this.initialRawValue,
    required this.displayUnit,
    required this.onChanged,
  });

  final fc.Constraints constraints;
  final double? initialRawValue;
  final Unit displayUnit;
  final ValueChanged<double> onChanged;

  @override
  State<UnitWheelPickerWidget> createState() => _UnitWheelPickerWidgetState();
}

class _UnitWheelPickerWidgetState extends State<UnitWheelPickerWidget> {
  late FixedExtentScrollController _controller;
  late UnitConversionHelper _helper;
  List<double> _displayValues = [];
  late double _currentRawValue;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _helper = UnitConversionHelper(
      constraints: widget.constraints,
      displayUnit: widget.displayUnit,
    );
    _currentRawValue = widget.initialRawValue ?? widget.constraints.minRaw;
    _generateDisplayValues();
    _currentIndex = _findClosestIndex(_currentRawValue);
    _controller = FixedExtentScrollController(initialItem: _currentIndex);
  }

  void _generateDisplayValues() {
    final minDisplay = _helper.displayMin;
    final maxDisplay = _helper.displayMax;

    double stepDisplay;
    if (widget.constraints is fc.RulerConstraints) {
      final rc = widget.constraints as fc.RulerConstraints;
      final val1 = _helper.toDisplay(rc.minRaw);
      final val2 = _helper.toDisplay(rc.minRaw + rc.stepRaw);
      stepDisplay = (val2 - val1).abs();
    } else {
      stepDisplay = 1 / pow(10, _helper.accuracy);
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
    final displayVal = _helper.toDisplay(rawValue);
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
      _currentRawValue = _helper
          .toRaw(displayValue)
          .clamp(widget.constraints.minRaw, widget.constraints.maxRaw);
    });
    widget.onChanged(_currentRawValue);
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

    return SizedBox(
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
                    _helper.formatDisplayValue(_displayValues[index]),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
    );
  }
}
