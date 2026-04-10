import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/confirm_dialog.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:go_router/go_router.dart';

class MyAmmoScreen extends ConsumerWidget {
  const MyAmmoScreen({this.profileId, super.key});

  /// ID of the profile that opened this screen.
  /// When provided, its ammo selection is highlighted and sorted first.
  /// Falls back to the active profile when null.
  final String? profileId;

  Future<void> _showAddAmmoSheet(BuildContext context) => showActionSheet(
    context,
    title: 'Add Ammo',
    entries: [
      ActionSheetItem(
        icon: Icons.add_circle_outline,
        title: 'Create new',
        onTap: () async => context.push(Routes.ammoCreate),
      ),
      ActionSheetItem(
        icon: Icons.folder_open_outlined,
        title: 'Select cartridge from collection',
        onTap: () async => context.push(Routes.cartridgeCollection),
      ),
      ActionSheetItem(
        icon: Icons.circle_outlined,
        title: 'Select bullet from collection',
        onTap: () async => context.push(Routes.bulletCollection),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final cartridges = ref.watch(cartridgesProvider);
    final appState = ref.watch(appStateProvider).value;
    final profile = profileId != null
        ? appState?.profiles
              .where((p) => p.id.toString() == profileId)
              .firstOrNull
        : appState?.activeProfile;
    final selectedId = profile?.ammo.targetId;

    final weapon = appState?.weapons
        .where((w) => w.id == profile?.weapon.targetId)
        .firstOrNull;

    final filtered = weapon != null
        ? cartridges.where((a) => a.caliber.raw == weapon.caliber.raw)
        : cartridges;

    final sorted = [
      ...filtered.where((a) => a.id == selectedId),
      ...filtered.where((a) => a.id != selectedId),
    ];

    return BaseScreen(
      title: "My Ammo",
      isSubscreen: true,
      floatingActionButton: FloatingActionButton(
        heroTag: "generalFab",
        onPressed: () => _showAddAmmoSheet(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 6,
        child: const Icon(Icons.add_outlined),
      ),
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) => BaseCollectionBody(
          tiles: sorted
              .map(
                (item) => CollectionItemTile(
                  key: ValueKey(item.id),
                  body: Center(child: Text(item.name)),
                  item: CartridgeCollectionItem(ref: item),
                  isSelected: item.id == selectedId,
                  onSelect: () async {
                    final pid = profileId ?? profile?.id.toString();
                    if (pid == null) return;
                    await ref
                        .read(appStateProvider.notifier)
                        .setProfileAmmo(pid, item.id);
                    if (context.mounted) context.pop();
                  },
                  onEdit: () async {
                    final result = await context.push<Ammo?>(
                      Routes.profileEditAmmo,
                      extra: item,
                    );
                    if (result != null && context.mounted) {
                      await ref
                          .read(appStateProvider.notifier)
                          .saveAmmo(result);
                    }
                  },
                  onDuplicate: () async {
                    final name = await showTextInputDialog(
                      context,
                      title: 'Duplicate Ammo',
                      initialValue: 'Copy of ${item.name}',
                      labelText: 'Ammo name',
                      confirmLabel: 'Create',
                    );
                    if (name == null || !context.mounted) return;
                    await ref
                        .read(appStateProvider.notifier)
                        .duplicateAmmo(item.id, name);
                  },
                  onExport: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export not yet available')),
                  ),
                  onRemove: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Remove ammo',
                      content: 'Remove "${item.name}"?',
                      confirmLabel: 'Remove',
                      isDestructive: true,
                    );
                    if (confirmed && context.mounted) {
                      await ref
                          .read(appStateProvider.notifier)
                          .deleteAmmo(item.id);
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
