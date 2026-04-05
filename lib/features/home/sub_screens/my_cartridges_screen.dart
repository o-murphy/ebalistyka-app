import 'package:eballistica/core/providers/app_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/models/collection_item.dart';
import 'package:eballistica/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:eballistica/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;

class MyCartridgesCollectionScreen extends ConsumerWidget {
  const MyCartridgesCollectionScreen({super.key});

  Widget _buildButton(String text) => SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FilledButton(onPressed: () => debugPrint(text), child: Text(text)),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final cartridges = ref.watch(cartridgesProvider);

    return BaseScreen(
      title: "My Cartridges",
      isSubscreen: true,
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
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton("Select cart from collection"),
              const SizedBox(height: 8),
              _buildButton("Select bullet from collection"),
              const SizedBox(height: 8),
              _buildButton("Create cartridge"),
            ],
          ),
        ),
      ),
    );
  }
}
