import 'dart:async';

import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/core/providers/filter_providers.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_item_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_weapon_tile_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/filter_sheet.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/error_display.dart';
import 'package:ebalistyka/shared/widgets/help_dialog.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WeaponCollectionScreen extends ConsumerWidget {
  const WeaponCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(builtinCollectionProvider);
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(weaponCollectionFilterProvider);

    return BaseScreen(
      title: l10n.weaponCollectionScreenTitle,
      isSubscreen: true,
      actions: [
        Builder(
          builder: (ctx) => IconButton(
            onPressed: () {
              final weapons = collectionAsync.value?.weapons ?? [];
              unawaited(showWeaponFilterSheet(ctx, allItems: weapons));
            },
            icon: Badge(
              isLabelVisible: filter.isActive,
              child: const Icon(IconDef.filter),
            ),
          ),
        ),
        helpAction(context, helpId: HelpData.weaponCollectionScreen),
      ],
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(error: error),
        data: (collection) {
          final items = collection.weapons.where((w) {
            if (filter.vendors.isNotEmpty &&
                !filter.vendors.contains(w.vendor ?? '')) {
              return false;
            }
            return true;
          }).toList();

          return BaseCollectionBody(
            tiles: items
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
          );
        },
      ),
    );
  }
}
