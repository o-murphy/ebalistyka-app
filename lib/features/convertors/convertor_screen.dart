import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ebalistyka/router.dart';

// ─── Convertor tile data ──────────────────────────────────────────────────────

const _convertors = [
  (
    type: 'target-distance',
    label: 'Target Distance',
    icon: IconDef.distanceConvertor,
  ),
  (type: 'velocity', label: 'Velocity', icon: IconDef.velocityConvertor),
  (type: 'length', label: 'Length', icon: IconDef.lengthConvertor),
  (type: 'weight', label: 'Weight', icon: IconDef.weigthConvertor),
  (type: 'pressure', label: 'Pressure', icon: IconDef.pressureConvertor),
  (
    type: 'temperature',
    label: 'Temperature',
    icon: IconDef.temperatureConvertor,
  ),
  (type: 'angular', label: 'Angles', icon: IconDef.angleConvertor),
  (type: 'torque', label: 'Torque', icon: IconDef.torqueConvertor),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ConvertorScreen extends StatelessWidget {
  const ConvertorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Convertors',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _convertors.length,
            itemBuilder: (context, i) => _ConvertorTile(
              type: _convertors[i].type,
              label: _convertors[i].label,
              icon: _convertors[i].icon,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _ConvertorTile extends StatelessWidget {
  const _ConvertorTile({
    required this.type,
    required this.label,
    required this.icon,
  });
  final String type;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.convertorOf(type)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
