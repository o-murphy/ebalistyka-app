import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart'
    show AdjustmentDisplayFormat;
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/reticle_view.dart';

// ─── Page 1 — Reticle & Adjustments ──────────────────────────────────────────

class HomeReticlePage extends ConsumerWidget {
  const HomeReticlePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    if (vmState is HomeUiNoData) {
      return EmptyStatePlaceholder(
        type: vmState.type,
        message: vmState.message,
      );
    }
    if (vmState is HomeUiError) {
      return Center(child: Text('Error: ${vmState.message}'));
    }
    if (vmAsync.isLoading || vmState is! HomeUiReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _SemicolonWrappingText(
            vmState.cartridgeInfoLine,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withAlpha(160)),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push(Routes.reticleView),
                    child: ReticleView(
                      reticleImageId: ref
                          .watch(activeProfileProvider)
                          ?.sight
                          .target
                          ?.reticleImage,
                      targetImageId: null,
                      targetSizeMil: 0.5,
                      offsetXMil: vmState.adjustmentWindMil,
                      offsetYMil: vmState.adjustmentElevMil,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  child: vmState.adjustment.elevation.isEmpty
                      ? Center(
                          child: Text('Enable units...', style: tt.bodySmall),
                        )
                      : _AdjPanel(
                          adjustment: vmState.adjustment,
                          fmt: vmState.adjustmentFormat,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Semicolon-aware wrapping text ───────────────────────────────────────────

class _SemicolonWrappingText extends StatelessWidget {
  const _SemicolonWrappingText(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, constraints) {
      final segments = text.split('; ');
      if (segments.length <= 1) {
        return Text(text, style: style, textAlign: TextAlign.center);
      }

      final maxWidth = constraints.maxWidth;
      final lines = <String>[];
      var current = segments.first;

      for (int i = 1; i < segments.length; i++) {
        final candidate = '$current; ${segments[i]}';
        final tp = TextPainter(
          text: TextSpan(text: candidate, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        if (tp.width <= maxWidth) {
          current = candidate;
        } else {
          lines.add(current);
          current = segments[i];
        }
      }
      lines.add(current);

      return Text(lines.join('\n'), style: style, textAlign: TextAlign.center);
    },
  );
}

// ─── Adjustment panel ─────────────────────────────────────────────────────────

class _AdjPanel extends StatelessWidget {
  const _AdjPanel({required this.adjustment, required this.fmt});

  final AdjustmentData adjustment;
  final AdjustmentDisplayFormat fmt;

  String _elevDir() {
    if (adjustment.elevation.isEmpty) return '';
    final pos = adjustment.elevation.first.isPositive;
    return switch (fmt) {
      AdjustmentDisplayFormat.arrows => pos ? '↑' : '↓',
      AdjustmentDisplayFormat.signs => pos ? '+' : '−',
      AdjustmentDisplayFormat.letters => pos ? 'U' : 'D',
    };
  }

  String _windDir() {
    if (adjustment.windage.isEmpty) return '';
    final pos = adjustment.windage.first.isPositive;
    return switch (fmt) {
      AdjustmentDisplayFormat.arrows => pos ? '→' : '←',
      AdjustmentDisplayFormat.signs => pos ? '+' : '−',
      AdjustmentDisplayFormat.letters => pos ? 'R' : 'L',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final headerStyle = tt.labelMedium!.copyWith(
      color: cs.onSurface.withAlpha(180),
      fontWeight: FontWeight.w600,
    );
    final dirStyle = tt.titleSmall!.copyWith(
      color: cs.primary,
      fontWeight: FontWeight.w700,
    );
    final valStyle = tt.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    final unitStyle = tt.bodySmall!.copyWith(
      color: cs.onSurface.withAlpha(140),
    );

    Widget valueRow(AdjustmentValue v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Required min for correct BoxFit
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(v.absValue.toStringAsFixed(v.decimals), style: valStyle),
          const SizedBox(width: 4),
          Text(v.symbol, style: unitStyle),
        ],
      ),
    );

    Widget sectionHeader(String label, String dir) => Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: headerStyle),
        if (dir.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(dir, style: dirStyle),
        ],
      ],
    );

    return FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: IntrinsicWidth(
        child: Column(
          // stretch forces the children (including the SizedBox with Divider)
          // to take up the full width calculated by IntrinsicWidth
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            sectionHeader('Drop', _elevDir()),
            const SizedBox(height: 2),
            ...adjustment.elevation.map(valueRow),

            // Wrapper container for adaptive width Divider
            const SizedBox(
              width: double.infinity,
              child: Divider(height: 16, thickness: 1, indent: 0, endIndent: 0),
            ),

            sectionHeader('Windage', _windDir()),
            const SizedBox(height: 2),
            ...adjustment.windage.map(valueRow),
          ],
        ),
      ),
    );
  }
}
