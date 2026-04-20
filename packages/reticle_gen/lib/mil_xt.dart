import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

// ─── Geometric constants (common to all variants) ───────────────────────
class MilXtSizes {
  static const double B = 0.05;
  static const double C = 0.1;
  static const double D = 0.2;
  static const double E = 1;
  static const double G = 0.5;
  static const double H = 0.2;
  static const double I = 0.6;
  static const double J = 0.2;
  static const double L = 0.05;
  static const double M = 0.1;
  static const double N = 0.05;
}

// ─── Reticle Variant (subtension chart) ─

/// Subtension parameters for a specific scope model.
/// [a] — line thickness (mils)
/// [f] — large font size (mils)
/// [k] — small font size (mils)
class MilXtVariant {
  final String name;
  final double a;
  final double f;
  final double k;

  const MilXtVariant({
    required this.name,
    required this.a,
    required this.f,
    required this.k,
  });

  /// Identifier for the file name: "ATACR 7-35" → "atacr_7-35"
  String get fileId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '-');

  // ── Predefined options ─────────────────────────────────────────────────

  // defaultVariant is a separate const because it is used as the default value of the parameter
  static const defaultVariant = MilXtVariant(
    name: 'ATACR 7-35',
    a: 0.033,
    f: 0.40,
    k: 0.20,
  );

  static const all = [
    defaultVariant,
    MilXtVariant(name: 'ATACR 5-25', a: 0.030, f: 0.40, k: 0.20),
    MilXtVariant(name: 'ATACR 4-20', a: 0.040, f: 0.50, k: 0.25),
    MilXtVariant(name: 'ATACR 4-16', a: 0.040, f: 0.60, k: 0.30),
    MilXtVariant(name: 'NX8 4-32', a: 0.036, f: 0.44, k: 0.22),
    MilXtVariant(name: 'NX8 2.5-20', a: 0.041, f: 0.50, k: 0.25),
    MilXtVariant(name: 'SHV 4-14', a: 0.044, f: 0.40, k: 0.20),
  ];

  /// Finds a variant by name (case insensitive).
  /// Returns [defaultVariant] if not found.
  static MilXtVariant byName(String name) {
    final lower = name.toLowerCase();
    return all.firstWhere(
      (v) => v.name.toLowerCase() == lower || v.fileId == lower,
      orElse: () => defaultVariant,
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class MilXtReticleDrawer implements SVGDrawerInterface {
  final MilXtVariant variant;

  MilXtReticleDrawer({this.variant = MilXtVariant.defaultVariant});

  @override
  void draw(MilReticleSVGCanvas canvas) {
    final A = variant.a;
    final F = variant.f;
    final K = variant.k;
    const B = MilXtSizes.B;
    const C = MilXtSizes.C;
    const D = MilXtSizes.D;
    const E = MilXtSizes.E;
    const G = MilXtSizes.G;
    const H = MilXtSizes.H;
    const I = MilXtSizes.I;
    const J = MilXtSizes.J;
    const L = MilXtSizes.L;
    const M = MilXtSizes.M;
    const N = MilXtSizes.N;

    const String bgColor = 'transparent';
    const String color = "onSurface"; //"onSurface";
    const String accentColor = "red";
    const double halfI = I / 2;
    const double labelOffset = 0.4;

    canvas.clip(
      shape: (c) => c.circle(0, 0, 24, bgColor),
      draw: (c) {
        c.fill(bgColor);

        // ── Labels + dot grid for one row by j ─
        void zoneRow(double j, double xOff, double dotRange) {
          final fontSize = j.round() % 2 == 0 ? F : K;
          c
            ..label(j.toStringAsFixed(0), xOff, j, color, h: fontSize)
            ..label(j.toStringAsFixed(0), -xOff, j, color, h: fontSize)
            // Large dots every E, skip center (i==0):
            ..hDotLine(j, -dotRange, -E, E, M / 2, color)
            ..hDotLine(j, E, dotRange, E, M / 2, color)
            // Small dots every D, skip |i|≤D:
            ..hDotLine(j, -dotRange, -2 * D, D, N / 2, color)
            ..hDotLine(j, 2 * D, dotRange, D, N / 2, color);
        }

        c
          // ..fill("white")
          // 1. Main axes
          ..hLine(0, 0.1, 10, accentColor, A)
          ..hLine(0, -0.1, -10, accentColor, A)
          ..vLine(0, -0.1, -5, accentColor, A);

        // Horizontal extension of axis + frame
        final double minI = I - 0.2;
        final double minHalfI = halfI - 0.1;
        c
          ..path(
            (PathBuilder()
                  ..moveTo(-15, 0)
                  ..lineTo(-10.2, 0)
                  ..moveTo(15, 0)
                  ..lineTo(10.2, 0)
                  ..moveTo(11, -minHalfI)
                  ..lineTo(10.2, 0)
                  ..moveTo(11, minHalfI)
                  ..lineTo(10.2, 0)
                  ..moveTo(-11, -minHalfI)
                  ..lineTo(-10.2, 0)
                  ..moveTo(-11, minHalfI)
                  ..lineTo(-10.2, 0))
                .d,
            'none',
            stroke: color,
            strokeWidth: A,
          )
          ..rect(
            -15,
            -minHalfI,
            4,
            minI,
            "transparent",
            stroke: color,
            strokeWidth: A,
          )
          ..rect(
            11,
            -minHalfI,
            4,
            minI,
            "transparent",
            stroke: color,
            strokeWidth: A,
          )
          ..rect(-24, -minHalfI, 24 - 15, minI, color)
          ..rect(15, -minHalfI, 24 - 15, minI, color);

        // Additional lines 11..15 (outside the frame)
        c
          ..hRuler(11, 15, E, I, color, A)
          ..hRuler(-11, -15, -E, I, color, A);

        // 2a. Horizontal axis marks (±1..10)
        for (double i = -10; i <= 10; i += E) {
          if (i == 0) continue;
          c.label(
            i.abs().toStringAsFixed(0),
            i,
            -(halfI + F + K * 0.35),
            color,
            h: K,
          );
        }

        final List<List<double>> horizontalRuler = [
          [10, 1, I, 0],
          [10 - D, 1 - D, H, H / 2],
          [10 - 2 * D, 1 - 2 * D, H, -H / 2],
          [10 - 3 * D, 1 - 3 * D, H, -H / 2],
          [10 - 4 * D, 2 - 4 * D, H, H / 2],
        ];

        for (final [start, end, tickWidth, y] in horizontalRuler) {
          c
            ..hRuler(start, end, -E, tickWidth, accentColor, A, y: y)
            ..hRuler(-start, -end, E, tickWidth, accentColor, A, y: y);
        }

        c
          ..vLine(D, 0, C, accentColor, A)
          ..vLine(-D, 0, C, accentColor, A);

        // 2b. Vertical axis lines (0..24) — positive part + center
        // 2c. Vertical axis lines (-5..-1) — negative part

        final List<List<double>> verticalRuler = [
          [1 + D, 24, H, -H / 2],
          [2 * D, 24, H, H / 2],
          [3 * D, 24, H, H / 2],
          [4 * D, 24, H, -H / 2],
          [-5, -1, I, 0],
          [-5 + D, -1 + D, H, -H / 2],
          [-5 + 2 * D, -1 + 2 * D, H, H / 2],
          [-5 + 3 * D, -1 + 3 * D, H, H / 2],
          [-5 + 4 * D, -2 + 4 * D, H, -H / 2],
          [1, 24, J / 2, J / 2 * 1.5],
          [1, 24, J / 2, -J / 2 * 1.5],
        ];

        for (final [start, end, tickWidth, x] in verticalRuler) {
          c.vRuler(start, end, E, tickWidth, accentColor, A, x: x);
        }

        c
          ..hLine(D, C, -C, accentColor, A)
          ..hLine(-D, C, -C, accentColor, A)
          ..vDotLine(0, 0, 24, E, B / 2, accentColor)
          ..vDashLine(0, 0.1, 24, 0.8, 0.2, accentColor, A);

        for (double i = -5; i <= -2; i += E) {
          c.label(
            i.abs().toStringAsFixed(0),
            -(halfI + labelOffset),
            i,
            color,
            h: K,
            anchor: 'end',
          );
        }

        // 3. Dot grid between lines
        c
          ..dotGrid(-(2 + G), G, 2 + G, 4 + G, E, E, L / 2, color)
          ..dotGrid(-(3 + G), 5 + G, 3 + G, 8 + G, E, E, L / 2, color)
          ..dotGrid(-(4 + G), 9 + G, 4 + G, 24 + G, E, E, L / 2, color);

        // 4. Labels + grid of points by zones (±mirrored via zoneRow)
        for (double j = 1; j <= 4; j++) {
          zoneRow(j, 3 + labelOffset, 3);
        }
        for (double j = 5; j <= 8; j++) {
          zoneRow(j, 4 + labelOffset, 4);
        }
        for (double j = 9; j <= 24; j++) {
          zoneRow(j, 5 + labelOffset, 5);
        }
      },
    );
  }
}

void main(List<String> args) {
  // Usage: dart mil_xt.dart [variant] [output.svg]
  // variant — name or fileId (e.g. "ATACR 7-35" or "atacr_7-35")
  // if not specified or not found — defaultVariant is used
  // output — path to file; if not specified — "<fileId>.svg"
  final variant = args.isNotEmpty
      ? MilXtVariant.byName(args[0])
      : MilXtVariant.defaultVariant;
  final outputPath = args.length >= 2 ? args[1] : '${variant.fileId}.svg';

  print('Generating "${variant.name}"  →  $outputPath');
  print('  A=${variant.a}  F=${variant.f}  K=${variant.k}');

  MilReticleSVGCanvas(milWidth: 48, milHeight: 48)
    ..generate(MilXtReticleDrawer(variant: variant))
    ..svg.export(outputPath);
}
