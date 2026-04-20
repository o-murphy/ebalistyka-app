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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ids) {
          final selected = currentId ?? defaultId;
          final sorted = [
            if (ids.contains(selected)) selected,
            ...ids.where((id) => id != selected),
          ];
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    this.clipRadius = 12.0, // Радіус обрізання в MIL (половина від 30)
  });

  final String assetId;
  final bool isSelected;
  final AsyncValue<String> Function(WidgetRef, String) watchSvg;
  final VoidCallback onTap;
  final double clipRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svgAsync = watchSvg(ref, assetId);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.primary, width: 2),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      assetId,
                      style: tt.titleMedium?.copyWith(
                        color: isSelected ? cs.primary : null,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle, color: cs.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                AspectRatio(
                  aspectRatio: 1,
                  child: svgAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (svg) => _buildPreview(svg, cs),
                  ),
                ),
              ],
            ),
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
        // SVG малюється в своєму натуральному розмірі, але обрізається кругом
        ClipOval(child: SvgPicture.string(preparedSvg, fit: BoxFit.contain)),
        // Рамка
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

    // Видаляємо width/height
    result = result.replaceFirst(RegExp(r'\bwidth="[^"]*"\s*'), '');
    result = result.replaceFirst(RegExp(r'\bheight="[^"]*"\s*'), '');

    // Видаляємо metadata
    result = result.replaceAll(RegExp(r'<metadata\b[^/]*/>', dotAll: true), '');
    result = result.replaceAll(
      RegExp(r'<metadata\b[^>]*>.*?</metadata>', dotAll: true),
      '',
    );

    // Застосовуємо обрізання viewBox до clipRadius
    result = _clipViewMils(result, clipRadius);

    // Додаємо shape-rendering для кращої якості
    result = result.replaceFirst(
      RegExp(r'<svg\b'),
      '<svg shape-rendering="crispEdges"',
    );

    return result;
  }

  String _clipViewMils(String svg, double clipRadius) {
    // Отримуємо поточний viewBox
    final viewBoxMatch = RegExp(r'viewBox="([^"]+)"').firstMatch(svg);
    if (viewBoxMatch == null) return svg;

    final parts = viewBoxMatch.group(1)!.trim().split(RegExp(r'\s+'));
    if (parts.length != 4) return svg;

    final minX = double.tryParse(parts[0]) ?? 0;
    final minY = double.tryParse(parts[1]) ?? 0;
    final currentWidth = double.tryParse(parts[2]) ?? 0;
    final currentHeight = double.tryParse(parts[3]) ?? 0;

    // Обчислюємо центр оригінального viewBox
    final centerX = minX + currentWidth / 2;
    final centerY = minY + currentHeight / 2;

    // Новий розмір (діаметр)
    final viewSize = 2 * clipRadius;

    // Новий viewBox з центром в оригінальному центрі
    final newMinX = centerX - clipRadius;
    final newMinY = centerY - clipRadius;
    final newViewBox = '$newMinX $newMinY $viewSize $viewSize';

    // Завжди замінюємо на новий viewBox для однакового масштабування
    return svg.replaceFirst(
      RegExp(r'viewBox="[^"]+"'),
      'viewBox="$newViewBox"',
    );
  }
}
