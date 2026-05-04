import 'package:ebalistyka/shared/helpers/debug_highlight.dart';
import 'package:flutter/material.dart';

class SideControlBlock extends StatelessWidget {
  final IconData topIcon;
  final IconData bottomIcon;
  final List<(IconData, Color, String, String)> infoRows;
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
    return ht(
      FloatingActionButton.small(
        elevation: 1,
        heroTag: null,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _fab(context, topIcon, onTopPressed),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < infoRows.length; i++) ...[
                Icon(infoRows[i].$1, size: 18, color: infoRows[i].$2),
                if (infoRows[i].$3.isNotEmpty)
                  Text(
                    infoRows[i].$3,
                    style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurface.withAlpha(216),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (infoRows[i].$4.isNotEmpty)
                  Text(
                    infoRows[i].$4,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(216),
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (i < infoRows.length - 1) const SizedBox(height: 4),
              ],
            ],
          ),
        ),
        _fab(context, bottomIcon, onBottomPressed),
      ],
    );
  }
}
