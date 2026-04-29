import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart' as fc;
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:flutter/material.dart';
import 'package:bclibc_ffi/unit.dart';

/// Reusable text input field for unit dialogs
class UnitDialogInputField extends StatelessWidget {
  const UnitDialogInputField({
    super.key,
    required this.controller,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.errorText,
    this.symbol,
    this.allowNull = false,
    this.onClear,
  });

  final TextEditingController controller;
  final fc.Constraints constraints;
  final Unit displayUnit;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? symbol;
  final bool allowNull;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sym = symbol ?? displayUnit.localizedSymbol(AppLocalizations.of(context)!);

    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: errorText != null
            ? theme.colorScheme.error
            : theme.colorScheme.primary,
      ),
      decoration: InputDecoration(
        errorText: errorText,
        errorMaxLines: 1,
        hintText: allowNull ? nullStr : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixText: sym,
        suffixStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        suffixIcon: allowNull && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(IconDef.clear, size: 18),
                onPressed: onClear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 16,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
