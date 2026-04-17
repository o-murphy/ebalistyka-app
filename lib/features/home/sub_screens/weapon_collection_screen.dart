import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_weapon_tile_body.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WeaponCollectionScreen extends ConsumerWidget {
  const WeaponCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(builtinCollectionProvider);

    return BaseScreen(
      title: 'Weapon Collection',
      isSubscreen: true,
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (collection) => BaseCollectionBody(
          tiles: collection.weapons
              .map(
                (weapon) => CollectionItemTile(
                  key: ValueKey(weapon.name),
                  body: CollectionWeaponTileBody(weapon: weapon),
                  item: WeaponCollectionItem(ref: weapon),
                  searchText: [weapon.name, weapon.vendor ?? ''].join(' '),
                  onSelect: () {
                    context.pop<Weapon>(weapon.clone());
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
