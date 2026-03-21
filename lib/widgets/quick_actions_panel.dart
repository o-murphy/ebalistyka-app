import 'package:flutter/material.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const double outerMargin = 16.0;
    const double spacing = 8.0;

    return Container(
      height: 80,
      margin: const EdgeInsets.only(
        left: outerMargin,
        right: outerMargin,
        bottom: outerMargin,
        top: 4,
      ),
      child: Row(
        children: [
          _buildAction(
            context,
            Icons.air_outlined,
            '5.4 m/s',
            'Wind speed',
            () => print("Wind speed"),
          ),
          const SizedBox(width: spacing),
          _buildAction(
            context,
            Icons.square_foot,
            '0°',
            'Look angle',
            () => print("Look angle"),
          ),
          const SizedBox(width: spacing),
          _buildAction(
            context,
            Icons.flag_outlined,
            '420 m',
            'Target range',
            () => print("Target range"),
          ),
          const SizedBox(width: spacing),
          _buildAction(
            context,
            Icons.av_timer,
            '00:00',
            'Metronome',
            () => print("Metronome"),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: SizedBox.expand(
              child: FloatingActionButton(
                heroTag: null,
                onPressed: onTap,
                backgroundColor: cs.surfaceContainerHighest,
                foregroundColor: cs.onSurface,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 22),
                    if (value.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
