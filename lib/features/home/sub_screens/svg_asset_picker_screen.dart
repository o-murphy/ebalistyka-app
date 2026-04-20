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
              mini: miniTiles,
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
    this.mini = false,
  });

  final String assetId;
  final bool isSelected;
  final AsyncValue<String> Function(WidgetRef, String) watchSvg;
  final VoidCallback onTap;
  final bool mini;

  static const double _kViewMils = 30.0;
  static const double _kViewMilsMini = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svgAsync = watchSvg(ref, assetId);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: mini ? 8 : 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(mini ? 8 : 12),
                side: BorderSide(color: cs.primary, width: mini ? 1.5 : 2),
              )
            : null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              mini ? 8 : 12,
              mini ? 6 : 10,
              mini ? 8 : 12,
              mini ? 8 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      assetId,
                      style: (mini ? tt.bodyMedium : tt.titleMedium)?.copyWith(
                        color: isSelected ? cs.primary : null,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: mini ? 12 : null,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: cs.primary,
                        size: mini ? 16 : 20,
                      ),
                  ],
                ),
                SizedBox(height: mini ? 6 : 10),
                AspectRatio(
                  aspectRatio: 1,
                  child: svgAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (svg) => Transform.scale(
                      scale: mini ? 0.25 : 1.0,
                      child: _buildPreview(
                        _prepareSvg(svg, cs, mini: mini),
                        cs,
                        mini: mini,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPreview(
    String svg,
    ColorScheme cs, {
    bool mini = false,
  }) => Stack(
    fit: StackFit.expand,
    children: [
      ClipOval(child: SvgPicture.string(svg, fit: BoxFit.contain)),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.onSurface.withAlpha(80),
              width: mini ? 1 : 1.5,
            ),
          ),
        ),
      ),
    ],
  );

  static String _prepareSvg(String svg, ColorScheme cs, {bool mini = false}) {
    var result = resolveSvgColorRoles(svg, cs);
    result = result.replaceFirst(RegExp(r'\bwidth="[^"]*"\s*'), '');
    result = result.replaceFirst(RegExp(r'\bheight="[^"]*"\s*'), '');
    result = result.replaceAll(RegExp(r'<metadata\b[^/]*/>', dotAll: true), '');
    result = result.replaceAll(
      RegExp(r'<metadata\b[^>]*>.*?</metadata>', dotAll: true),
      '',
    );

    final viewSize = mini ? _kViewMilsMini : _kViewMils;
    final halfSize = viewSize / 2;

    final milW = _attr(result, 'data-mil-width');
    final milH = _attr(result, 'data-mil-height');
    if (milW > viewSize || milH > viewSize) {
      result = result.replaceFirst(
        RegExp(r'viewBox="[^"]+"'),
        'viewBox="-$halfSize -$halfSize $viewSize $viewSize"',
      );
    }
    return result;
  }

  static double _attr(String svg, String name) {
    final m = RegExp('$name="([^"]+)"').firstMatch(svg);
    final defaultSize = _kViewMils;
    return m != null
        ? double.tryParse(m.group(1)!) ?? defaultSize
        : defaultSize;
  }
}
