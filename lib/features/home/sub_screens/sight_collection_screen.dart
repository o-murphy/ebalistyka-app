import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_sight_tile_body.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SightCollectionScreen extends ConsumerWidget {
  const SightCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(builtinCollectionProvider);

    return BaseScreen(
      title: 'Sight Collection',
      isSubscreen: true,
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (collection) => BaseCollectionBody(
          tiles: collection.sights
              .map(
                (sight) => CollectionItemTile(
                  key: ValueKey(sight.name),
                  body: CollectionSightTileBody(sight: sight),
                  item: SightCollectionItem(ref: sight),
                  onSelect: () async {
                    await ref.read(appStateProvider.notifier).saveSight(sight);
                    if (context.mounted) context.pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
