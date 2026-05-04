import 'dart:async';

import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/core/providers/filter_providers.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_item_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_ammo_tile_body.dart';
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

class AmmoCollectionScreen extends ConsumerWidget {
  const AmmoCollectionScreen({
    required this.filterBullet,
    this.caliberInch,
    super.key,
  });

  final bool filterBullet;

  /// When provided, only ammo matching this caliber is shown.
  final double? caliberInch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(builtinCollectionProvider);
    final l10n = AppLocalizations.of(context)!;

    final defaultCaliberInch = caliberInch != null && caliberInch! > 0
        ? caliberInch
        : null;
    final filter = ref.watch(ammoCollectionFilterProvider(defaultCaliberInch));

    final title = filterBullet
        ? l10n.bulletCollectionScreenTitle
        : l10n.cartridgeCollectionScreenTitle;

    return BaseScreen(
      title: title,
      isSubscreen: true,
      actions: [
        Builder(
          builder: (ctx) => IconButton(
            onPressed: () {
              final all = collectionAsync.value == null
                  ? <Ammo>[]
                  : filterBullet
                  ? collectionAsync.value!.bullets
                  : collectionAsync.value!.cartridges;
              unawaited(
                showAmmoCollectionFilterSheet(
                  ctx,
                  allItems: all,
                  defaultCaliberInch: defaultCaliberInch,
                ),
              );
            },
            icon: Badge(
              isLabelVisible: filter.isActive,
              child: const Icon(IconDef.filter),
            ),
          ),
        ),
        helpAction(context, helpId: HelpData.ammoCollectionScreen),
      ],
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(error: error),
        data: (collection) {
          final all = filterBullet ? collection.bullets : collection.cartridges;

          final items = all.where((a) {
            if (filter.calibers.isNotEmpty &&
                !filter.calibers.contains(a.caliberInch)) {
              return false;
            }
            if (filter.vendors.isNotEmpty &&
                !filter.vendors.contains(a.vendor ?? '')) {
              return false;
            }
            if (filter.minWeightGrain != null &&
                a.weightGrain < filter.minWeightGrain!) {
              return false;
            }
            if (filter.maxWeightGrain != null &&
                a.weightGrain > filter.maxWeightGrain!) {
              return false;
            }
            return true;
          }).toList();

          return BaseCollectionBody(
            tiles: items
                .map(
                  (ammo) => CollectionItemTile(
                    key: ValueKey(ammo.name),
                    body: CollectionAmmoTileBody(ammo: ammo),
                    item: CartridgeCollectionItem(ref: ammo),
                    searchText: [
                      ammo.name,
                      ammo.vendor ?? '',
                      ammo.projectileName ?? '',
                    ].join(' '),
                    onSelect: () => context.pop<Ammo>(ammo.clone()),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
