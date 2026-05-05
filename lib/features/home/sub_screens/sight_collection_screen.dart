import 'dart:async';

import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/core/providers/filter_providers.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_item_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/collection_sight_tile_body.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/filter_sheet.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/error_display.dart';
import 'package:ebalistyka/shared/widgets/help_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SightCollectionScreen extends ConsumerWidget {
  const SightCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(builtinCollectionProvider);
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(sightCollectionFilterProvider);

    return BaseScreen(
      title: l10n.sightCollectionScreenTitle,
      isSubscreen: true,
      actions: [
        Builder(
          builder: (ctx) => IconButton(
            onPressed: () {
              final sights = collectionAsync.value?.sights ?? [];
              unawaited(
                showSightFilterSheet(
                  ctx,
                  allItems: sights,
                  forCollection: true,
                ),
              );
            },
            icon: Badge(
              isLabelVisible: filter.isActive,
              child: const Icon(IconDef.filter),
            ),
          ),
        ),
        helpAction(context, helpId: HelpData.sightCollectionScreen),
      ],
      body: collectionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(error: error),
        data: (collection) {
          final items = collection.sights.where((s) {
            if (filter.vendors.isNotEmpty &&
                !filter.vendors.contains(s.vendor ?? '')) {
              return false;
            }
            if (filter.focalPlanes.isNotEmpty &&
                !filter.focalPlanes.contains(s.focalPlane)) {
              return false;
            }
            return true;
          }).toList();

          return BaseCollectionBody(
            tiles: items
                .map(
                  (sight) => CollectionItemTile(
                    key: ValueKey(sight.name),
                    body: CollectionSightTileBody(sight: sight),
                    item: SightCollectionItem(ref: sight),
                    searchText: [sight.name, sight.vendor ?? ''].join(' '),
                    onSelect: () async {
                      await ref
                          .read(appStateProvider.notifier)
                          .saveSight(sight.clone());
                      if (context.mounted) context.pop();
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
