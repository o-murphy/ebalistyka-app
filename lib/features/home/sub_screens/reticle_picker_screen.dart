import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'svg_asset_picker_screen.dart';

class ReticlePickerScreen extends ConsumerWidget {
  const ReticlePickerScreen({this.currentReticleId, super.key});

  final String? currentReticleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SvgAssetPickerScreen(
      title: 'Select Reticle',
      defaultId: defaultReticleId,
      currentId: currentReticleId,
      watchList: (ref) => ref.watch(reticleListProvider),
      watchSvg: (ref, id) => ref.watch(reticleSvgProvider(id)),
    );
  }
}
