import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart'
    show AdjustmentDisplayFormat;
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/shared/models/adjustment_data.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';

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
                  child: _ReticleView(
                    cs: cs,
                    elevMil: vmState.adjustmentElevMil,
                    windMil: vmState.adjustmentWindMil,
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

// ─── Reticle view ─────────────────────────────────────────────────────────────

class _ReticleView extends ConsumerWidget {
  const _ReticleView({
    required this.cs,
    required this.elevMil,
    required this.windMil,
  });

  final ColorScheme cs;
  final double elevMil;
  final double windMil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reticleId = ref
        .watch(activeProfileProvider)
        ?.sight
        .target
        ?.reticleImage;
    final svgAsync = ref.watch(reticleSvgProvider(reticleId));
    return AspectRatio(
      aspectRatio: 1,
      child: svgAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (svgString) => _buildSvg(svgString),
      ),
    );
  }

  Widget _buildSvg(String svgString) {
    final meta = _parseSvgMeta(svgString);
    final svg = _clipViewMils(_resolveRoles(svgString, cs), meta);
    final adjColor = _toHex(
      cs.brightness == Brightness.dark
          ? Colors.orangeAccent
          : Colors.deepOrangeAccent,
    );
    final svgWithAdj = _injectAdjustment(
      svg,
      windMil: windMil,
      elevMil: elevMil,
      milWidth: meta.milWidth,
      milHeight: meta.milHeight,
      fillColor: adjColor,
      strokeColor: adjColor,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipOval(child: SvgPicture.string(svgWithAdj, fit: BoxFit.contain)),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.onSurface),
            ),
          ),
        ),
      ],
    );
  }

  static String _resolveRoles(String svg, ColorScheme cs) {
    final roles = {
      'onSurface': cs.onSurface,
      'onBackground': cs.onSurface,
      'primary': cs.primary,
      'secondary': cs.secondary,
      'error': cs.error,
    };
    var result = svg;
    for (final e in roles.entries) {
      result = result.replaceAll('"${e.key}"', '"${_toHex(e.value)}"');
    }
    return result;
  }

  static String _toHex(Color c) {
    final v = c.toARGB32();
    return '#${(v & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }

  // Injects adjustment indicator in mil coordinates (matches the mil viewBox
  // used by MilReticleCanvas): vertical line, horizontal line, dot.
  static String _injectAdjustment(
    String svg, {
    required double windMil,
    required double elevMil,
    required double milWidth,
    required double milHeight,
    required String fillColor,
    required String strokeColor,
  }) {
    final maxX = milWidth / 2;
    final maxY = milHeight / 2;
    final outOfRange = windMil.abs() > maxX || elevMil.abs() > maxY;

    if (outOfRange) {
      const fs = 1.8; // mils
      const dy = fs * 0.35; // baseline compensation
      final elements =
          '\n  <text x="0" y="$dy" text-anchor="middle" font-size="$fs" fill="$fillColor" font-weight="bold">OUT OF RANGE</text>';
      return svg.replaceFirst('</svg>', '$elements\n</svg>');
    }

    // All values in mils — the SVG viewBox is already in mils.
    const sw = 0.05;
    const r = 0.2;
    final elements =
        '''
  <line x1="$windMil" y1="0" x2="$windMil" y2="$elevMil" stroke="$strokeColor" stroke-width="$sw"/>
  <line x1="0" y1="$elevMil" x2="$windMil" y2="$elevMil" stroke="$strokeColor" stroke-width="$sw"/>
  <circle cx="$windMil" cy="$elevMil" r="$r" fill="$fillColor" stroke="$strokeColor" stroke-width="$sw"/>''';
    return svg.replaceFirst('</svg>', '$elements\n</svg>');
  }

  // Clips the SVG viewBox to [_kViewMils]×[_kViewMils] mils when the reticle
  // is larger (e.g. mil_xt is 48×48). The viewBox is in mils, so no factor
  // multiplication is needed.
  static const double _kViewMils = 30.0;

  static String _clipViewMils(String svg, _SvgMeta meta) {
    if (meta.milWidth <= _kViewMils && meta.milHeight <= _kViewMils) return svg;
    // viewBox is in mils — no factor multiplication needed.
    return svg.replaceFirst(
      RegExp(r'viewBox="[^"]+"'),
      'viewBox="${-_kViewMils / 2} ${-_kViewMils / 2} $_kViewMils $_kViewMils"',
    );
  }

  // Reads data-mil-width / data-factor from the SVG root element written by
  // MilReticleCanvas.
  static _SvgMeta _parseSvgMeta(String svg) {
    double attr(String name, double fallback) {
      final m = RegExp('$name="([^"]+)"').firstMatch(svg);
      return m != null ? (double.tryParse(m.group(1)!) ?? fallback) : fallback;
    }

    return _SvgMeta(
      milWidth: attr('data-mil-width', 30.0),
      milHeight: attr('data-mil-height', 30.0),
      factor: attr('data-factor', 100.0),
    );
  }
}

class _SvgMeta {
  const _SvgMeta({
    required this.milWidth,
    required this.milHeight,
    required this.factor,
  });

  final double milWidth;
  final double milHeight;
  final double factor;
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
