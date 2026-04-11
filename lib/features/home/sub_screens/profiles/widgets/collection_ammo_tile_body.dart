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
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionAmmoTileBody extends ConsumerWidget {
  const CollectionAmmoTileBody({super.key, required this.ammo});

  final Ammo ammo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background image placeholder
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Icon(IconDef.image, size: 50, color: Colors.grey),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Name - top
                Text(
                  "${ammo.name}\n${ammo.projectileName ?? '—'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Bottom information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "G1 BC = ${ammo.bcG1.toFixedSafe(3)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "G1 BC = ${ammo.bcG1.toFixedSafe(3)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.velocity, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              ammo.mv != null
                                  ? formatter.velocity(ammo.mv!)
                                  : '—',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.caliber, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.diameter(ammo.caliber),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.weigth, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.weight(ammo.weight),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.length, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.length(ammo.length),
                              style: const TextStyle(fontSize: 12),
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
}
