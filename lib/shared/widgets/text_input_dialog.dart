import 'package:flutter/material.dart';

/// Shows a simple single-line text input dialog.
///
/// Returns the trimmed non-empty string the user confirmed,
/// or `null` if they cancelled.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String labelText = 'Name',
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  String? error;
  var touched = false;

  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void validate() {
          setState(
            () => error = controller.text.trim().isEmpty ? 'Required' : null,
          );
        }

        void tryConfirm() {
          touched = true;
          validate();
          if (controller.text.trim().isEmpty) return;
          Navigator.of(ctx).pop(controller.text.trim());
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(),
              errorText: error,
            ),
            onChanged: (_) {
              if (touched) validate();
            },
            onSubmitted: (_) => tryConfirm(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(cancelLabel),
            ),
            FilledButton(onPressed: tryConfirm, child: Text(confirmLabel)),
          ],
        );
      },
    ),
  );
}
