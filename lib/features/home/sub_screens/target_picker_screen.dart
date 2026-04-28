import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'svg_asset_picker_screen.dart';

class TargetPickerScreen extends ConsumerWidget {
  const TargetPickerScreen({this.currentTargetId, super.key});

  final String? currentTargetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return SvgAssetPickerScreen(
      title: l10n.labelTargetSize,
      defaultId: defaultTargetId,
      currentId: currentTargetId,
      watchList: (ref) => ref.watch(targetListProvider),
      watchSvg: (ref, id) => ref.watch(targetSvgProvider(id)),
      // miniTiles: true,
    );
  }
}
