import 'package:flutter/material.dart';

Widget listInputLabel(BuildContext context, String label) {
  final theme = Theme.of(context);
  final (cs, tt) = (theme.colorScheme, theme.textTheme);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
    child: Text(
      label,
      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
    ),
  );
}
