import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/weapon_svg_view.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionWeaponTileBody extends ConsumerWidget {
  const CollectionWeaponTileBody({super.key, required this.weapon});

  final Weapon weapon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider);
    final l10n = AppLocalizations.of(context)!;

    final twistIcon = weapon.isRightHandTwist ? IconDef.twistR : IconDef.twistL;
    final twistStr = formatter.twist(weapon.twist);
    final caliberStr = formatter.diameter(weapon.caliber);
    final barrelLength = weapon.barrelLength;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background weapon image
          Positioned.fill(child: WeaponSvgView(imageId: weapon.image)),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Vendor + Name - top
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (weapon.vendor != null && weapon.vendor!.isNotEmpty)
                      Text(
                        weapon.vendor!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    Text(
                      weapon.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                // Bottom information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: caliber + barrel length
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconDef.caliber, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              caliberStr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        if (barrelLength != null) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(IconDef.length, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                formatter.barrelLength(barrelLength),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Row 2: twist rate + twist direction
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(twistIcon, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              twistStr,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(twistIcon, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              weapon.isRightHandTwist
                                  ? l10n.rightHand
                                  : l10n.leftHand,
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
