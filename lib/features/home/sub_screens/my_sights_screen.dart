import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;

class MySightsCollectionScreen extends ConsumerWidget {
  const MySightsCollectionScreen({super.key});

  // Функція для показу bottom sheet
  Future<void> _showAddSightSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Add Sight',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create new'),
              onTap: () {
                Navigator.pop(ctx);
                debugPrint("Create new sight");
                // TODO: додати навігацію на екран створення
                // context.push(Routes.sightCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Select from collection'),
              onTap: () {
                Navigator.pop(ctx);
                debugPrint("Select sight from collection");
                // TODO: додати логіку вибору з колекції
              },
            ),
            // ListTile(
            //   leading: const Icon(Icons.file_open_outlined),
            //   title: const Text('Import from file'),
            //   onTap: () {
            //     Navigator.pop(ctx);
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('Import not yet available')),
            //     );
            //   },
            // ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final sights = ref.watch(sightsProvider);

    return BaseScreen(
      title: "My Sights",
      isSubscreen: true,
      floatingActionButton: FloatingActionButton(
        heroTag: "generalFab",
        onPressed: () => _showAddSightSheet(context), // викликає bottom sheet
        child: const Icon(Icons.add_outlined),
      ),
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) => BaseCollectionBody(
          tiles: sights
              .map(
                (item) => CollectionItemTile(
                  key: ValueKey(item.id),
                  body: Center(child: Text(item.name)),
                  item: SightCollectionItem(ref: item),
                  onSelect: () => debugPrint("item id: ${item.id} selected"),
                  onEdit: () => debugPrint(
                    "routes to item wizard screen id: ${item.id} selected",
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
