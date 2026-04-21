import 'dart:math' as math;
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/consts.dart';
import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Гібридний віджет, що поєднує Wheel Picker та текстове введення одночасно
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
  late FixedExtentScrollController _scrollController;
  late TextEditingController _textController;
  late UnitConversionHelper _helper;

  List<double> _displayValues = [];
  late double _currentRawValue;
  int _wheelIndex = 0;

  String? _errorText;
  bool _isNullValue = false;
  bool _isWheeling = false; // Прапорець, щоб уникнути циклічного оновлення

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

    _generateDisplayValues();
    _wheelIndex = _findClosestIndex(_currentRawValue);
    _scrollController = FixedExtentScrollController(initialItem: _wheelIndex);

    final initialText = !_isNullValue
        ? _helper.formatDisplayValue(_helper.toDisplay(_currentRawValue))
        : '';
    _textController = TextEditingController(text: initialText);
  }

  void _generateDisplayValues() {
    final minDisplay = _helper.displayMin;
    final maxDisplay = _helper.displayMax;

    double stepDisplay;
    if (widget.pickerContext.constraints is RulerConstraints) {
      final rc = widget.pickerContext.constraints as RulerConstraints;
      final val1 = _helper.toDisplay(rc.minRaw);
      final val2 = _helper.toDisplay(rc.minRaw + rc.stepRaw);
      stepDisplay = (val2 - val1).abs();
    } else {
      stepDisplay = 1 / math.pow(10, _helper.accuracy);
    }

    if (stepDisplay <= 0) stepDisplay = 1.0;

    final List<double> values = [];
    double current = minDisplay;
    int guard = 0;
    // Оптимізація: якщо значень забагато, збільшуємо крок для колеса
    while (current <= maxDisplay + (stepDisplay / 2) && guard < 2000) {
      values.add(current);
      current += stepDisplay;
      guard++;
    }
    _displayValues = values;
  }

  int _findClosestIndex(double rawValue) {
    if (_displayValues.isEmpty) return 0;
    final targetDisplay = _helper.toDisplay(rawValue);
    int closest = 0;
    double minDiff = double.maxFinite;
    for (int i = 0; i < _displayValues.length; i++) {
      final diff = (targetDisplay - _displayValues[i]).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  // Обробка прокрутки колеса
  void _onWheelChanged(int index) {
    if (_isWheeling) return;
    if (index < 0 || index >= _displayValues.length) return;

    final displayVal = _displayValues[index];
    final rawVal = _helper
        .toRaw(displayVal)
        .clamp(
          widget.pickerContext.constraints.minRaw,
          widget.pickerContext.constraints.maxRaw,
        );

    setState(() {
      _wheelIndex = index;
      _currentRawValue = rawVal;
      _isNullValue = false;
      _errorText = null;
      // Оновлюємо текст без тригера _onTextChanged
      _textController.value = _textController.value.copyWith(
        text: _helper.formatDisplayValue(displayVal),
        selection: TextSelection.collapsed(
          offset: _helper.formatDisplayValue(displayVal).length,
        ),
      );
    });
    HapticFeedback.selectionClick();
  }

  // Обробка введення тексту
  void _onTextChanged(String text) {
    final (raw, error) = _helper.parseAndValidate(text);
    setState(() {
      _errorText = error;
      if (error == null) {
        _isNullValue = raw == null;
        if (raw != null) {
          _currentRawValue = raw;
          // Синхронізуємо колесо плавно
          final newIdx = _findClosestIndex(raw);
          if (newIdx != _wheelIndex) {
            _wheelIndex = newIdx;
            _isWheeling = true;
            _scrollController
                .animateToItem(
                  newIdx,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                )
                .then((_) => _isWheeling = false);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Text(
            ctx.label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12), // Зменшено відступ
          // ПОЛЕ ВВОДУ (Клавіатура)
          TextField(
            controller: _textController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
            decoration: InputDecoration(
              errorText: _errorText,
              errorMaxLines: 1,
              hintText: ctx.allowNull == true ? nullStr : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixText: sym,
              suffixIcon:
                  ctx.allowNull == true && _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(IconDef.clear, size: 18),
                      onPressed: () {
                        _textController.clear();
                        setState(() {
                          _isNullValue = true;
                          _errorText = null;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
            ),
            onChanged: _onTextChanged,
          ),

          const SizedBox(height: 4), // Зменшено відступ між вводом та колесом
          // КОЛЕСО (Візуальний вибір)
          SizedBox(
            height: 240, // Дещо зменшено висоту
            child: Stack(
              children: [
                Center(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 40,
                  perspective: 0.006,
                  diameterRatio: 1.2,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: _onWheelChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: _displayValues.length,
                    builder: (context, index) {
                      final isSelected = _wheelIndex == index;
                      return Center(
                        child: Text(
                          _helper.formatDisplayValue(_displayValues[index]),
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.normal,
                            fontSize: isSelected ? 20 : 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12), // Зменшено відступ перед кнопками
          // Кнопки дій
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Скасувати'),
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
                  child: const Text('Зберегти'),
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
