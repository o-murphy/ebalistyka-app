import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;

class MyAmmoScreen extends ConsumerWidget {
  const MyAmmoScreen({super.key});

  // Функція для показу bottom sheet
  Future<void> _showAddAmmoSheet(BuildContext context) async {
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
                'Add Ammo',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create new'),
              onTap: () {
                Navigator.pop(ctx);
                debugPrint("Create new ammo");
                // TODO: додати навігацію на екран створення
                // context.push(Routes.ammoCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Select cartridge from collection'),
              onTap: () {
                Navigator.pop(ctx);
                debugPrint("Select cartridge from collection");
                // TODO: додати логіку вибору картриджа з колекції
              },
            ),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: const Text('Select bullet from collection'),
              onTap: () {
                Navigator.pop(ctx);
                debugPrint("Select bullet from collection");
                // TODO: додати логіку вибору кулі з колекції
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
    final cartridges = ref.watch(cartridgesProvider);

    return BaseScreen(
      title: "My Ammo",
      isSubscreen: true,
      floatingActionButton: FloatingActionButton(
        heroTag: "generalFab",
        onPressed: () => _showAddAmmoSheet(context), // викликає bottom sheet
        child: const Icon(Icons.add_outlined),
      ),
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) => BaseCollectionBody(
          tiles: cartridges
              .map(
                (item) => CollectionItemTile(
                  key: ValueKey(item.id),
                  body: Center(child: Text(item.name)),
                  item: CartridgeCollectionItem(ref: item),
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
