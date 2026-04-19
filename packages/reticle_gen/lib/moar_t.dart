import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

/// 1 MOA expressed in MIL: (π/10800) / (π/3200) = 3200/10800 = 8/27
const double moaToMil = 8.0 / 27.0;

// ─── Geometric constants (common to all variants) ───────────────────────
class MoarTSizes {
  static const double A = 40;
  static const double B = 1.72;
  static const double C = 0.5;
  static const double D = 2;
  static const double E = 4;
  static const double G = 1;
  static const double H = 2;
  static const double K = 0.5;
  static const double L = 1;
  static const double M = 1;
  static const double O = 2;
}

// ─── Reticle option (subtension chart) ─

/// Subtension parameters for a specific scope model.
/// [f]
/// [i]
/// [j]
/// [n]
class MoarTVariant {
  final String name;
  final double f;
  final double i;
  final double j;
  final double n;

  const MoarTVariant({
    required this.name,
    required this.f,
    required this.i,
    required this.j,
    required this.n,
  });

  /// Identifier for the file name: "ATACR 7-35" → "atacr_7-35"
  String get fileId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '-');

  // ── Predefined options ─────────────────────────────────────────────────

  // defaultVariant is a separate const because it is used as the default value of the parameter
  static const defaultVariant = MoarTVariant(
    name: 'NXS 22x & 32x',
    f: 0.75,
    i: 0.3,
    j: 0.0625,
    n: 0.6,
  );

  static const all = [
    defaultVariant,
    MoarTVariant(name: 'ATACR 25x', f: 0.65, i: 0.25, j: 0.05, n: 0.5),
  ];

  /// Finds a variant by name (case insensitive).
  /// Returns [defaultVariant] if not found.
  static MoarTVariant byName(String name) {
    final lower = name.toLowerCase();
    return all.firstWhere(
      (v) => v.name.toLowerCase() == lower || v.fileId == lower,
      orElse: () => defaultVariant,
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class MoarTReticleDrawer implements SVGDrawerInterface {
  final MoarTVariant variant;

  MoarTReticleDrawer({this.variant = MoarTVariant.defaultVariant});

  @override
  void draw(MilReticleSVGCanvas canvas) {
    const A = MoarTSizes.A;
    const B = MoarTSizes.B;
    const C = MoarTSizes.C;
    const D = MoarTSizes.D;
    const E = MoarTSizes.E;
    final F = variant.f;
    const G = MoarTSizes.G;
    const H = MoarTSizes.H;
    final I = variant.i;
    final J = variant.j;
    const K = MoarTSizes.K;
    const L = MoarTSizes.L;
    const M = MoarTSizes.M;
    final N = variant.n;
    const O = MoarTSizes.O;

    const String bgColor = "white";
    const String color = "black"; //"onSurface";
    const String accentColor = "red";

    canvas.clip(
      shape: (c) => c.circle(0, 0, 30, 'white'),
      draw: (c) {
        c.fill(bgColor);

        c
          ..cross(0, 0, O, accentColor, J)
          ..hLine(0, 2, A / 2, color, J)
          ..hLine(0, -2, -A / 2, color, J)
          ..vLine(0, -10, -2, color, J)
          ..vLine(0, A / 2, 2, color, J)
          ..vLine(-2, -D / 2, D / 2, color, J)
          ..vLine(2, -D / 2, D / 2, color, J)
          ..vLine(-A / 2, -D / 2, D / 2, color, J)
          ..vLine(A / 2, -D / 2, D / 2, color, J)
          ..hRuler(A / 2, 2, -H, L, color, J, y: L / 2)
          ..hRuler(-A / 2, -2, H, L, color, J, y: L / 2)
          ..hRuler(A / 2, 2, -G, K, color, J, y: K / 2)
          ..hRuler(-A / 2, -2, G, K, color, J, y: K / 2)
          ..hRuler(-10, -A / 2 + 1, -10, -E, color, J)
          ..hRuler(10, A / 2 - 1, 10, E, color, J)
          ..vRuler(-10, -2, H, D, color, J)
          ..vRuler(2, A / 2, H, D, color, J)
          ..vRuler(-10, -2, G, C, color, J)
          ..vRuler(2, A / 2, G, C, color, J)
          ..vRuler(10, A / 2 - 1, 10, E, color, J)
          ..vRuler(-10, -10, -10, E, color, J);

        for (double i = -A / 2; i <= A / 2; i += 10) {
          if (i == 0) continue;
          c.text(i.abs().toStringAsFixed(0), i, -3 + N, color, fontSize: N);
        }

        for (double i = 10; i <= A / 2; i += 10) {
          c.text(
            i.abs().toStringAsFixed(0),
            -3,
            i + F * 0.35,
            color,
            fontSize: F,
            textAnchor: "middle",
          );
        }

        c
          ..rect(-35, -B / 2, 35 - A / 2 - 4, B, color)
          ..rect(A / 2 + 4, -B / 2, 35 - A / 2 + 4, B, color)
          ..path(
            (PathBuilder()
                  ..moveTo(35, 0)
                  ..lineTo(A / 2 + M, 0)
                  ..moveTo(-35, 0)
                  ..lineTo(-(A / 2 + M), 0))
                .d,
            'none',
            stroke: color,
            strokeWidth: J,
          )
          ..path(
            (PathBuilder()
                  ..moveTo(35, B / 2)
                  ..lineTo(A / 2 + 3, B / 2)
                  ..lineTo(A / 2 + M, 0)
                  ..lineTo(A / 2 + 3, -B / 2)
                  ..lineTo(35, -B / 2)
                  ..moveTo(-35, B / 2)
                  ..lineTo(-(A / 2 + 3), B / 2)
                  ..lineTo(-(A / 2 + M), 0)
                  ..lineTo(-(A / 2 + 3), -B / 2)
                  ..lineTo(-35, -B / 2))
                .d,
            'none',
            stroke: color,
            strokeWidth: I,
          );

        c
          ..path(
            (PathBuilder()
                  ..moveTo(0, 35)
                  ..lineTo(0, A / 2 + M))
                .d,
            'none',
            stroke: color,
            strokeWidth: J,
          )
          ..path(
            (PathBuilder()
                  ..moveTo(B / 2, 35)
                  ..lineTo(B / 2, A / 2 + 3)
                  ..lineTo(0, A / 2 + M)
                  ..lineTo(-B / 2, A / 2 + 3)
                  ..lineTo(-B / 2, 35))
                .d,
            'none',
            stroke: color,
            strokeWidth: I,
          )
          ..rect(-B / 2, A / 2 + 4, B, 35 - A / 2 + 4, color);
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
      ? MoarTVariant.byName(args[0])
      : MoarTVariant.defaultVariant;
  final outputPath = args.length >= 2 ? args[1] : '${variant.fileId}.svg';

  print('Generating "${variant.name}"  →  $outputPath');
  print('  F=${variant.f}  I=${variant.i} J=${variant.j} N=${variant.n}');

  MilReticleSVGCanvas(
      milWidth: 60 * moaToMil,
      milHeight: 60 * moaToMil,
      unitScale: moaToMil,
    )
    ..generate(MoarTReticleDrawer(variant: variant))
    ..svg.export(outputPath);
}
