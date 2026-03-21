import 'package:flutter/material.dart';

class SideControlBlock extends StatelessWidget {
  final IconData topIcon;
  final IconData bottomIcon;
  final List<(IconData, String)> infoRows;
  final VoidCallback onTopPressed;
  final VoidCallback onBottomPressed;

  const SideControlBlock({
    super.key,
    required this.topIcon,
    required this.bottomIcon,
    required this.infoRows,
    required this.onTopPressed,
    required this.onBottomPressed,
  });

  Widget _fab(BuildContext context, IconData icon, VoidCallback onPressed) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: cs.surfaceContainerHighest,
      foregroundColor: cs.onSurface,
      onPressed: onPressed,
      child: Icon(icon, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(4),
      child: Column(
        children: [
          _fab(context, topIcon, onTopPressed),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: infoRows.map((row) {
                final (icon, value) = row;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    if (value.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
          _fab(context, bottomIcon, onBottomPressed),
        ],
      ),
    );
  }
}
