import 'package:ebalistyka/shared/consts.dart';
import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:flutter/material.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Refactored dialog using UnitPickerContext ──────────────────────────────

class _UnitEditDialogContent extends StatefulWidget {
  const _UnitEditDialogContent({
    required this.pickerContext,
    required this.initialRawValue,
  });

  final UnitPickerContext pickerContext;
  final double? initialRawValue;

  @override
  State<_UnitEditDialogContent> createState() => _UnitEditDialogContentState();
}

class _UnitEditDialogContentState extends State<_UnitEditDialogContent> {
  late final TextEditingController _controller;
  late final UnitConversionHelper _helper;

  late double _editRaw;
  late bool _isNullValue;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final ctx = widget.pickerContext;

    _helper = UnitConversionHelper(
      constraints: ctx.constraints,
      displayUnit: ctx.displayUnit,
    );

    // IMPORTANT: Use initialRawValue to define the initial state null
    _editRaw = widget.initialRawValue ?? ctx.constraints.minRaw;
    _isNullValue = widget.initialRawValue == null;

    final initialText = widget.initialRawValue != null
        ? _helper.formatDisplayValue(_helper.toDisplay(widget.initialRawValue!))
        : '';

    _controller = TextEditingController(text: initialText);
  }

  void _onTextChanged(String text) {
    final (rawValue, errorText) = _helper.parseAndValidate(text);

    setState(() {
      _errorText = errorText;
      if (errorText == null) {
        _isNullValue = (rawValue == null);
        if (rawValue != null) {
          _editRaw = rawValue;
        }
      } else {
        _isNullValue = false;
      }
    });
  }

  void _step(int dir) {
    setState(() {
      _isNullValue = false;
      _editRaw = (_editRaw + dir * _helper.stepRaw).clamp(
        widget.pickerContext.constraints.minRaw,
        widget.pickerContext.constraints.maxRaw,
      );
      _controller.text = _helper.formatDisplayValue(
        _helper.toDisplay(_editRaw),
      );
      _errorText = null;
    });
  }

  void _clearField() {
    if (widget.pickerContext.allowNull != true) return;
    _controller.clear();
    setState(() {
      _isNullValue = true;
      _errorText = null;
      _editRaw = widget.pickerContext.constraints.minRaw;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctx = widget.pickerContext;
    final sym = ctx.symbol ?? ctx.displayUnit.symbol;
    final accuracy = ctx.constraints.accuracyFor(ctx.displayUnit);

    final canSave =
        _errorText == null && (!_isNullValue || (ctx.allowNull == true));

    String displayHeader;
    Color headerColor;

    if (_errorText != null) {
      displayHeader = "Invalid";
      headerColor = theme.colorScheme.error;
    } else if (_isNullValue) {
      displayHeader = nullStr;
      headerColor = theme.colorScheme.onSurfaceVariant;
    } else {
      displayHeader = _helper.toDisplay(_editRaw).toStringAsFixed(accuracy);
      headerColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ctx.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayHeader,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: headerColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (_errorText == null && !_isNullValue) ...[
                const SizedBox(width: 6),
                Text(
                  sym,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.filledTonal(
                icon: const Icon(IconDef.minus),
                onPressed: () => _step(-1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                  decoration: InputDecoration(
                    errorText: _errorText,
                    errorMaxLines: 2,
                    hintText: ctx.allowNull == true ? nullStr : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon:
                        ctx.allowNull == true && _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(IconDef.clear),
                            onPressed: _clearField,
                            iconSize: 18,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onChanged: _onTextChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(IconDef.plus),
                onPressed: () => _step(1),
              ),
            ],
          ),

          const SizedBox(height: 24),

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
                          ctx.onChanged(_isNullValue ? null : _editRaw);
                          Navigator.pop(context);
                        },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Public dialog functions ─────────────────────────────────────────────────

void showUnitEditDialog(UnitPickerContext pickerContext) {
  showDialog<void>(
    context: pickerContext.buildContext,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _UnitEditDialogContent(
        pickerContext: pickerContext,
        initialRawValue: pickerContext.rawValue,
      ),
    ),
  );
}

Future<void> showNullableUnitEditDialog(
  BuildContext context, {
  required String label,
  required double? rawValue,
  required FieldConstraints constraints,
  required Unit displayUnit,
  String? symbol,
  required ValueChanged<double?> onChanged,
}) async {
  // Create a context. Although internally UnitPickerContext onChanged has type ValueChanged<double>,
  // we wrap our nullable onChanged to avoid a Type Error when passing null.
  final pickerContext = UnitPickerContext(
    context,
    label: label,
    rawValue: rawValue ?? constraints.minRaw,
    constraints: constraints,
    displayUnit: displayUnit,
    onChanged: onChanged,
    symbol: symbol,
    allowNull: true,
  );

  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _UnitEditDialogContent(
        pickerContext: pickerContext,
        initialRawValue: rawValue,
      ),
    ),
  );
}
