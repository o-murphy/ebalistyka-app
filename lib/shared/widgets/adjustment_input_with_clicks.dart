import 'dart:async';
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_field.dart';
import 'package:flutter/material.dart';

const _clicksSymbol = 'click';
const _clicksLabel = 'Clicks';

/// Like [UnitInputWithPicker] but also exposes a "Clicks" pseudo-unit.
///
/// [displayUnit] == null means clicks mode; the input field shows the
/// adjustment value divided by [clickSizeRaw] (one click in the raw unit).
/// [onUnitChanged] receives null when the user picks "Clicks".
class AdjustmentInputWithClicks extends StatelessWidget {
  const AdjustmentInputWithClicks({
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.clickSizeRaw,
    required this.options,
    required this.onChanged,
    required this.onUnitChanged,
    this.unitLabel = 'Select Unit',
    super.key,
  });

  final double? rawValue;
  final FieldConstraints constraints;
  final Unit? displayUnit;
  final double clickSizeRaw;
  final List<Unit> options;
  final ValueChanged<double?> onChanged;
  final ValueChanged<Unit?> onUnitChanged;
  final String unitLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: displayUnit == null
          ? _ClicksInputField(
              rawValue: rawValue,
              clickSizeRaw: clickSizeRaw,
              onChanged: onChanged,
            )
          : ConstrainedUnitInputField(
              rawValue: rawValue,
              constraints: constraints,
              displayUnit: displayUnit!,
              onChanged: onChanged,
              hideSymbol: true,
            ),
      trailing: _AdjUnitPickerButton(
        current: displayUnit,
        options: options,
        label: unitLabel,
        onChanged: onUnitChanged,
      ),
      dense: true,
    );
  }
}

// ── Clicks input ─────────────────────────────────────────────────────────────

class _ClicksInputField extends StatefulWidget {
  const _ClicksInputField({
    required this.rawValue,
    required this.clickSizeRaw,
    required this.onChanged,
  });

  final double? rawValue;
  final double clickSizeRaw;
  final ValueChanged<double?> onChanged;

  @override
  State<_ClicksInputField> createState() => _ClicksInputFieldState();
}

class _ClicksInputFieldState extends State<_ClicksInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  double get _clicks => (widget.rawValue != null && widget.clickSizeRaw != 0)
      ? widget.rawValue! / widget.clickSizeRaw
      : 0;

  String _format(double v) => v.toStringAsFixed(0);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(_clicks));
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus && mounted) _submit();
      });
  }

  @override
  void didUpdateWidget(_ClicksInputField old) {
    super.didUpdateWidget(old);
    if ((widget.rawValue != old.rawValue ||
            widget.clickSizeRaw != old.clickSizeRaw) &&
        !_focusNode.hasFocus) {
      _controller.text = _format(_clicks);
    }
  }

  void _submit() {
    final v = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (v != null) widget.onChanged(v * widget.clickSizeRaw);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      textInputAction: TextInputAction.done,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      decoration: const InputDecoration(
        suffixText: _clicksSymbol,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}

// ── Unit picker ───────────────────────────────────────────────────────────────

class _AdjUnitPickerButton extends StatelessWidget {
  const _AdjUnitPickerButton({
    required this.current,
    required this.options,
    required this.label,
    required this.onChanged,
  });

  final Unit? current;
  final List<Unit> options;
  final String label;
  final ValueChanged<Unit?> onChanged;

  @override
  Widget build(BuildContext context) {
    final symbol = current?.symbol ?? _clicksSymbol;
    return SizedBox(
      width: 60,
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  symbol,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(IconDef.dropDown, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    label,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                const TileDivider(),
                ListTile(
                  title: const Text('$_clicksLabel ($_clicksSymbol)'),
                  trailing: current == null ? const Icon(IconDef.apply) : null,
                  onTap: () {
                    onChanged(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...options.map(
                  (unit) => ListTile(
                    title: Text(
                      '${unit.localizedLabel(l10n)} (${unit.localizedSymbol(l10n)})',
                    ),
                    trailing: current == unit
                        ? const Icon(IconDef.apply)
                        : null,
                    onTap: () {
                      onChanged(unit);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
