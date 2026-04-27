import 'package:flutter/material.dart';

class WizardActionBar extends StatelessWidget {
  const WizardActionBar({
    required this.onDiscard,
    required this.onSave,
    super.key,
  });

  final VoidCallback onDiscard;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton(onPressed: onDiscard, child: const Text('Discard')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: onSave, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
