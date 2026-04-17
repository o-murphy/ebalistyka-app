import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';

class ReticlePickerScreen extends ConsumerWidget {
  const ReticlePickerScreen({this.currentReticleId, super.key});

  final String? currentReticleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(reticleListProvider);

    return BaseScreen(
      title: 'Select Reticle',
      isSubscreen: true,
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ids) {
          final selected = currentReticleId ?? defaultReticleId;
          final sorted = [
            if (ids.contains(selected)) selected,
            ...ids.where((id) => id != selected),
          ];
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, i) => _ReticleTile(
              reticleId: sorted[i],
              isSelected: sorted[i] == selected,
              onTap: () => context.pop(sorted[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ReticleTile extends ConsumerWidget {
  const _ReticleTile({
    required this.reticleId,
    required this.isSelected,
    required this.onTap,
  });

  final String reticleId;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _kViewMils = 30.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svgAsync = ref.watch(reticleSvgProvider(reticleId));
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reticleId,
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
                    error: (_, _) => const SizedBox.shrink(),
                    data: (svg) => _buildPreview(
                      _clipViewMils(_resolveColors(svg, cs)),
                      cs,
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

  static Widget _buildPreview(String svg, ColorScheme cs) => Stack(
    fit: StackFit.expand,
    children: [
      ClipOval(child: SvgPicture.string(svg, fit: BoxFit.contain)),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.onSurface.withAlpha(80)),
          ),
        ),
      ),
    ],
  );

  static String _clipViewMils(String svg) {
    double attr(String name) {
      final m = RegExp('$name="([^"]+)"').firstMatch(svg);
      return m != null
          ? double.tryParse(m.group(1)!) ?? _kViewMils
          : _kViewMils;
    }

    final milW = attr('data-mil-width');
    final milH = attr('data-mil-height');
    if (milW <= _kViewMils && milH <= _kViewMils) return svg;
    return svg.replaceFirst(
      RegExp(r'viewBox="[^"]+"'),
      'viewBox="${-_kViewMils / 2} ${-_kViewMils / 2} $_kViewMils $_kViewMils"',
    );
  }

  static String _resolveColors(String svg, ColorScheme cs) {
    final roles = {
      'onSurface': cs.onSurface,
      'onBackground': cs.onSurface,
      'primary': cs.primary,
      'secondary': cs.secondary,
      'error': cs.error,
    };
    var result = svg;
    for (final e in roles.entries) {
      result = result.replaceAll('"${e.key}"', '"${_hex(e.value)}"');
    }
    return result;
  }

  static String _hex(Color c) {
    final v = c.toARGB32();
    return '#${(v & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
