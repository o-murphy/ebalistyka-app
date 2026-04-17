import 'package:ebalistyka/core/utils/svg_color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Generic widget that renders an SVG from an [AsyncValue<String>].
///
/// Color-role placeholders (e.g. fill="outlineVariant") are resolved against
/// the current [ColorScheme] automatically via [resolveSvgColorRoles].
///
/// Usage:
/// ```dart
/// SvgAssetView(svgAsync: ref.watch(weaponSvgProvider(weapon.image)))
/// SvgAssetView(svgAsync: ref.watch(ammoSvgProvider(ammo.image)))
/// ```
class SvgAssetView extends StatelessWidget {
  const SvgAssetView({
    required this.svgAsync,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    super.key,
  });

  final AsyncValue<String> svgAsync;
  final BoxFit fit;
  final Alignment alignment;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return svgAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (raw) => Padding(
        padding: padding,
        child: SvgPicture.string(
          resolveSvgColorRoles(raw, cs),
          fit: fit,
          alignment: alignment,
        ),
      ),
    );
  }
}
