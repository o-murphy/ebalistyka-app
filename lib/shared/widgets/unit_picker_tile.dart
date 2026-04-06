import 'package:bclibc_ffi/bclibc_ffi.dart';
import 'package:ebalistyka/shared/widgets/unit_picker_button.dart';
import 'package:flutter/material.dart';

/// Обгортка на базі ListTile для використання в налаштуваннях
class UnitPickerListTile extends StatelessWidget {
  const UnitPickerListTile({
    required this.current,
    required this.onChanged,
    required this.options,
    this.label,
    this.icon,
    this.title,
    this.dense = true,
    super.key,
  });

  final Unit current;
  final ValueChanged<Unit> onChanged;
  final List<Unit> options;
  final String? label;
  final IconData? icon;
  final String? title;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null ? Icon(icon) : null,
      title: Text(title ?? label ?? ''),
      trailing: UnitPickerButton(
        current: current,
        onChanged: onChanged,
        options: options,
        label: label ?? title ?? 'Select Unit',
      ),
      dense: dense,
    );
  }
}
