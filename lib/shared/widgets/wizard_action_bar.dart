import 'package:ebalistyka/l10n/app_localizations.dart';
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
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: onDiscard,
              child: Text(l10n.discardButton),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: Text(l10n.confirmButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
