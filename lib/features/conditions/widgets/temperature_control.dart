import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/unit_hybrid_picker_dialog.dart';
import 'package:flutter/material.dart';

import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:bclibc_ffi/unit.dart';

// ─── Large temperature control (big ± buttons + tap-to-edit dialog) ───────────

class TempControl extends StatelessWidget {
  const TempControl({
    super.key,
    required this.rawValue,
    required this.displayUnit,
    required this.onChanged,
  });

  final double rawValue;
  final Unit displayUnit;
  final ValueChanged<double> onChanged;

  static final _fc = FC.temperature;

  double get _display => rawValue.convert(_fc.rawUnit, displayUnit);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sym = displayUnit.symbol;
    final inputAcc = _fc.accuracy;
    final l10n = AppLocalizations.of(context)!;

    final UnitPickerContext tempCtx = UnitPickerContext(
      context,
      label: l10n.temperature,
      rawValue: rawValue,
      constraints: _fc,
      displayUnit: displayUnit,
      onChanged: (v) => onChanged(v!),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          icon: const Icon(IconDef.minus),
          onPressed: () =>
              onChanged((rawValue - _fc.stepRaw).clamp(_fc.minRaw, _fc.maxRaw)),
          style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () => showUnitHybridPickerDialog(tempCtx),
          child: Column(
            children: [
              Icon(IconDef.temperature, color: cs.primary),
              const SizedBox(height: 4),
              Text(
                '${_display.toStringAsFixed(inputAcc)} $sym',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                l10n.temperature,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        IconButton.filledTonal(
          icon: const Icon(IconDef.add),
          onPressed: () =>
              onChanged((rawValue + _fc.stepRaw).clamp(_fc.minRaw, _fc.maxRaw)),
          style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
        ),
      ],
    );
  }
}
