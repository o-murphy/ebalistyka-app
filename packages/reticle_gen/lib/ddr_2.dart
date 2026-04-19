import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

/// 1 MOA expressed in MIL: (π/10800) / (π/3200) = 3200/10800 = 8/27
const double moaToMil = 8.0 / 27.0;

// ─── Geometric constants (common to all variants) ─────────────────────
class Ddr2Sizes {
  static const double A = 28.8; // MOA
  static const double B = 12.9; // MOA
  static const double C = 1.5; // MOA
  static const double D = 0.5; // MOA
  static const double E = 0.5; // MOA
  static const double F = 0.5; // MOA
  static const double G = 0.095; // MOA
  static const double H = 0.25; // MOA
  static const double I = 0.5; // MOA
  static const double J = 1.0; // MOA
  static const double K = 2.0; // MOA
  static const double L = 3.0; // MOA
  static const double M = 0.016; // MOA
  static const double N = 2.5; // MOA
  static const double O = 0.5; // MOA
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class Ddr2ReticleDrawer implements SVGDrawerInterface {
  Ddr2ReticleDrawer();

  @override
  void draw(MilReticleSVGCanvas canvas) {
    // const A = Ddr2Sizes.A;
    const B = Ddr2Sizes.B;
    // const C = Ddr2Sizes.C;
    const D = Ddr2Sizes.D;
    const E = Ddr2Sizes.E;
    const F = Ddr2Sizes.F;
    const G = Ddr2Sizes.G;
    const H = Ddr2Sizes.H;
    const I = Ddr2Sizes.I;
    const J = Ddr2Sizes.J;
    const K = Ddr2Sizes.K;
    const L = Ddr2Sizes.L;
    const M = Ddr2Sizes.M;
    const N = Ddr2Sizes.N;
    const O = Ddr2Sizes.O;
    const P = H;

    const String bgColor = "white";
    const String color = "black"; //"onSurface";

    canvas.clip(
      shape: (c) => c.circle(0, 0, B, 'white'),
      draw: (c) {
        c.fill(bgColor);

        c
          ..dot(0, 0, G / 2, color)
          ..dot(0, L, G / 2, color)
          ..hLine(0, F, F + E, color, M)
          ..hLine(0, -F, -(F + E), color, M)
          ..vLine(0, I, N, color, M)
          ..hLine(J, -O / 2, O / 2, color, M)
          ..hLine(K, -O / 2, O / 2, color, M);

        c
          ..hLine(0, B, D + E + F + H, color, P)
          ..hLine(0, -B, -(D + E + F + H), color, P)
          ..batchLines(color, M, fill: color, (pb) {
            final offset = D + E + F;
            final tipOffset = offset + H;
            final halfP = P / 2;

            // Top right arrow (filled triangle)
            pb
              ..moveTo(offset, 0)
              ..lineTo(tipOffset, halfP)
              ..lineTo(tipOffset, -halfP)
              ..close();

            // Top left arrow (filled triangle)
            pb
              ..moveTo(-offset, 0)
              ..lineTo(-tipOffset, halfP)
              ..lineTo(-tipOffset, -halfP)
              ..close();

            // Contoured arrow edges
            pb
              ..moveTo(offset, 0)
              ..lineTo(tipOffset, halfP)
              ..moveTo(offset, 0)
              ..lineTo(tipOffset, -halfP)
              ..moveTo(-offset, 0)
              ..lineTo(-tipOffset, halfP)
              ..moveTo(-offset, 0)
              ..lineTo(-tipOffset, -halfP);
          });
      },
    );
  }
}

void main(List<String> args) {
  // Usage: dart ddr_2.dart [output.svg]
  // output — path to file; if not specified — "DDR-2.svg"

  final outputPath = args.isNotEmpty ? args[0] : 'DDR-2.svg';

  print('Generating "DDR-2"  →  $outputPath');

  MilReticleSVGCanvas(
      milWidth: 26 * moaToMil,
      milHeight: 26 * moaToMil,
      unitScale: moaToMil,
    )
    ..generate(Ddr2ReticleDrawer())
    ..svg.export(outputPath);
}
