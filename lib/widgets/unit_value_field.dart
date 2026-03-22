import 'package:flutter/material.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/unit.dart';

/// A `[−]  value symbol  [+]` input field.
///
/// - [rawValue] / [onChanged] work in [constraints.rawUnit].
/// - [displayUnit] is the currently-selected user unit (from UnitSettings).
///   If [displayUnit] == [constraints.rawUnit], no conversion is done.
/// - min / max / step come from [constraints] and are in the raw unit.
/// - Tapping the value opens a keyboard dialog for direct input.
class UnitValueField extends StatelessWidget {
  const UnitValueField({
    super.key,
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.label,
    this.symbol,
    this.icon,
  });

  final double            rawValue;
  final FieldConstraints  constraints;
  /// Display unit from unitSettingsProvider. Pass same as constraints.rawUnit
  /// for dimensionless quantities (humidity, BC) — no conversion will occur.
  final Unit              displayUnit;
  final ValueChanged<double> onChanged;
  final String            label;
  final String?           symbol;   // override displayed symbol (e.g. '%')
  final IconData?         icon;

  // ── Shorthand getters ───────────────────────────────────────────────────────

  Unit   get _rawUnit  => constraints.rawUnit;
  double get _minRaw   => constraints.minRaw;
  double get _maxRaw   => constraints.maxRaw;
  double get _stepRaw  => constraints.stepRaw;

  // ── Conversion ─────────────────────────────────────────────────────────────

  double _toDisplay(double raw) {
    if (_rawUnit == displayUnit) return raw;
    return (_rawUnit(raw) as dynamic).in_(displayUnit) as double;
  }

  double _toRaw(double display) {
    if (_rawUnit == displayUnit) return display;
    return (displayUnit(display) as dynamic).in_(_rawUnit) as double;
  }

  double get _displayValue => _toDisplay(rawValue);
  int    get _accuracy     => displayUnit.accuracy;
  String get _sym          => symbol ?? displayUnit.symbol;

  // ── Button callbacks ────────────────────────────────────────────────────────

  void _decrement() =>
      onChanged((rawValue - _stepRaw).clamp(_minRaw, _maxRaw));

  void _increment() =>
      onChanged((rawValue + _stepRaw).clamp(_minRaw, _maxRaw));

  // ── Keyboard dialog ─────────────────────────────────────────────────────────

  void _showDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _displayValue.toStringAsFixed(_accuracy),
    );
    final displayMin = _toDisplay(_minRaw);
    final displayMax = _toDisplay(_maxRaw);

    showDialog<void>(
      context: context,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('$label  ($_sym)'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                suffixText: _sym,
                errorText: errorText,
              ),
              onChanged: (text) {
                final parsed = double.tryParse(text.replaceAll(',', '.'));
                setState(() {
                  if (parsed == null) {
                    errorText = 'Invalid number';
                  } else if (parsed < displayMin || parsed > displayMax) {
                    errorText =
                        '${displayMin.toStringAsFixed(_accuracy)} – '
                        '${displayMax.toStringAsFixed(_accuracy)}';
                  } else {
                    errorText = null;
                  }
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: errorText != null
                    ? null
                    : () {
                        final parsed = double.tryParse(
                          controller.text.replaceAll(',', '.'),
                        );
                        if (parsed != null) {
                          onChanged(
                            _toRaw(parsed).clamp(_minRaw, _maxRaw),
                          );
                        }
                        Navigator.pop(ctx);
                      },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final displayText =
        '${_displayValue.toStringAsFixed(_accuracy)} $_sym';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          IconButton.filledTonal(
            onPressed: _decrement,
            icon: const Icon(Icons.remove),
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _showDialog(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 90),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            onPressed: _increment,
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
