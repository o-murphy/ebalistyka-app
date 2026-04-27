import 'package:flutter/material.dart';

class WizardNameField extends StatelessWidget {
  const WizardNameField({
    required this.controller,
    required this.label,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          errorText: controller.text.trim().isEmpty ? 'Name is required' : null,
          labelStyle: controller.text.trim().isEmpty
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged != null ? (_) => onChanged!() : null,
      ),
    );
  }
}
