import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
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

  Future<void> _showAddSightSheet(BuildContext context) => showActionSheet(
    context,
    title: 'Add Sight',
    entries: [
      ActionSheetItem(
        icon: Icons.add_circle_outline,
        title: 'Create new',
        onTap: () async => debugPrint('Create new sight'),
        // TODO: context.push(Routes.sightCreate)
      ),
      ActionSheetItem(
        icon: Icons.folder_open_outlined,
        title: 'Select from collection',
        onTap: () async => debugPrint('Select sight from collection'),
        // TODO: context.push(Routes.sightCollection)
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
        onPressed: () => _showAddSightSheet(context),
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
