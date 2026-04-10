import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_sight_tile_body.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/confirm_dialog.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:go_router/go_router.dart';

class MySightsCollectionScreen extends ConsumerWidget {
  const MySightsCollectionScreen({this.profileId, super.key});

  /// ID of the profile that opened this screen.
  /// When provided, its sight selection is highlighted and sorted first.
  /// Falls back to the active profile when null.
  final String? profileId;

  Future<void> _showAddSightSheet(BuildContext context, WidgetRef ref) =>
      showActionSheet(
        context,
        title: 'Add Sight',
        entries: [
          ActionSheetItem(
            icon: IconDef.addCircle,
            title: 'Create new',
            onTap: () async {
              final result = await context.push<Sight?>(Routes.sightCreate);
              if (result != null && context.mounted) {
                await ref.read(appStateProvider.notifier).saveSight(result);
              }
            },
          ),
          ActionSheetItem(
            icon: IconDef.openCollection,
            title: 'Select from collection',
            onTap: () async => context.push(Routes.sightCollection),
          ),
        ],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final sights = ref.watch(sightsProvider);
    final appState = ref.watch(appStateProvider).value;
    final profile = profileId != null
        ? appState?.profiles
              .where((p) => p.id.toString() == profileId)
              .firstOrNull
        : appState?.activeProfile;
    final selectedId = profile?.sight.targetId;

    final sorted = [
      ...sights.where((s) => s.id == selectedId),
      ...sights.where((s) => s.id != selectedId),
    ];

    return BaseScreen(
      title: "My Sights",
      isSubscreen: true,
      floatingActionButton: FloatingActionButton(
        heroTag: "generalFab",
        onPressed: () => _showAddSightSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 6,
        child: const Icon(IconDef.add),
      ),
      actions: [
        IconButton(
          onPressed: () => debugPrint("Filter button (will call bottom toast)"),
          icon: Icon(IconDef.filter),
        ),
      ],
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (_) => BaseCollectionBody(
          tiles: sorted
              .map(
                (item) => CollectionItemTile(
                  key: ValueKey(item.id),
                  body: CollectionSightTileBody(sight: item),
                  item: SightCollectionItem(ref: item),
                  isSelected: item.id == selectedId,
                  onSelect: () async {
                    final pid = profileId ?? profile?.id.toString();
                    if (pid == null) return;
                    await ref
                        .read(appStateProvider.notifier)
                        .setProfileSight(pid, item.id);
                    if (context.mounted) context.pop();
                  },
                  onEdit: () async {
                    final result = await context.push<Sight?>(
                      Routes.profileEditSight,
                      extra: item,
                    );
                    if (result != null && context.mounted) {
                      await ref
                          .read(appStateProvider.notifier)
                          .saveSight(result);
                    }
                  },
                  onDuplicate: () async {
                    final name = await showTextInputDialog(
                      context,
                      title: 'Duplicate Sight',
                      initialValue: 'Copy of ${item.name}',
                      labelText: 'Sight name',
                      confirmLabel: 'Create',
                    );
                    if (name == null || !context.mounted) return;
                    await ref
                        .read(appStateProvider.notifier)
                        .duplicateSight(item.id, name);
                  },
                  onExport: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export not yet available')),
                  ),
                  onRemove: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Remove sight',
                      content: 'Remove "${item.name}"?',
                      confirmLabel: 'Remove',
                      isDestructive: true,
                    );
                    if (confirmed && context.mounted) {
                      await ref
                          .read(appStateProvider.notifier)
                          .deleteSight(item.id);
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
