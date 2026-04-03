import 'dart:math';
import 'package:flutter/material.dart';
import 'package:eballistica/core/models/field_constraints.dart';
import 'package:eballistica/core/solver/unit.dart';

/// Просте поле вводу з валідацією за констрейнтами
///
/// Використання:
/// ```dart
/// ConstrainedUnitInputField(
///   value: myValue,
///   constraints: myConstraints,
///   displayUnit: currentUnit,
///   label: 'Швидкість',
///   onChanged: (newValue) => setState(() => myValue = newValue),
/// )
/// ```
class ConstrainedUnitInputField extends StatefulWidget {
  const ConstrainedUnitInputField({
    super.key,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    this.label,
    this.hintText,
    this.symbol,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.hideSymbol = false,
  });

  final double? rawValue;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<double?> onChanged;
  final String? label;
  final String? hintText;
  final String? symbol;
  final bool autofocus;
  final bool enabled;
  final Widget? prefixIcon;
  final bool hideSymbol;

  @override
  State<ConstrainedUnitInputField> createState() =>
      _ConstrainedUnitInputFieldState();
}

class _ConstrainedUnitInputFieldState extends State<ConstrainedUnitInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  double? _currentRawValue;
  String? _errorText;

  // Helper методи
  double _toDisplay(double raw) {
    if (widget.constraints.rawUnit == widget.displayUnit) return raw;
    return Dimension.auto(
      raw,
      widget.constraints.rawUnit,
    ).in_(widget.displayUnit);
  }

  double _toRaw(double display) {
    if (widget.constraints.rawUnit == widget.displayUnit) return display;
    return Dimension.auto(
      display,
      widget.displayUnit,
    ).in_(widget.constraints.rawUnit);
  }

  int get _accuracy {
    if (widget.constraints.rawUnit == widget.displayUnit) {
      return widget.constraints.accuracy;
    }
    final stepDisplay =
        (_toDisplay(widget.constraints.minRaw + widget.constraints.stepRaw) -
                _toDisplay(widget.constraints.minRaw))
            .abs();
    if (stepDisplay <= 0) return widget.constraints.accuracy;
    final digits = (-log(stepDisplay) / ln10).ceil();
    return digits < 0 ? 0 : digits;
  }

  double get _dispMin => _toDisplay(widget.constraints.minRaw);
  double get _dispMax => _toDisplay(widget.constraints.maxRaw);
  String get _sym => widget.symbol ?? widget.displayUnit.symbol;

  String _formatDisplayValue(double value) {
    return value.toStringAsFixed(_accuracy);
  }

  void _updateControllerFromValue() {
    if (_currentRawValue != null) {
      _controller.text = _formatDisplayValue(_toDisplay(_currentRawValue!));
    } else {
      _controller.clear();
    }
  }

  void _validateAndSubmit() {
    final text = _controller.text.trim();

    // Порожнє поле = null
    if (text.isEmpty) {
      setState(() {
        _currentRawValue = null;
        _errorText = null;
        widget.onChanged(null);
      });
      return;
    }

    // Парсинг числа
    final parsed = double.tryParse(text.replaceAll(',', '.'));
    if (parsed == null) {
      setState(() {
        _errorText = 'Invalid number';
      });
      return;
    }

    // Перевірка діапазону
    if (parsed < _dispMin - 1e-10 || parsed > _dispMax + 1e-10) {
      setState(() {
        _errorText =
            'Must be between ${_formatDisplayValue(_dispMin)} and ${_formatDisplayValue(_dispMax)}';
      });
      return;
    }

    // Валідне значення
    final clampedRaw = _toRaw(
      parsed,
    ).clamp(widget.constraints.minRaw, widget.constraints.maxRaw);

    setState(() {
      _currentRawValue = clampedRaw;
      _updateControllerFromValue();
      _errorText = null;
      widget.onChanged(_currentRawValue);
      _focusNode.unfocus();
    });
  }

  @override
  void initState() {
    super.initState();
    _currentRawValue = widget.rawValue;
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _updateControllerFromValue();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndSubmit();
      }
    });
  }

  @override
  void didUpdateWidget(ConstrainedUnitInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rawValue != oldWidget.rawValue) {
      _currentRawValue = widget.rawValue;
      _updateControllerFromValue();
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixText: widget.hideSymbol ? null : _sym,
        errorText: _errorText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onSubmitted: (_) => _validateAndSubmit(),
    );
  }
}
