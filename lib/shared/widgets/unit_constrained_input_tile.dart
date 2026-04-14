import 'package:ebalistyka/shared/helpers/unit_constrained_convertion_helper.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:bclibc_ffi/unit.dart';

// ── Shared tile logic ───────────────────────────────────────────────────────

/// Базовий клас для тайлів з підтримкою generic типу
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

  String get _sym => symbol ?? displayUnit.symbol;

  /// Отримати display значення для показу (у випадку null повертає '—')
  String _getDisplayText() {
    // Для nullable варіанту rawValue може бути null, але ми не можемо це перевірити в базовому класі
    // Тому цей метод має бути перевизначений в нащадках
    throw UnimplementedError();
  }

  TextStyle? _getDisplayTextStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getDisplayText(), style: _getDisplayTextStyle(theme)),
          const SizedBox(width: 8),
          Icon(IconDef.edit, size: 16, color: theme.colorScheme.primary),
        ],
      ),
      onTap: () => _showDialog(context),
      dense: true,
    );
  }

  void _showDialog(BuildContext context);
}

/// Тайл для обов'язкового значення (не може бути null)
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
  String _getDisplayText() {
    final helper = UnitConversionHelper(
      constraints: constraints,
      displayUnit: displayUnit,
    );
    return '${helper.formatDisplayValue(helper.toDisplay(rawValue))} $_sym';
  }

  @override
  void _showDialog(BuildContext context) => showUnitEditDialog(
    context,
    label: title,
    rawValue: rawValue,
    constraints: constraints,
    displayUnit: displayUnit,
    symbol: symbol,
    onChanged: onChanged,
  );
}

/// Тайл для опціонального значення (може бути null).
///
/// [isRequired] — якщо `true` і значення `null`, тайл підсвічується кольором
/// помилки (червоний icon + текст "Required"). Використовується для полів,
/// які блокують збереження коли порожні.
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
  String _getDisplayText() {
    if (_isEmpty) return isRequired ? 'Required' : '—';

    final helper = UnitConversionHelper(
      constraints: constraints,
      displayUnit: displayUnit,
    );
    return '${helper.formatDisplayValue(helper.toDisplay(rawValue!))} $_sym';
  }

  @override
  TextStyle? _getDisplayTextStyle(ThemeData theme) {
    if (_isEmpty) {
      return theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        color: isRequired
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      );
    }
    return super._getDisplayTextStyle(theme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showError = isRequired && _isEmpty;

    return ListTile(
      tileColor: showError ? theme.colorScheme.tertiaryContainer : null,
      leading: icon != null
          ? Icon(icon, color: showError ? theme.colorScheme.tertiary : null)
          : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getDisplayText(), style: _getDisplayTextStyle(theme)),
          const SizedBox(width: 8),
          Icon(IconDef.edit, size: 16, color: theme.colorScheme.primary),
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
