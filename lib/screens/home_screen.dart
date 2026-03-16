import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/wind_indicator.dart';

class SideControlBlock extends StatelessWidget {
  final IconData topIcon;
  final IconData bottomIcon;
  final String label;
  final String value;
  final VoidCallback onTopPressed;
  final VoidCallback onBottomPressed;

  const SideControlBlock({
    super.key,
    required this.topIcon,
    required this.bottomIcon,
    required this.label,
    required this.value,
    required this.onTopPressed,
    required this.onBottomPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Кнопка зверху
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: onTopPressed,
              icon: Icon(topIcon, size: 28),
              // Оновлено: .withValues замість .withOpacity
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.8),
              padding: EdgeInsets.zero,
            ),
          ),

          // Інформаційний текст по центру
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    // Оновлено: .withValues замість .withOpacity
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Кнопка знизу
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: onBottomPressed,
              icon: Icon(bottomIcon, size: 24),
              // Якщо захочеш додати колір і сюди:
              // color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const double outerMargin = 12.0;
    const double spacing = 8.0;

    return Container(
      height: 64,
      margin: const EdgeInsets.only(
        left: outerMargin,
        right: outerMargin,
        bottom: outerMargin,
        top: 4,
      ),
      child: Row(
        children: [
          _buildAction(context, Icons.settings, () => print("Settings")),
          const SizedBox(width: spacing),
          _buildAction(context, Icons.straighten, () => print("Rangefinder")),
          const SizedBox(width: spacing),
          _buildAction(context, Icons.gps_fixed, () => print("Target")),
          const SizedBox(width: spacing),
          _buildAction(context, Icons.balance, () => print("Stability")),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: double.infinity,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 24),
          style: IconButton.styleFrom(
            // ЗАМІНА ТУТ:
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
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
        double maxHeight = constraints.maxHeight * 0.5;
        double height = min(width, maxHeight);

        return Column(
          children: [
            // ВЕРХНЯ СЕКЦІЯ
            Container(
              width: double.infinity,
              height: height,
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
                    // 1. Верхня частина: Блоки + Колесо
                    Expanded(
                      child: Row(
                        children: [
                          // Лівий блок
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon: Icons.add,
                              bottomIcon: Icons.remove,
                              label: "WIND",
                              value: "5.4",
                              onTopPressed: () => print("Wind +"),
                              onBottomPressed: () => print("Wind -"),
                            ),
                          ),

                          // Центр: Колесо
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: WindIndicator(
                                onAngleChanged: (degrees, clockFormat) {
                                  print("Напрямок: $degrees°");
                                },
                              ),
                            ),
                          ),

                          // Правий блок
                          Expanded(
                            flex: 1,
                            child: SideControlBlock(
                              topIcon: Icons.keyboard_arrow_up,
                              bottomIcon: Icons.keyboard_arrow_down,
                              label: "TEMP",
                              value: "15°",
                              onTopPressed: () => print("Temp +"),
                              onBottomPressed: () => print("Temp -"),
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
