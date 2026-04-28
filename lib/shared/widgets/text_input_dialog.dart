import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shows a simple single-line text input dialog.
///
/// Returns the trimmed non-empty string the user confirmed,
/// or `null` if they cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? labelText,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  String? error;
  var touched = false;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final theme = Theme.of(ctx);
        final l10n = AppLocalizations.of(ctx)!;

        void validate() {
          setState(
            () => error = controller.text.trim().isEmpty
                ? l10n.requiredFieldError
                : null,
          );
        }

        void tryConfirm() {
          touched = true;
          validate();
          if (controller.text.trim().isEmpty) return;
          Navigator.of(ctx).pop(controller.text.trim());
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            constraints: BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: labelText,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    errorText: error,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (_) {
                    if (touched) validate();
                  },
                  onSubmitted: (_) => tryConfirm(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: Text(cancelLabel ?? l10n.dismissButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: tryConfirm,
                        child: Text(confirmLabel ?? l10n.confirmButton),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
