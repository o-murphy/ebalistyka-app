import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CollectionSightTileBody extends ConsumerWidget {
  const CollectionSightTileBody({super.key, required this.sight});

  final Sight sight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(unitFormatterProvider);

    final verticalClick = formatter.click(
      sight.verticalClick,
      sight.verticalClickUnitValue,
    );
    final horizontalClick = formatter.click(
      sight.horizontalClick,
      sight.horizontalClickUnitValue,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Background image placeholder
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Icon(Icons.image_outlined, size: 50, color: Colors.grey),
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
                  sight.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Bottom information
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reticle
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location_outlined, size: 14),
                        SizedBox(width: 6),
                        Text("<reticle>", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 2nd row: vertical_click + height
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_vert_outlined, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              verticalClick,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.height_outlined, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.sightHeight(sight.sightHeight),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 3rd row: horizontal_click + magnification range
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz_outlined, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              horizontalClick,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_outlined, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              formatter.magnificationRange(
                                sight.minMagnification,
                                sight.maxMagnification,
                              ),
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
