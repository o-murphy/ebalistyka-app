import 'package:ebalistyka/core/services/ebcp_service.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/filter_providers.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_sight_tile_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/filter_sheet.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/confirm_dialog.dart';
import 'package:ebalistyka/shared/widgets/error_display.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_item_tile.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MySightsCollectionScreen extends ConsumerWidget {
  const MySightsCollectionScreen({this.profileId, super.key});

  /// ID of the profile that opened this screen.
  /// When provided, its sight selection is highlighted and sorted first.
  /// Falls back to the active profile when null.
  final String? profileId;

  Future<void> _showAddSightSheet(BuildContext context, WidgetRef ref) {
    final l10n = ref.read(appLocalizationsProvider);

    return showActionSheet(
      context,
      title: l10n.actionAddSight,
      entries: [
        ActionSheetItem(
          icon: IconDef.addCircle,
          title: l10n.createNewAction,
          onTap: () async {
            final result = await context.push<Sight?>(Routes.sightCreate);
            if (result != null && context.mounted) {
              await ref.read(appStateProvider.notifier).saveSight(result);
            }
          },
        ),
        ActionSheetItem(
          icon: IconDef.openCollection,
          title: l10n.actionSelectSightFromCollection,
          onTap: () async => context.push(Routes.sightCollection),
        ),
        ActionSheetItem(
          icon: IconDef.import,
          title: l10n.actionImportFromFile,
          onTap: () async {
            try {
              final ebcp = await EbcpService.pickAndParse();
              if (ebcp == null || !context.mounted) return;
              final sights = ebcp.items
                  .map((i) => i.asSight())
                  .whereType<SightExport>()
                  .toList();
              if (sights.isEmpty) {
                showNotAvailableSnackBar(context, l10n.noSightsFoundInFile);
                return;
              }
              for (final s in sights) {
                await ref.read(appStateProvider.notifier).importSight(s);
              }
            } catch (e) {
              if (!context.mounted) return;
              showFeedback(
                context,
                '${l10n.errorImportFailed}: $e',
                isError: true,
              );
            }
          },
        ),
      ],
    );
  }

  Future<void> _onExport(
    BuildContext context,
    WidgetRef ref,
    Sight item,
  ) async {
    final info = await PackageInfo.fromPlatform();
    final ebcp = EbcpFile(
      version: info.version,
      items: [EbcpItem.fromSight(SightExport.fromEntity(item))],
    );
    if (!context.mounted) return;
    try {
      await EbcpService.shareFile(ebcp, EbcpService.sanitizeName(item.name));
    } catch (e) {
      if (context.mounted) showFeedback(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final appState = appStateAsync.value;

    final sights = appState?.sights ?? [];
    final profile = profileId != null
        ? appState?.profiles
              .where((p) => p.id.toString() == profileId)
              .firstOrNull
        : appState?.activeProfile;
    final selectedId = profile?.sight.targetId;

    final filter = ref.watch(sightFilterProvider);

    final filtered = sights.where((s) {
      if (filter.vendors.isNotEmpty &&
          !filter.vendors.contains(s.vendor ?? '')) {
        return false;
      }
      if (filter.focalPlanes.isNotEmpty &&
          !filter.focalPlanes.contains(s.focalPlane)) {
        return false;
      }
      return true;
    });

    final sorted = [
      ...filtered.where((s) => s.id == selectedId),
      ...filtered.where((s) => s.id != selectedId),
    ];

    return BaseScreen(
      title: l10n.mySights,
      isSubscreen: true,
      floatingActionButton: FloatingActionButton(
        heroTag: 'generalFab',
        onPressed: () => _showAddSightSheet(context, ref),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 6,
        child: const Icon(IconDef.add),
      ),
      actions: [
        IconButton(
          onPressed: () => showSightFilterSheet(context, allItems: sights),
          icon: Badge(
            isLabelVisible: filter.isActive,
            child: Icon(IconDef.filter),
          ),
        ),
      ],
      body: appStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(error: error),
        data: (_) => BaseCollectionBody(
          tiles: sorted
              .map(
                (item) => CollectionItemTile(
                  key: ValueKey(item.id),
                  body: CollectionSightTileBody(sight: item),
                  item: SightCollectionItem(ref: item),
                  isSelected: item.id == selectedId,
                  searchText: [item.name, item.vendor ?? ''].join(' '),
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
                      title: l10n.sightDuplicateDialogTitle,
                      initialValue: '${l10n.copyOf} ${item.name}',
                      labelText: l10n.sightName,
                      confirmLabel: l10n.createAction,
                    );
                    if (name == null || !context.mounted) return;
                    await ref
                        .read(appStateProvider.notifier)
                        .duplicateSight(item.id, name);
                  },
                  onExport: () => _onExport(context, ref, item),
                  onRemove: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: l10n.sightRemoveDialogTitle,
                      content: '${l10n.remove} "${item.name}"?',
                      confirmLabel: l10n.removeAction,
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
