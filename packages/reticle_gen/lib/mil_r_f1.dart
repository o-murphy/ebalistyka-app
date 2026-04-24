import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

// ─── Geometric constants (common to all variants) ───────────────────────
class MilRF1Sizes {
  static const double A = 10;
  static const double D = 0.5;
  static const double E = 0.5;
  static const double F = 1.0;
  static const double G = 1.0;
  static const double I = 0.2;
  static const double J = 1.0;
  static const double K = 0.8;
  static const double L = 0.4;
  static const double M = 2.0;
  static const double O = 2.0;
  static const double P = 0.2;
  static const double Q = 0.1;
}

// ─── Reticle option (subtension chart) ─

/// Subtension parameters for a specific scope model.
/// [b] — thickness of thin lines (mils)
/// [c] — thickness of thick lines (mils)
/// [h] — height of text/font (mils)
/// [n] — pitch of captions (mils)
class MilRF1Variant {
  final String name;
  final double b;
  final double c;
  final double h;
  final double n;

  const MilRF1Variant({
    required this.name,
    required this.b,
    required this.c,
    required this.h,
    required this.n,
  });

  /// Identifier for the file name: "ATACR 16x F1" → "atacr_16x_f1"
  String get fileId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '-');

  // ── Predefined options ─────────────────────────────────────────────────

  // defaultVariant is a separate const because it is used as the default value of the parameter
  static const defaultVariant = MilRF1Variant(
    name: 'ATACR 16x F1',
    b: 0.05,
    c: 0.1,
    h: 0.36,
    n: 0.041,
  );

  static const all = [
    defaultVariant,
    MilRF1Variant(name: 'ATACR 25x F1', b: 0.036, c: 0.1, h: 0.28, n: 0.029),
    MilRF1Variant(name: 'ATACR 35x F1', b: 0.036, c: 0.1, h: 0.28, n: 0.029),
  ];

  /// Finds a variant by name (case insensitive).
  /// Returns [defaultVariant] if not found.
  static MilRF1Variant byName(String name) {
    final lower = name.toLowerCase();
    return all.firstWhere(
      (v) => v.name.toLowerCase() == lower || v.fileId == lower,
      orElse: () => defaultVariant,
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class MilRF1ReticleDrawer implements SVGDrawerInterface {
  final MilRF1Variant variant;

  MilRF1ReticleDrawer({this.variant = MilRF1Variant.defaultVariant});

  @override
  void draw(MilReticleSVGCanvas canvas) {
    const A = MilRF1Sizes.A;
    final B = variant.b;
    final C = variant.c;
    const D = MilRF1Sizes.D;
    const E = MilRF1Sizes.E;
    const F = MilRF1Sizes.F;
    const G = MilRF1Sizes.G;
    final H = variant.h;
    const I = MilRF1Sizes.I;
    const J = MilRF1Sizes.J;
    const K = MilRF1Sizes.K;
    const L = MilRF1Sizes.L;
    const M = MilRF1Sizes.M;
    final N = variant.n;
    const O = MilRF1Sizes.O;
    const P = MilRF1Sizes.P;
    const Q = MilRF1Sizes.Q;

    const String bgColor = 'transparent';
    const String color = "onSurface"; //"onSurface";
    const String accentColor = "red";

    canvas.clip(
      shape: (c) => c.circle(0, 0, 10, fill: bgColor),
      draw: (c) {
        c.fill(bgColor);

        c
          ..cross(0, 0, G, accentColor, B)
          ..hLine(1, -J / 2, J / 2, accentColor, B)
          ..hLine(-1, -J / 2, J / 2, accentColor, B)
          ..hLine(5, -M / 2, M / 2, accentColor, B)
          ..hLine(-5, -J / 2, J / 2, accentColor, B)
          ..vRuler(-5, -2, F, K, accentColor, B)
          ..vRuler(-3.5, -1.5, F, L, accentColor, B)
          ..vRuler(2, A, F, K, accentColor, B)
          ..vRuler(1.5, A, F, L, accentColor, B)
          ..hRuler(-A / 2, A / 2, A * F, J, accentColor, B)
          ..hRuler(-F, F, 2 * F, J, accentColor, B)
          ..hRuler(-A / 2, -1, F, L, accentColor, B, y: L / 2)
          ..hRuler(A / 2, 1, -F, L, accentColor, B, y: L / 2)
          ..hRuler(-(A / 2 - 1), -1, F / 2, P, accentColor, B, y: P / 2)
          ..hRuler(A / 2 - 1, 1, -F / 2, P, accentColor, B, y: P / 2)
          ..hRuler(-A / 2, -(A / 2 - 1), P, P, accentColor, B, y: P / 2)
          ..hRuler(A / 2, A / 2 - 1, -P, P, accentColor, B, y: P / 2)
          ..vDashLine(0, 3 * E - P, A, 2 * P, (E - 2 * P), accentColor, B)
          ..vDashLine(0, -(3 * E - P), -5, 2 * P, (E - 2 * P), accentColor, B)
          ..hDashLine(0, 3 * E - P, A / 2 - 1, 2 * P, Q, accentColor, B)
          ..hDashLine(0, -(3 * E - P), -(A / 2 - 1), 2 * P, Q, accentColor, B)
          ..hLine(0, -A / 2, -A / 2 + 1, accentColor, B)
          ..hLine(0, A / 2, A / 2 - 1, accentColor, B)
          ..hLine(0, G / 2 + Q, 3 * E - P - Q, accentColor, B)
          ..hLine(0, -(G / 2 + Q), -(3 * E - P - Q), accentColor, B)
          ..vLine(0, G / 2 + Q, 3 * E - P - Q, accentColor, B)
          ..vLine(0, -(G / 2 + Q), -(3 * E - P - Q), accentColor, B);

        for (double i = -A / 2 + 1; i <= A / 2 - 1; i += F * 2) {
          if (i == 0) continue;
          c.label(i.abs().toStringAsFixed(0), i, H * 0.65 - 1, color, h: H);
        }

        for (double i = 2; i <= A; i += F * 2) {
          c.label(i.abs().toStringAsFixed(0), -1, i, color, h: H);
        }

        c
          ..vLine(3.5, 1, 3.3, color, N)
          ..hLine(3, 3.5 - 1, 3.5 + 1, color, N)
          ..vRuler(1, 2, F, K, color, N, x: 3.5)
          ..vRuler(1, 3 - 0.4, P, P, color, N, x: 3.5 - P / 2)
          ..vRuler(1 + 0.1, 3 - 0.2, P, P, color, N, x: 3.5 + P / 2)
          ..hRuler(3.5 - O / 2, 3.5 + O / 2, 2 * F, K, color, N, y: 3)
          //
          ..hRuler(3.5 + 0.1 - O / 2, 3.5 - 0.3, P, P, color, N, y: 3 + P / 2)
          ..hRuler(3.5 + 0.3, 3.5 - 0.1 + O / 2, P, P, color, N, y: 3 + P / 2)
          ..hRuler(3.5 + 0.2 - O / 2, 3.5 - 0.3, P, P, color, N, y: 3 - P / 2)
          ..hRuler(3.5 + 0.4, 3.5 - 0.2 + O / 2, P, P, color, N, y: 3 - P / 2)
          ..hLine(2.8, 3.5, 3.5 - P / 2, color, N)
          ..hLine(2.9, 3.5, 3.5 + P / 2, color, N)
          ..vLine(3.3, 3 - P / 2, 3, color, N)
          ..vLine(3.4, 3 + P / 2, 3, color, N)
          ..vLine(3.6, 3 + P / 2, 3, color, N)
          ..vLine(3.7, 3 - P / 2, 3, color, N);

        c
          ..path(
            (PathBuilder()
                  ..moveTo(30, 0)
                  ..lineTo(A / 2 + I, 0)
                  ..moveTo(-30, 0)
                  ..lineTo(-(A / 2 + I), 0))
                .d,
            stroke: color,
            strokeWidth: B,
          )
          ..path(
            (PathBuilder()
                  ..moveTo(30, D / 2)
                  ..lineTo(A / 2 + 1, D / 2)
                  ..lineTo(A / 2 + I, 0)
                  ..lineTo(A / 2 + 1, -D / 2)
                  ..lineTo(30, -D / 2)
                  ..moveTo(-30, D / 2)
                  ..lineTo(-(A / 2 + 1), D / 2)
                  ..lineTo(-(A / 2 + I), 0)
                  ..lineTo(-(A / 2 + 1), -D / 2)
                  ..lineTo(-30, -D / 2))
                .d,
            stroke: color,
            strokeWidth: C,
          )
          ..label('2', 3.5 + 0.5, 1, color, h: H);
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
      ? MilRF1Variant.byName(args[0])
      : MilRF1Variant.defaultVariant;
  final outputPath = args.length >= 2 ? args[1] : '${variant.fileId}.svg';

  print('Generating "${variant.name}"  →  $outputPath');
  print('  B=${variant.b}  C=${variant.c}  H=${variant.h}  N=${variant.n}');

  MilReticleSVGCanvas(milWidth: 20, milHeight: 20)
    ..generate(MilRF1ReticleDrawer(variant: variant))
    ..svg.export(outputPath);
}
