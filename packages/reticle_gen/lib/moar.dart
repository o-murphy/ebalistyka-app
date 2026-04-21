import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

/// 1 MOA expressed in MIL: (π/10800) / (π/3200) = 3200/10800 = 8/27
const double moaToMil = 8.0 / 27.0;

// ─── Geometric constants (common to all variants) ───────────────────────
class MoarSizes {
  static const double A =
      40; // MOA (basic, but may vary depending on the variant)
  static const double B = 1.7188; // MOA
  static const double C = 0.5; // MOA
  static const double D = 2.0; // MOA
  static const double E = 4.0; // MOA
  static const double F = 1.0; // MOA
  static const double G = 2.0; // MOA
  static const double H =
      2.0; // MOA (typical value, for specific models see subtension chart)
  static const double K = 0.5; // MOA
  static const double L = 1.0; // MOA
  static const double M = 1.0; // MOA
  static const double N = 2.0; // MOA
  static const double O = 0.8; // MOA
}

// ─── Reticle option (subtension chart) ─

/// Subtension parameters for a specific scope model.
/// [a] - A value (MOA)
/// [h] - H value (MOA)
/// [i] - I value (MOA)
/// [j] - J value (MOA)
class MoarVariant {
  final String name;
  final double a; // A
  final double h; // H
  final double i; // I
  final double j; // J

  const MoarVariant({
    required this.name,
    required this.a,
    required this.h,
    required this.i,
    required this.j,
  });

  /// Identifier for the file name: "ATACR 7-35" → "atacr_7-35"
  String get fileId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '-');

  // ── Predefined options (according to the table) ─

  static const atacr16x = MoarVariant(
    name: 'ATACR 16x',
    a: 40,
    h: 0.16,
    i: 0.34,
    j: 1.25,
  );

  static const atacr20x = MoarVariant(
    name: 'ATACR 20x',
    a: 80,
    h: 0.137,
    i: 0.34,
    j: 1.14,
  );

  static const atacr25x = MoarVariant(
    name: 'ATACR 25x',
    a: 40,
    h: 0.125,
    i: 0.34,
    j: 0.95,
  );

  static const atacr35x = MoarVariant(
    name: 'ATACR 35x',
    a: 40,
    h: 0.125,
    i: 0.34,
    j: 1.05,
  );

  static const nx8_20x = MoarVariant(
    name: 'NX8 20x',
    a: 80,
    h: 0.152,
    i: 0.15,
    j: 1.16,
  );

  static const nx8_32x = MoarVariant(
    name: 'NX8 32x',
    a: 80,
    h: 0.132,
    i: 0.15,
    j: 1.14,
  );

  // defaultVariant — for backward compatibility
  static const defaultVariant = atacr25x;

  static const all = [atacr16x, atacr20x, atacr25x, atacr35x, nx8_20x, nx8_32x];

  /// Finds a variant by name (case insensitive).
  /// Returns [defaultVariant] if not found.
  static MoarVariant byName(String name) {
    final lower = name.toLowerCase();
    return all.firstWhere(
      (v) => v.name.toLowerCase() == lower || v.fileId == lower,
      orElse: () => defaultVariant,
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class MoarReticleDrawer implements SVGDrawerInterface {
  final MoarVariant variant;

  MoarReticleDrawer({this.variant = MoarVariant.defaultVariant});

  @override
  void draw(MilReticleSVGCanvas canvas) {
    final A = variant.a; // taken from variant (previously it was MoarSizes.A)
    const B = MoarSizes.B;
    const C = MoarSizes.C;
    const D = MoarSizes.D;
    const E = MoarSizes.E;
    const F = MoarSizes.F; // now with MoarSizes (1.0 MOA)
    const G = MoarSizes.G;
    final H = variant.h; // H from variant
    final I = variant.i; // I from variant
    final J = variant.j; // J from variant
    const K = MoarSizes.K;
    const L = MoarSizes.L;
    const M = MoarSizes.M;
    const N = MoarSizes.N; // now with MoarSizes (2.0 MOA)
    const O = MoarSizes.O; // 0.8 MOA

    const String bgColor = 'transparent';
    const String color = "onSurface"; //"onSurface";
    const String accentColor = "red";

    canvas.clip(
      shape: (c) => c.circle(0, 0, 40, fill: bgColor),
      draw: (c) {
        c.fill(bgColor);

        c
          ..cross(0, 0, N, accentColor, H)
          ..hLine(0, 2, A / 2, accentColor, H)
          ..hLine(0, -2, -A / 2, accentColor, H)
          ..vLine(0, -10, -2, accentColor, H)
          ..vLine(0, 40, 2, accentColor, H)
          ..vLine(-2, -D / 2, D / 2, accentColor, H)
          ..vLine(2, -D / 2, D / 2, accentColor, H)
          ..vLine(-A / 2, -D / 2, D / 2, accentColor, H)
          ..vLine(A / 2, -D / 2, D / 2, accentColor, H)
          ..hRuler(A / 2, 2, -G, L, accentColor, H, y: L / 2)
          ..hRuler(-A / 2, -2, G, L, accentColor, H, y: L / 2)
          ..hRuler(A / 2, 2, -F, K, accentColor, H, y: K / 2)
          ..hRuler(-A / 2, -2, F, K, accentColor, H, y: K / 2)
          ..hRuler(-10, -A / 2 + 1, -10, -E, accentColor, H)
          ..hRuler(10, A / 2 - 1, 10, E, accentColor, H)
          ..vRuler(-10, -2, G, D, accentColor, H)
          ..vRuler(2, 40, G, D, accentColor, H)
          ..vRuler(-10, -2, F, C, accentColor, H)
          ..vRuler(2, 40, F, C, accentColor, H)
          ..vRuler(10, 40, 10, E, accentColor, H)
          ..vRuler(-10, -10, -10, E, accentColor, H);

        for (double i = -A / 2; i <= A / 2; i += 10) {
          if (i == 0) continue;
          c.label(i.abs().toStringAsFixed(0), i, -3 + O * 0.65, color, h: O);
        }

        for (double i = 10; i <= 40; i += 10) {
          c.label(i.abs().toStringAsFixed(0), -3, i, color, h: J);
        }

        c
          ..rect(-40, -B / 2, 40 - A / 2 - 15, B, color)
          ..rect(A / 2 + 15, -B / 2, 40 - A / 2 + 15, B, color)
          ..path(
            (PathBuilder()
                  ..moveTo(40, 0)
                  ..lineTo(A / 2 + M, 0)
                  ..moveTo(-40, 0)
                  ..lineTo(-(A / 2 + M), 0))
                .d,
            'none',
            stroke: color,
            strokeWidth: H,
          )
          ..path(
            (PathBuilder()
                  ..moveTo(40, B / 2)
                  ..lineTo(A / 2 + 3, B / 2)
                  ..lineTo(A / 2 + M, 0)
                  ..lineTo(A / 2 + 3, -B / 2)
                  ..lineTo(40, -B / 2)
                  ..close()
                  ..moveTo(-40, B / 2)
                  ..lineTo(-(A / 2 + 3), B / 2)
                  ..lineTo(-(A / 2 + M), 0)
                  ..lineTo(-(A / 2 + 3), -B / 2)
                  ..lineTo(-40, -B / 2)
                  ..close())
                .d,
            'none',
            stroke: color,
            strokeWidth: I,
          );
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
      ? MoarVariant.byName(args[0])
      : MoarVariant.defaultVariant;
  final outputPath = args.length >= 2 ? args[1] : '${variant.fileId}.svg';

  print('Generating "${variant.name}"  →  $outputPath');

  MilReticleSVGCanvas(
      milWidth: 80 * moaToMil,
      milHeight: 80 * moaToMil,
      unitScale: moaToMil,
    )
    ..generate(MoarReticleDrawer(variant: variant))
    ..svg.export(outputPath);
}
