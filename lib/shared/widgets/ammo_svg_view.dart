import 'package:ebalistyka/core/providers/ammo_svg_provider.dart';
import 'package:ebalistyka/shared/widgets/svg_asset_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AmmoSvgView extends ConsumerWidget {
  const AmmoSvgView({
    this.imageId,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    super.key,
  });

  final String? imageId;
  final BoxFit fit;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SvgAssetView(
    svgAsync: ref.watch(ammoSvgProvider(imageId)),
    fit: fit,
    alignment: alignment,
    padding: padding,
  );
}
