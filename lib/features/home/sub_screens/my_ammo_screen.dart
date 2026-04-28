import 'package:ebalistyka/core/services/ebcp_service.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_ammo_tile_body.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/confirm_dialog.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_item_tile.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MyAmmoScreen extends ConsumerWidget {
  const MyAmmoScreen({this.profileId, super.key});

  /// ID of the profile that opened this screen.
  /// When provided, its ammo selection is highlighted and sorted first.
  /// Falls back to the active profile when null.
  final String? profileId;

  Future<void> _showAddAmmoSheet(
    BuildContext context,
    WidgetRef ref,
    Weapon? weapon,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return showActionSheet(
      context,
      title: l10n.actionAddAmmo,
      entries: [
        ActionSheetItem(
          icon: IconDef.addCircle,
          title: l10n.createNewAction,
          onTap: () async {
            final result = await context.push<Ammo?>(
              Routes.ammoCreate,
              extra: weapon?.caliberInch,
            );
            if (result != null && context.mounted) {
              await ref.read(appStateProvider.notifier).saveAmmo(result);
            }
          },
        ),
        ActionSheetItem(
          icon: IconDef.openCollection,
          title: l10n.selectCartridgeFromCollection,
          onTap: () async {
            final template = await context.push<Ammo?>(
              Routes.cartridgeCollection,
              extra: weapon?.caliberInch,
            );
            if (template == null || !context.mounted) return;
            final result = await context.push<Ammo?>(
              Routes.profileEditAmmo,
              extra: (
                template,
                template.caliberInch > 0 ? template.caliberInch : null,
              ),
            );
            if (result != null && context.mounted) {
              await ref.read(appStateProvider.notifier).saveAmmo(result);
            }
          },
        ),
        ActionSheetItem(
          icon: IconDef.openCollection,
          title: l10n.selectBulletFromCollection,
          onTap: () async {
            final template = await context.push<Ammo?>(
              Routes.bulletCollection,
              extra: weapon?.caliberInch,
            );
            if (template == null || !context.mounted) return;
            final result = await context.push<Ammo?>(
              Routes.profileEditAmmo,
              extra: (
                template,
                template.caliberInch > 0 ? template.caliberInch : null,
              ),
            );
            if (result != null && context.mounted) {
              await ref.read(appStateProvider.notifier).saveAmmo(result);
            }
          },
        ),
        ActionSheetItem(
          icon: IconDef.import,
          title: l10n.actionImportFromFile,
          onTap: () async {
            try {
              final ebcp = await EbcpService.pickAndParse();
              if (ebcp == null || !context.mounted) return;
              final ammos = ebcp.items
                  .map((i) => i.asAmmo())
                  .whereType<AmmoExport>()
                  .toList();
              if (ammos.isEmpty) {
                showNotAvailableSnackBar(context, l10n.errorNoAmmoFoundInFile);
                return;
              }
              for (final a in ammos) {
                await ref.read(appStateProvider.notifier).importAmmo(a);
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

  Future<void> _onExport(BuildContext context, WidgetRef ref, Ammo item) async {
    final info = await PackageInfo.fromPlatform();
    final ebcp = EbcpFile(
      version: info.version,
      items: [EbcpItem.fromAmmo(AmmoExport.fromEntity(item))],
    );
    if (!context.mounted) return;
    await EbcpService.shareFile(ebcp, EbcpService.sanitizeName(item.name));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStateAsync = ref.watch(appStateProvider);
    final appState = ref.watch(appStateProvider).value;
    final l10n = AppLocalizations.of(context)!;

    final cartridges = appState?.ammo ?? [];
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
      title: l10n.myAmmoScreenTitle,
      isSubscreen: true,
      floatingActionButton: FloatingActionButton(
        heroTag: "generalFab",
        onPressed: () => _showAddAmmoSheet(context, ref, weapon),
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
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        data: (_) => BaseCollectionBody(
          tiles: sorted
              .map(
                (item) => CollectionItemTile(
                  key: ValueKey(item.id),
                  body: CollectionAmmoTileBody(ammo: item),
                  item: CartridgeCollectionItem(ref: item),
                  isSelected: item.id == selectedId,
                  searchText: [
                    item.name,
                    item.vendor ?? '',
                    item.projectileName ?? '',
                  ].join(' '),
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
                      extra: (
                        item,
                        item.caliberInch > 0 ? item.caliberInch : null,
                      ),
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
                      title: l10n.ammoDuplicateDialogTitle,
                      initialValue: '${l10n.copyOf} ${item.name}',
                      labelText: l10n.ammoName,
                      confirmLabel: l10n.actionCreate,
                    );
                    if (name == null || !context.mounted) return;
                    await ref
                        .read(appStateProvider.notifier)
                        .duplicateAmmo(item.id, name);
                  },
                  onExport: () => _onExport(context, ref, item),
                  onRemove: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: l10n.ammoRemoveDialogTitle,
                      content: '${l10n.remove} "${item.name}"?',
                      confirmLabel: l10n.removeAction,
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
