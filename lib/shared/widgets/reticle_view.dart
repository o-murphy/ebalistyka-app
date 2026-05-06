import 'dart:math';

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
    this.clipRadius,
    this.showAdjLines = true,
  });

  final double? clipRadius;
  final bool showAdjLines;

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
        error: (_, _) => const SizedBox.shrink(),
        data: (reticleSvg) => _ReticleStack(
          cs: cs,
          reticleSvg: reticleSvg,
          targetSvg: targetAsync.value,
          clipRadius: clipRadius,
          showAdjLines: showAdjLines,
          offsetXMil: offsetXMil,
          offsetYMil: offsetYMil,
          targetSizeMil: targetSizeMil,
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _ReticleStack extends StatelessWidget {
  const _ReticleStack({
    required this.cs,
    required this.reticleSvg,
    required this.targetSvg,
    required this.clipRadius,
    required this.showAdjLines,
    required this.offsetXMil,
    required this.offsetYMil,
    required this.targetSizeMil,
  });

  final ColorScheme cs;
  final String reticleSvg;
  final String? targetSvg;
  final double? clipRadius;
  final bool showAdjLines;
  final double offsetXMil;
  final double offsetYMil;
  final double targetSizeMil;

  @override
  Widget build(BuildContext context) {
    final meta = _ReticleComposer.parseSvgMeta(reticleSvg);
    String materialSvg = resolveSvgColorRoles(reticleSvg, cs);

    final geometry = _ReticleGeometry.clipped(
      meta.milWidth,
      meta.milHeight,
      clipRadius: clipRadius,
    );
    if (clipRadius != null) {
      materialSvg = _ReticleComposer.clipViewMils(
        materialSvg,
        geometry,
        clipRadius!,
      );
    }

    final lineColor = svgHex(
      cs.brightness == Brightness.dark
          ? Colors.orangeAccent
          : Colors.deepOrangeAccent,
    );

    final underlaySvg = _ReticleComposer.buildUnderlaySvg(
      geometry: geometry,
      targetSvg: targetSvg,
      showAdjLines: showAdjLines,
      offsetXMil: offsetXMil,
      offsetYMil: offsetYMil,
      targetSizeMil: targetSizeMil,
      lineColor: lineColor,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Underlay (target + adjustment lines) - goes BEHIND reticle
        if (underlaySvg.isNotEmpty)
          ClipOval(child: SvgPicture.string(underlaySvg, fit: BoxFit.contain)),

        // Reticle overlay (on top)
        ClipOval(child: SvgPicture.string(materialSvg, fit: BoxFit.contain)),

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
}

class _SvgMeta {
  const _SvgMeta({required this.milWidth, required this.milHeight});

  final double milWidth;
  final double milHeight;
}

class _ReticleGeometry {
  final double milWidth;
  final double milHeight;

  const _ReticleGeometry(this.milWidth, this.milHeight);

  factory _ReticleGeometry.clipped(
    double milWidth,
    double milHeight, {
    double? clipRadius,
  }) {
    if (clipRadius == null) {
      return _ReticleGeometry(milWidth, milHeight);
    }

    final maxSize = 2 * clipRadius;

    return _ReticleGeometry(min(milWidth, maxSize), min(milHeight, maxSize));
  }

  bool isOutOfRange(double x, double y) =>
      x.abs() > milWidth / 2 || y.abs() > milHeight / 2;

  double targetScale(double targetSizeMil, double sourceSizeMil) =>
      targetSizeMil / max(sourceSizeMil, 0.0001);
}

class _ReticleComposer {
  static String clipViewMils(
    String svg,
    _ReticleGeometry geometry,
    double clipRadius,
  ) {
    if (geometry.milWidth <= 2 * clipRadius &&
        geometry.milHeight <= 2 * clipRadius) {
      return svg;
    }

    return svg.replaceFirst(
      RegExp(r'viewBox="[^"]+"'),
      'viewBox="${-clipRadius} ${-clipRadius} ${2 * clipRadius} ${2 * clipRadius}"',
    );
  }

  static String buildUnderlaySvg({
    required _ReticleGeometry geometry,
    required String? targetSvg,
    required bool showAdjLines,
    required double offsetXMil,
    required double offsetYMil,
    required double targetSizeMil,
    required String lineColor,
  }) {
    final milWidth = geometry.milWidth;
    final milHeight = geometry.milHeight;

    // Build SVG elements for underlay
    final buffer = StringBuffer();
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln('     shape-rendering="geometricPrecision"');
    buffer.writeln(
      '     viewBox="-${milWidth / 2} -${milHeight / 2} $milWidth $milHeight">',
    );

    if (geometry.isOutOfRange(offsetXMil, offsetYMil)) {
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

      // Target
      if (targetSvg != null) {
        final tMeta = _ReticleComposer.parseSvgMeta(targetSvg);
        final inner = _ReticleComposer.extractSvgInner(targetSvg);
        final scale = geometry.targetScale(targetSizeMil, tMeta.milWidth);
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

      if (showAdjLines) {
        buffer.writeln('''
          <line x1="$offsetXMil" y1="0" x2="$offsetXMil" y2="$offsetYMil" stroke="$lineColor" stroke-width="${sw * 1.5}"/>
          <line x1="$offsetXMil" y1="${-milHeight}" x2="$offsetXMil" y2="$milHeight" stroke="$lineColor" stroke-width="$sw" stroke-dasharray="0.1"/>
          <line x1="0" y1="$offsetYMil" x2="$offsetXMil" y2="$offsetYMil" stroke="$lineColor" stroke-width="${sw * 1.5}"/>
          <line x1="${-milWidth}" y1="$offsetYMil" x2="$milWidth" y2="$offsetYMil" stroke="$lineColor" stroke-width="$sw" stroke-dasharray="0.1"/>
          <circle cx="$offsetXMil" cy="$offsetYMil" r="0.2" fill="$lineColor"/>
        ''');
      }
    }

    buffer.writeln('</svg>');

    return buffer.toString();
  }

  static _SvgMeta parseSvgMeta(String svg) {
    // Get dimensions from viewBox
    double milWidth = 30.0;
    double milHeight = 30.0;

    final viewBoxMatch = RegExp(r'viewBox="([^"]+)"').firstMatch(svg);
    if (viewBoxMatch != null) {
      final parts = viewBoxMatch.group(1)!.trim().split(RegExp(r'\s+'));
      if (parts.length == 4) {
        // parts: [minX, minY, width, height]
        milWidth = double.tryParse(parts[2]) ?? milWidth;
        milHeight = double.tryParse(parts[3]) ?? milHeight;
      }
    }

    return _SvgMeta(milWidth: milWidth, milHeight: milHeight);
  }

  static String extractSvgInner(String svg) {
    final start = svg.indexOf('>') + 1;
    final end = svg.lastIndexOf('</svg>');
    if (start <= 0 || end <= start) return '';
    return svg.substring(start, end);
  }
}
