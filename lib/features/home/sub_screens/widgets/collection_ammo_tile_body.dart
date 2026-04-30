// name
// projectile name
// Ammo.image (placeholder only for now)
// caliber
// g1bc g7bc muzzlevelocity
// weight
// length

import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/ammo_svg_view.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionAmmoTileBody extends ConsumerWidget {
  const CollectionAmmoTileBody({super.key, required this.ammo});

  final Ammo ammo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background ammo image
          Positioned.fill(child: AmmoSvgView(imageId: ammo.image)),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Vendor + Name - top
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ammo.vendor != null && ammo.vendor!.isNotEmpty)
                        Text(
                          ammo.vendor!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      Text(
                        ammo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                      if (ammo.projectileName != null &&
                          ammo.projectileName!.isNotEmpty)
                        Text(
                          ammo.projectileName!,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Bottom information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First row - BC values and velocity
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildBcRow(
                          'G1 ${l10n.bcShort}',
                          ammo.bcG1,
                          DragType.g1,
                          ammo.dragType == DragType.g1,
                          cs,
                        ),
                        _buildBcRow(
                          'G7 ${l10n.bcShort}',
                          ammo.bcG7,
                          DragType.g7,
                          ammo.dragType == DragType.g7,
                          cs,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.velocity, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.velocity(ammo.mv),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Second row - Caliber, weight, length
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.caliber, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.diameter(ammo.caliber),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.weigth, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.weight(ammo.weight),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.length, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.length(ammo.length),
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.visible,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBcRow(String label, double bc, DragType dt, bool isPrimary, cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label = ${bc > 0 ? bc.toFixedSafe(3) : nullStr}',
          style: TextStyle(
            fontSize: 12,
            color: isPrimary ? cs.primary : null,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        ),
      ],
    );
  }
}
