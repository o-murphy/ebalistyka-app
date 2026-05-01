import 'package:ebalistyka/features/home/widgets/adjustment_panel.dart';
import 'package:ebalistyka/shared/widgets/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      return ErrorDisplay(error: vmState.message);
    }
    if (vmAsync.isLoading || vmState is! HomeUiReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);

    final rs = vmState.reticleState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: _SemicolonWrappingText(
            vmState.reticleState.cartridgeInfoLine,
            style: tt.labelMedium?.copyWith(color: cs.onSurface.withAlpha(160)),
          ),
        ),
        if (rs.zeroOffsetMessageLine != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              rs.zeroOffsetMessageLine!,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: tt.labelMedium?.copyWith(color: cs.tertiary),
            ),
          ),
        if (rs.adjustedMessageLine != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              rs.adjustedMessageLine!,
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: tt.labelMedium?.copyWith(color: cs.tertiary),
            ),
          ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.push(Routes.reticleView),
                        child: ReticleView(
                          reticleImageId: rs.reticleId,
                          targetImageId: rs.targetId,
                          targetSizeMil: rs.targetSizeMilAtDistance,
                          offsetXMil: rs.adjustmentWindMil,
                          offsetYMil: rs.adjustmentElevMil,
                          clipRadius: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
                  child: Center(
                    child: AdjustmentsDisplayPanel(
                      adjustment: rs.adjustment,
                      fmt: rs.adjustmentFormat,
                      isEmpty: rs.adjustment.elevation.isEmpty,
                      displayVertical: true,
                    ),
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
