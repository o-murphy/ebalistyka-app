import 'dart:async';
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:flutter/material.dart';

/// Widget for selecting a unit of measurement from BottomSheet
class UnitPickerButton extends StatelessWidget {
  const UnitPickerButton({
    required this.current,
    this.onChanged,
    this.options,
    this.label = 'Select Unit',
    this.width = 60,
    super.key,
  });

  final Unit current;
  final ValueChanged<Unit>? onChanged;
  final List<Unit>? options;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onChanged == null || options == null
            ? null
            : () => showUnitPicker(
                context,
                label: label,
                current: current,
                options: options!,
                onChanged: onChanged!,
              ),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  current.symbol,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.primary,
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
}

void showUnitPicker(
  BuildContext context, {
  required String label,
  required Unit current,
  required List<Unit> options,
  required ValueChanged<Unit> onChanged,
}) {
  unawaited(
    showModalBottomSheet(
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
                child: Text(label, style: Theme.of(ctx).textTheme.titleMedium),
              ),
              const TileDivider(),
              ...options.map(
                (unit) => ListTile(
                  title: Text(
                    '${unit.localizedLabel(l10n)} (${unit.localizedSymbol(l10n)})',
                  ),
                  trailing: current == unit ? const Icon(IconDef.apply) : null,
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
