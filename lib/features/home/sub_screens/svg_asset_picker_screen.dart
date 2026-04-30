import 'package:ebalistyka/shared/widgets/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:ebalistyka/core/utils/svg_color_utils.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';

/// Generic picker screen for SVG assets (reticles or targets).
///
/// Pass Riverpod providers via [watchList] / [watchSvg] callbacks so the
/// shared widget stays decoupled from specific provider instances.
///
/// Example:
/// ```dart
/// SvgAssetPickerScreen(
///   title: 'Select Reticle',
///   defaultId: defaultReticleId,
///   currentId: currentReticleId,
///   watchList: (ref) => ref.watch(reticleListProvider),
///   watchSvg:  (ref, id) => ref.watch(reticleSvgProvider(id)),
/// )
/// ```
class SvgAssetPickerScreen extends ConsumerWidget {
  const SvgAssetPickerScreen({
    required this.title,
    required this.defaultId,
    required this.watchList,
    required this.watchSvg,
    this.currentId,
    this.miniTiles = false,
    super.key,
  });

  final String title;
  final String defaultId;
  final String? currentId;
  final AsyncValue<List<String>> Function(WidgetRef) watchList;
  final AsyncValue<String> Function(WidgetRef, String) watchSvg;
  final bool miniTiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = watchList(ref);

    return BaseScreen(
      title: title,
      isSubscreen: true,
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorDisplay(error: error),
        data: (ids) {
          final selected = currentId ?? defaultId;
          final sorted = [
            if (ids.contains(selected)) selected,
            ...ids.where((id) => id != selected),
          ];
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 375,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _SvgAssetTile(
              assetId: sorted[i],
              isSelected: sorted[i] == selected,
              watchSvg: watchSvg,
              onTap: () => context.pop(sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SvgAssetTile extends ConsumerWidget {
  const _SvgAssetTile({
    required this.assetId,
    required this.isSelected,
    required this.watchSvg,
    required this.onTap,
  });

  final String assetId;
  final bool isSelected;
  final AsyncValue<String> Function(WidgetRef, String) watchSvg;
  final VoidCallback onTap;

  static const double clipRadius = 12.0;

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svgAsync = watchSvg(ref, assetId);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: svgAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (svg) => _buildPreview(svg, cs),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Text(
                  assetId,
                  style: tt.bodyLarge?.copyWith(
                    color: isSelected ? cs.primary : Colors.white,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black.withAlpha(100),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: cs.onPrimary,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(String svg, ColorScheme cs) {
    final preparedSvg = _prepareSvg(svg, cs);

    return Stack(
      fit: StackFit.expand,
      children: [
        // SVG is drawn at its natural size, but clipped around the circle
        ClipOval(child: SvgPicture.string(preparedSvg, fit: BoxFit.contain)),
        // Frame
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.onSurface.withAlpha(80), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  String _prepareSvg(String svg, ColorScheme cs) {
    var result = resolveSvgColorRoles(svg, cs);

    // Delete width/height
    result = result.replaceFirst(RegExp(r'\bwidth="[^"]*"\s*'), '');
    result = result.replaceFirst(RegExp(r'\bheight="[^"]*"\s*'), '');

    // Delete metadata
    result = result.replaceAll(RegExp(r'<metadata\b[^/]*/>', dotAll: true), '');
    result = result.replaceAll(
      RegExp(r'<metadata\b[^>]*>.*?</metadata>', dotAll: true),
      '',
    );

    // Apply the viewBox clipping to the clipRadius
    result = _clipViewMils(result, clipRadius);

    // Add shape-rendering for better quality
    result = result.replaceFirst(
      RegExp(r'<svg\b'),
      '<svg shape-rendering="geometricPrecision"',
    );

    return result;
  }

  String _clipViewMils(String svg, double clipRadius) {
    // Get the current viewBox
    final viewBoxMatch = RegExp(r'viewBox="([^"]+)"').firstMatch(svg);
    if (viewBoxMatch == null) return svg;

    final parts = viewBoxMatch.group(1)!.trim().split(RegExp(r'\s+'));
    if (parts.length != 4) return svg;

    final minX = double.tryParse(parts[0]) ?? 0;
    final minY = double.tryParse(parts[1]) ?? 0;
    final currentWidth = double.tryParse(parts[2]) ?? 0;
    final currentHeight = double.tryParse(parts[3]) ?? 0;

    // Calculate the center of the original viewBox
    final centerX = minX + currentWidth / 2;
    final centerY = minY + currentHeight / 2;

    // New size (diameter)
    final viewSize = 2 * clipRadius;

    // New viewBox centered at the original center
    final newMinX = centerX - clipRadius;
    final newMinY = centerY - clipRadius;
    final newViewBox = '$newMinX $newMinY $viewSize $viewSize';

    // Always replace with a new viewBox for the same scaling
    return svg.replaceFirst(
      RegExp(r'viewBox="[^"]+"'),
      'viewBox="$newViewBox"',
    );
  }
}
