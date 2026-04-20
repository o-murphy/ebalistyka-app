import 'package:ebalistyka/features/home/widgets/adjustment_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/router.dart';
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
        if (vmState.adjustedMessageLine != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              vmState.adjustedMessageLine!,
              style: tt.labelMedium?.copyWith(color: cs.tertiary),
            ),
          ),
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
                      reticleImageId: vmState.reticleId,
                      targetImageId: vmState.targetId,
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
                  child: AdjPanel(
                    adjustment: vmState.adjustment,
                    fmt: vmState.adjustmentFormat,
                    isEmpty: vmState.adjustment.elevation.isEmpty,
                    displayVertical: true,
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
