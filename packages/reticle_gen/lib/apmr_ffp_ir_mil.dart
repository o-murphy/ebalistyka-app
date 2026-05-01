import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

// ─── Geometric constants (common to all variants) ─────────────────────
class ApmrFfpIrMilSizes {
  static const double A1 = 0.02;
  static const double A2 = 0.4;
  static const double A3 = 0.05;
  static const double A4 = 0.1;
  static const double B1 = 0.2;
  static const double B2 = 0.4;
  static const double B3 = 0.3;
  static const double C1 = 2;
  static const double D1 = 0.5;
  static const double D2 = 1;
  static const double D3 = 0.2;
  static const double D4 = 1;
  static const double D5 = 0.2;
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class ApmrFfpIrMilReticleDrawer implements SVGDrawerInterface {
  ApmrFfpIrMilReticleDrawer();

  @override
  void draw(MilReticleSVGCanvas canvas) {
    // const A = ApmrFfpIrMilSizes.A;
    const A1 = ApmrFfpIrMilSizes.A1;
    const A2 = ApmrFfpIrMilSizes.A2;
    const A3 = ApmrFfpIrMilSizes.A3;
    const A4 = ApmrFfpIrMilSizes.A4;
    const B1 = ApmrFfpIrMilSizes.B1;
    const B2 = ApmrFfpIrMilSizes.B2;
    const B3 = ApmrFfpIrMilSizes.B3;
    const C1 = ApmrFfpIrMilSizes.C1;
    const D1 = ApmrFfpIrMilSizes.D1;
    const D2 = ApmrFfpIrMilSizes.D2;
    const D3 = ApmrFfpIrMilSizes.D3;
    const D4 = ApmrFfpIrMilSizes.D4;
    const D5 = ApmrFfpIrMilSizes.D5;

    const L = 9 * D2;
    const H = 0.4;

    const String bgColor = 'transparent';
    const String color = "onSurface";
    const String accentColor = "red";

    canvas.clip(
      shape: (c) => c.circle(0, 0, 2 * L, fill: bgColor),
      draw: (c) {
        c.fill(bgColor);
        c.hLine(0, -L, L, accentColor, A1);
        c.vLine(0, -L, L, accentColor, A1);
        c.vRuler(-L, L, D2, B2, accentColor, A1);
        c.vRuler(-L, 7 * D2, D1, B1, accentColor, A1, x: B1 / 2);
        c.vRuler(L - 2 * D2, L, D3, B3, accentColor, A1);
        c.hRuler(-L, L, D2, B2, accentColor, A1);
        c.hRuler(-7 * D2, 7 * D2, D1, B1, accentColor, A1, y: -B1 / 2);
        c.hRuler(L - 2 * D2, L, D3, B3, accentColor, A1);
        c.hRuler(-L, -(L - 2 * D2), D3, B3, accentColor, A1);
        for (double i = 2; i <= L; i += 2) {
          c.label(i.abs().toStringAsFixed(0), i, 0.75, accentColor, h: H);
          c.label(i.abs().toStringAsFixed(0), -i, 0.75, accentColor, h: H);
          c.label(i.abs().toStringAsFixed(0), 1, -i, accentColor, h: H);
        }
        c.label(4.toStringAsFixed(0), -2.5, 4 * D4, accentColor, h: H);
        c.label(6.toStringAsFixed(0), -3.5, 6 * D4, accentColor, h: H);
        c.label(8.toStringAsFixed(0), -4.5, 8 * D4, accentColor, h: H);
        // A4 dots
        c.hDotLine(1, -1, -1, D4, A4 / 2, accentColor);
        c.hDotLine(1, 1, 1, D4, A4 / 2, accentColor);
        c.hDotLine(2, -1, -1, D4, A4 / 2, accentColor);
        c.hDotLine(2, 1, 1, D4, A4 / 2, accentColor);
        c.hDotLine(3, -1, -1, D4, A4 / 2, accentColor);
        c.hDotLine(3, 1, 1, D4, A4 / 2, accentColor);
        c.hDotLine(4, -1, -2, D4, A4 / 2, accentColor);
        c.hDotLine(4, 1, 2, D4, A4 / 2, accentColor);
        c.hDotLine(5, -2, -1, D4, A4 / 2, accentColor);
        c.hDotLine(5, 1, 2, D4, A4 / 2, accentColor);
        c.hDotLine(6, -3, -1, D4, A4 / 2, accentColor);
        c.hDotLine(6, 1, 3, D4, A4 / 2, accentColor);
        c.hDotLine(7, -3, -1, D4, A4 / 2, accentColor);
        c.hDotLine(7, 1, 3, D4, A4 / 2, accentColor);
        c.hDotLine(8, -4, -1, D4, A4 / 2, accentColor);
        c.hDotLine(8, 1, 4, D4, A4 / 2, accentColor);
        c.hDotLine(9, -4, -1, D4, A4 / 2, accentColor);
        c.hDotLine(9, 1, 4, D4, A4 / 2, accentColor);
        // A3 dots
        c.hDotLine(1, -1, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(1, 0.4, 1, D5, A3 / 2, accentColor);
        c.hDotLine(2, -1, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(2, 0.4, 1, D5, A3 / 2, accentColor);
        c.hDotLine(3, -1, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(3, 0.4, 1, D5, A3 / 2, accentColor);
        c.hDotLine(4, -2, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(4, 0.4, 2, D5, A3 / 2, accentColor);
        c.hDotLine(5, -2, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(5, 0.4, 2, D5, A3 / 2, accentColor);
        c.hDotLine(6, -3, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(6, 0.4, 3, D5, A3 / 2, accentColor);
        c.hDotLine(7, -3, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(7, 0.4, 3, D5, A3 / 2, accentColor);
        c.hDotLine(8, -4, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(8, 0.4, 4, D5, A3 / 2, accentColor);
        c.hDotLine(9, -4, -0.4, D5, A3 / 2, accentColor);
        c.hDotLine(9, 0.4, 4, D5, A3 / 2, accentColor);

        PathBuilder pb;

        pb = PathBuilder();
        pb
          ..moveTo(-L - C1, 0)
          ..lineTo(-L - C1 - D2, -A2 / 2)
          ..lineTo(-15, -A2 / 2)
          ..lineTo(-15, A2 / 2)
          ..lineTo(-L - C1 - D2, A2 / 2)
          ..close();
        c.path(pb.d, fill: color);

        pb = PathBuilder();
        pb
          ..moveTo(L + C1, 0)
          ..lineTo(L + C1 + D2, -A2 / 2)
          ..lineTo(15, -A2 / 2)
          ..lineTo(15, A2 / 2)
          ..lineTo(L + C1 + D2, A2 / 2)
          ..close();
        c.path(pb.d, fill: color);

        pb = PathBuilder();
        pb
          ..moveTo(0, -(L + C1))
          ..lineTo(-A2 / 2, -(L + C1 + D2))
          ..lineTo(-A2 / 2, -15)
          ..lineTo(A2 / 2, -15)
          ..lineTo(A2 / 2, -(L + C1 + D2))
          ..close();
        c.path(pb.d, fill: color);

        pb = PathBuilder();
        pb
          ..moveTo(0, L + C1)
          ..lineTo(-A2 / 2, L + C1 + D2)
          ..lineTo(-A2 / 2, 15)
          ..lineTo(A2 / 2, 15)
          ..lineTo(A2 / 2, L + C1 + D2)
          ..close();
        c.path(pb.d, fill: color);
      },
    );
  }
}

void main(List<String> args) {
  // Usage: dart ddr_2.dart [output.svg]
  // output — path to file; if not specified — "DDR-2.svg"

  final outputPath = args.isNotEmpty ? args[0] : 'APMR-FFP-IR-MIL.svg';

  print('Generating "APMR-FFP-IR-MIL"  →  $outputPath');

  MilReticleSVGCanvas(milWidth: 30, milHeight: 30)
    ..generate(ApmrFfpIrMilReticleDrawer())
    ..svg.export(outputPath);
}
