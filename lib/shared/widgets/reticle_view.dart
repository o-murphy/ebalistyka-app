import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/core/utils/svg_color_utils.dart';

/// Dumb reticle widget — renders a reticle SVG with an optional target overlay
/// and two crosshair lines pointing to [offsetXMil] / [offsetYMil].
///
/// Knows nothing about ballistics. Callers are responsible for computing the
/// offset (e.g. ballistic adjustment + turret corrections) and target size.
class ReticleView extends ConsumerWidget {
  const ReticleView({
    super.key,
    required this.reticleImageId,
    required this.targetImageId,
    required this.targetSizeMil,
    required this.offsetXMil,
    required this.offsetYMil,
  });

  /// Reticle asset ID (filename without `.svg`). Null → default reticle.
  final String? reticleImageId;

  /// Target asset ID (filename without `.svg`). Null → default target.
  final String? targetImageId;

  /// Angular size of the target in MIL (diameter / side).
  final double targetSizeMil;

  /// Horizontal offset of the target center in MIL (+ = right).
  final double offsetXMil;

  /// Vertical offset of the target center in MIL (+ = down in SVG space).
  final double offsetYMil;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final reticleAsync = ref.watch(reticleSvgProvider(reticleImageId));
    final targetAsync = ref.watch(targetSvgProvider(targetImageId));

    return AspectRatio(
      aspectRatio: 1,
      child: reticleAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (reticleSvg) {
          final targetSvg = targetAsync.value;
          return _buildView(context, cs, reticleSvg, targetSvg);
        },
      ),
    );
  }

  Widget _buildView(
    BuildContext context,
    ColorScheme cs,
    String reticleSvg,
    String? targetSvg,
  ) {
    final meta = _parseSvgMeta(reticleSvg);
    var svg = _clipViewMils(resolveSvgColorRoles(reticleSvg, cs), meta);

    final lineColor = svgHex(
      cs.brightness == Brightness.dark
          ? Colors.orangeAccent
          : Colors.deepOrangeAccent,
    );

    // Create underlay SVG with target and adjustment lines
    final underlaySvg = _buildUnderlaySvg(
      targetSvg: targetSvg,
      offsetXMil: offsetXMil,
      offsetYMil: offsetYMil,
      targetSizeMil: targetSizeMil,
      milWidth: meta.milWidth,
      milHeight: meta.milHeight,
      lineColor: lineColor,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Underlay (target + adjustment lines) - goes BEHIND reticle
        if (underlaySvg != null)
          ClipOval(child: SvgPicture.string(underlaySvg, fit: BoxFit.contain)),

        // Reticle overlay (on top)
        ClipOval(child: SvgPicture.string(svg, fit: BoxFit.contain)),

        // Border
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

  String? _buildUnderlaySvg({
    required String? targetSvg,
    required double offsetXMil,
    required double offsetYMil,
    required double targetSizeMil,
    required double milWidth,
    required double milHeight,
    required String lineColor,
  }) {
    final maxX = milWidth / 2;
    final maxY = milHeight / 2;
    final outOfRange = offsetXMil.abs() > maxX || offsetYMil.abs() > maxY;

    // Build SVG elements for underlay
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln(
      '     viewBox="-${milWidth / 2} -${milHeight / 2} $milWidth $milHeight">',
    );

    if (outOfRange) {
      const fs = 1.8;
      const dy = fs * 0.35;
      buffer.writeln(
        '  <text x="0" y="$dy" text-anchor="middle" font-size="$fs" ',
      );
      buffer.writeln(
        '        fill="$lineColor" font-weight="bold">OUT OF RANGE</text>',
      );
    } else {
      const sw = 0.05;

      // Adjustment lines (targeting crosshair)
      buffer.writeln(
        '  <line x1="$offsetXMil" y1="0" x2="$offsetXMil" y2="$offsetYMil" ',
      );
      buffer.writeln('        stroke="$lineColor" stroke-width="$sw"/>');
      buffer.writeln(
        '  <line x1="0" y1="$offsetYMil" x2="$offsetXMil" y2="$offsetYMil" ',
      );
      buffer.writeln('        stroke="$lineColor" stroke-width="$sw"/>');

      // Target
      if (targetSvg != null) {
        final tMeta = _parseSvgMeta(targetSvg);
        final inner = _extractSvgInner(targetSvg);
        final scale = tMeta.milWidth > 0 ? targetSizeMil / tMeta.milWidth : 1.0;
        buffer.writeln(
          '  <g transform="translate($offsetXMil,$offsetYMil) scale($scale)">',
        );
        buffer.writeln('    $inner');
        buffer.writeln('  </g>');
      } else {
        const r = 0.2;
        buffer.writeln('  <circle cx="$offsetXMil" cy="$offsetYMil" r="$r" ');
        buffer.writeln(
          '          fill="$lineColor" stroke="$lineColor" stroke-width="$sw"/>',
        );
      }
    }

    buffer.writeln('</svg>');

    return buffer.toString();
  }

  static String _extractSvgInner(String svg) {
    final start = svg.indexOf('>') + 1;
    final end = svg.lastIndexOf('</svg>');
    if (start <= 0 || end <= start) return '';
    return svg.substring(start, end);
  }

  static const double _kViewMils = 30.0;

  static String _clipViewMils(String svg, _SvgMeta meta) {
    if (meta.milWidth <= _kViewMils && meta.milHeight <= _kViewMils) return svg;
    return svg.replaceFirst(
      RegExp(r'viewBox="[^"]+"'),
      'viewBox="${-_kViewMils / 2} ${-_kViewMils / 2} $_kViewMils $_kViewMils"',
    );
  }

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
