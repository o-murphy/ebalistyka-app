import 'package:ebalistyka/core/extensions/unit_label_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Shared tile logic ───────────────────────────────────────────────────────

/// Base class for tiles with generic type support
abstract class UnitValueFieldTileBase<T> extends StatelessWidget {
  const UnitValueFieldTileBase({
    required this.rawValue,
    required this.constraints,
    required this.displayUnit,
    required this.onChanged,
    required this.title,
    this.symbol,
    this.icon,
    this.subtitle,
    super.key,
  });

  final T rawValue;
  final FieldConstraints constraints;
  final Unit displayUnit;
  final ValueChanged<T> onChanged;
  final String title;
  final String? symbol;
  final IconData? icon;
  final String? subtitle;

  String _sym(BuildContext context) =>
      symbol ?? displayUnit.localizedSymbol(AppLocalizations.of(context)!);

  /// Get display value to display (in case of null returns nullStr)
  String _getDisplayText(BuildContext context) {
    // For nullable, rawValue can be null, but we can't check for it in the base class
    // Therefore, this method must be overridden in descendants
    throw UnimplementedError();
  }

  TextStyle? _getDisplayTextStyle(ColorScheme cs, TextTheme tt) =>
      tt.bodyMedium?.copyWith(fontFamily: 'monospace');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getDisplayText(context), style: _getDisplayTextStyle(cs, tt)),
          const SizedBox(width: 8),
          Icon(IconDef.edit, size: 16, color: cs.primary),
        ],
      ),
      onTap: () => _showDialog(context),
      dense: true,
    );
  }

  void _showDialog(BuildContext context);
}

/// Tile for required value (cannot be null)
class UnitValueFieldTile extends UnitValueFieldTileBase<double> {
  const UnitValueFieldTile({
    super.key,
    required super.rawValue,
    required super.constraints,
    required super.displayUnit,
    required super.onChanged,
    required super.title,
    super.symbol,
    super.icon,
    super.subtitle,
  });

  @override
  String _getDisplayText(BuildContext context) {
    final helper = UnitConversionHelper(
      constraints: constraints,
      displayUnit: displayUnit,
    );
    return '${helper.formatDisplayValue(helper.toDisplay(rawValue))} ${_sym(context)}';
  }

  @override
  void _showDialog(BuildContext context) => showUnitEditDialog(
    UnitPickerContext(
      context,
      label: title,
      rawValue: rawValue,
      constraints: constraints,
      displayUnit: displayUnit,
      symbol: symbol,
      onChanged: (v) => onChanged(v!),
    ),
  );
}

/// Tile for optional value (can be null).
///
/// [isRequired] — if `true` and value `null`, tile is highlighted in
/// error color (red icon + text "Required"). Used for fields
/// that block saving when empty.
class NullableUnitValueFieldTile extends UnitValueFieldTileBase<double?> {
  const NullableUnitValueFieldTile({
    super.key,
    required super.rawValue,
    required super.constraints,
    required super.displayUnit,
    required super.onChanged,
    required super.title,
    super.symbol,
    super.icon,
    super.subtitle,
    this.isRequired = false,
  });

  final bool isRequired;

  bool get _isEmpty => rawValue == null;

  @override
  String _getDisplayText(BuildContext context) {
    if (_isEmpty) return isRequired ? 'Required' : nullStr;

    final helper = UnitConversionHelper(
      constraints: constraints,
      displayUnit: displayUnit,
    );
    return '${helper.formatDisplayValue(helper.toDisplay(rawValue!))} ${_sym(context)}';
  }

  @override
  TextStyle? _getDisplayTextStyle(ColorScheme cs, TextTheme tt) {
    if (_isEmpty) {
      return tt.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        color: isRequired ? cs.error : cs.onSurfaceVariant,
      );
    }
    return super._getDisplayTextStyle(cs, tt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);
    final showError = isRequired && _isEmpty;

    return ListTile(
      tileColor: showError ? cs.tertiaryContainer : null,
      leading: icon != null
          ? Icon(icon, color: showError ? cs.tertiary : null)
          : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getDisplayText(context), style: _getDisplayTextStyle(cs, tt)),
          const SizedBox(width: 8),
          Icon(IconDef.edit, size: 16, color: cs.primary),
        ],
      ),
      onTap: () => _showDialog(context),
      dense: true,
    );
  }

  @override
  void _showDialog(BuildContext context) => showNullableUnitEditDialog(
    context,
    label: title,
    rawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    onChanged: onChanged,
  );
}
