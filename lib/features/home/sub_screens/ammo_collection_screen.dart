import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_ammo_tile_body.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AmmoCollectionScreen extends ConsumerWidget {
  const AmmoCollectionScreen({
    required this.filterBullet,
    this.caliberInch,
    super.key,
  });

  final bool filterBullet;

  /// When provided, only ammo matching this caliber is shown.
  final double? caliberInch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(builtinCollectionProvider);
    final title = filterBullet ? 'Bullet Collection' : 'Cartridge Collection';

    return BaseScreen(
      title: title,
      isSubscreen: true,
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (collection) {
          final all = filterBullet ? collection.bullets : collection.cartridges;
          final items = caliberInch != null
              ? all
                    .where((a) => (a.caliberInch - caliberInch!).abs() < 0.001)
                    .toList()
              : all;

          return BaseCollectionBody(
            tiles: items
                .map(
                  (ammo) => CollectionItemTile(
                    key: ValueKey(ammo.name),
                    body: CollectionAmmoTileBody(ammo: ammo),
                    item: CartridgeCollectionItem(ref: ammo),
                    onSelect: () => context.pop<Ammo>(ammo.clone()),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
