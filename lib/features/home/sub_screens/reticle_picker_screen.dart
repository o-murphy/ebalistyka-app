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
        data: (ids) => ListView.builder(
          itemCount: ids.length,
          itemBuilder: (context, i) => _ReticleTile(
            reticleId: ids[i],
            isSelected: ids[i] == (currentReticleId ?? defaultReticleId),
            onTap: () => context.pop(ids[i]),
          ),
        ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svgAsync = ref.watch(reticleSvgProvider(reticleId));
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      selected: isSelected,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: svgAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (svg) => ClipOval(
            child: SvgPicture.string(
              _resolveColors(svg, cs),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      title: Text(reticleId),
      trailing: isSelected ? Icon(Icons.check, color: cs.primary) : null,
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
