import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/wind_indicator.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        // Обмежуємо висоту: квадрат або половина екрана
        double maxHeight = constraints.maxHeight * 0.55;
        double height = maxHeight; //min(width, maxHeight);

        return Column(
          children: [
            // ВЕРХНЯ СЕКЦІЯ
            Container(
              width: double.infinity,
              height: height,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                // Щоб панель кнопок не конфліктувала з SafeArea,
                // використовуємо внутрішній Column
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: () {},
                              child: const Text(
                                '.338 Lapua Mag 300gr SMK',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () {},
                            icon: const Icon(Icons.rocket_launch_outlined),
                          ),
                        ],
                      ),
                    ),

                    // 1. Верхня частина: Блоки + Колесо
                    Expanded(
                      child: Row(
                        children: [
                          // Лівий блок
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon: Icons.info_outline,
                              bottomIcon: Icons.note_add_outlined,
                              infoRows: const [
                                (Icons.thunderstorm_outlined, ''),
                                (Icons.device_thermostat_outlined, '23°C'),
                                (Icons.terrain_outlined, '150 m'),
                              ],
                              onTopPressed: () => print("Info pressed"),
                              onBottomPressed: () => print("Notes pressed"),
                            ),
                          ),

                          // Центр: Колесо
                          Expanded(
                            flex: 2,
                            child: WindIndicator(
                              onAngleChanged: (degrees, clockFormat) {
                                print("Напрямок: $degrees°");
                              },
                            ),
                          ),

                          // Правий блок
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon: Icons.question_mark_outlined,
                              bottomIcon: Icons.more_horiz_outlined,
                              infoRows: const [
                                (Icons.thunderstorm_outlined, ''),
                                (Icons.water_drop_outlined, '29%'),
                                (Icons.speed_outlined, '992 hPa'),
                              ],
                              onTopPressed: () => print("Help pressed"),
                              onBottomPressed: () => print("Tools pressed"),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Нижня частина: Панель кнопок (Фіксована висота)
                    const QuickActionsPanel(),
                  ],
                ),
              ),
            ),

            // НИЖНЯ СЕКЦІЯ (Скрол)
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [Text("Параметри балістики будуть тут")],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
