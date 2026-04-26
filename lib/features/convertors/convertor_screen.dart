import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ebalistyka/router.dart';

// ─── Convertor tile data ──────────────────────────────────────────────────────

typedef _ConvertorConfig = ({
  String type,
  String Function(AppLocalizations) labelBuilder,
  IconData icon,
});

final List<_ConvertorConfig> _convertors = [
  (
    type: 'target-distance',
    labelBuilder: (l10n) => l10n.targetDistanceConvertorTitle,
    icon: IconDef.distanceConvertor,
  ),
  (
    type: 'velocity',
    labelBuilder: (l10n) => l10n.velocityConvertorTitle,
    icon: IconDef.velocityConvertor,
  ),
  (
    type: 'length',
    labelBuilder: (l10n) => l10n.lengthConvertorTitle,
    icon: IconDef.lengthConvertor,
  ),
  (
    type: 'weight',
    labelBuilder: (l10n) => l10n.weightConvertorTitle,
    icon: IconDef.weigthConvertor,
  ),
  (
    type: 'pressure',
    labelBuilder: (l10n) => l10n.pressureConvertorTitle,
    icon: IconDef.pressureConvertor,
  ),
  (
    type: 'temperature',
    labelBuilder: (l10n) => l10n.temperatureConvertorTitle,
    icon: IconDef.temperatureConvertor,
  ),
  (
    type: 'angular',
    labelBuilder: (l10n) => l10n.anglesConvertorTitle,
    icon: IconDef.angleConvertor,
  ),
  (
    type: 'torque',
    labelBuilder: (l10n) => l10n.torqueConvertorTitle,
    icon: IconDef.torqueConvertor,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ConvertorScreen extends StatelessWidget {
  const ConvertorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: l10n.convertorsScreenTitle,
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
            itemBuilder: (context, i) {
              final config = _convertors[i];
              return _ConvertorTile(
                type: config.type,
                label: config.labelBuilder(l10n),
                icon: config.icon,
              );
            },
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
    final textTheme = Theme.of(context).textTheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.convertorOf(type)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                label,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
