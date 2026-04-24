import 'package:flutter/material.dart';

Widget listInputLabel(BuildContext context, String label) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
