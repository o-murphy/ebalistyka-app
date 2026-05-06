import 'package:flutter/material.dart';

class OffsetsMessage extends StatelessWidget {
  const OffsetsMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: tt.labelMedium?.copyWith(color: cs.tertiary),
      ),
    );
  }
}
