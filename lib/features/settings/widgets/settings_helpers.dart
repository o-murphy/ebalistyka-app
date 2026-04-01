import 'package:flutter/material.dart';

import 'package:eballistica/core/solver/unit.dart';

// ─── Shared widgets for settings sub-screens ─────────────────────────────────

class SettingsUnitTile extends StatelessWidget {
  const SettingsUnitTile({
    super.key,
    required this.icon,
    required this.label,
    required this.current,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Unit current;
  final List<Unit> options;
  final ValueChanged<Unit> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        current.symbol,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      dense: true,
      onTap: () => _showPicker(context),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(label),
        children: options
            .map(
              (u) => RadioGroup<Unit>(
                groupValue: current,
                onChanged: (v) {
                  if (v != null) {
                    onChanged(v);
                    Navigator.pop(ctx);
                  }
                },
                child: RadioListTile<Unit>(
                  value: u,
                  title: Text('${u.label}  (${u.symbol})'),
                  dense: true,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
