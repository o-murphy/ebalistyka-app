import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

// ─── Geometric constants (common to all variants) ─────────────────────
class ApmrFfpIrMilSizes {
  static const double a1 = 0.02;
  static const double a2 = 0.4;
  static const double a3 = 0.05;
  static const double a4 = 0.1;
  static const double b1 = 0.2;
  static const double b2 = 0.4;
  static const double b3 = 0.3;
  static const double c1 = 2;
  static const double d1 = 0.5;
  static const double d2 = 1;
  static const double d3 = 0.2;
  static const double d4 = 1;
  static const double d5 = 0.2;
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class ApmrFfpIrMilReticleDrawer implements SVGDrawerInterface {
  ApmrFfpIrMilReticleDrawer();

  @override
  void draw(MilReticleSVGCanvas canvas) {
    // const A = ApmrFfpIrMilSizes.A;
    const a1 = ApmrFfpIrMilSizes.a1;
    const a2 = ApmrFfpIrMilSizes.a2;
    const a3 = ApmrFfpIrMilSizes.a3;
    const a4 = ApmrFfpIrMilSizes.a4;
    const b1 = ApmrFfpIrMilSizes.b1;
    const b2 = ApmrFfpIrMilSizes.b2;
    const b3 = ApmrFfpIrMilSizes.b3;
    const c1 = ApmrFfpIrMilSizes.c1;
    const d1 = ApmrFfpIrMilSizes.d1;
    const d2 = ApmrFfpIrMilSizes.d2;
    const d3 = ApmrFfpIrMilSizes.d3;
    const d4 = ApmrFfpIrMilSizes.d4;
    const d5 = ApmrFfpIrMilSizes.d5;

    const L = 9 * d2;
    const H = 0.4;

    const String bgColor = 'transparent';
    const String color = "onSurface";
    const String accentColor = "red";

    canvas.clip(
      shape: (c) => c.circle(0, 0, 2 * L, fill: bgColor),
      draw: (c) {
        c.fill(bgColor);
        c.hLine(0, -L, L, accentColor, a1);
        c.vLine(0, -L, L, accentColor, a1);
        c.vRuler(-L, L, d2, b2, accentColor, a1);
        c.vRuler(-L, 7 * d2, d1, b1, accentColor, a1, x: b1 / 2);
        c.vRuler(L - 2 * d2, L, d3, b3, accentColor, a1);
        c.hRuler(-L, L, d2, b2, accentColor, a1);
        c.hRuler(-7 * d2, 7 * d2, d1, b1, accentColor, a1, y: -b1 / 2);
        c.hRuler(L - 2 * d2, L, d3, b3, accentColor, a1);
        c.hRuler(-L, -(L - 2 * d2), d3, b3, accentColor, a1);
        for (double i = 2; i <= L; i += 2) {
          c.label(i.abs().toStringAsFixed(0), i, 0.75, accentColor, h: H);
          c.label(i.abs().toStringAsFixed(0), -i, 0.75, accentColor, h: H);
          c.label(i.abs().toStringAsFixed(0), 1, -i, accentColor, h: H);
        }
        c.label(4.toStringAsFixed(0), -2.5, 4 * d4, accentColor, h: H);
        c.label(6.toStringAsFixed(0), -3.5, 6 * d4, accentColor, h: H);
        c.label(8.toStringAsFixed(0), -4.5, 8 * d4, accentColor, h: H);
        // a4 dots
        c.hDotLine(1, -1, -1, d4, a4 / 2, accentColor);
        c.hDotLine(1, 1, 1, d4, a4 / 2, accentColor);
        c.hDotLine(2, -1, -1, d4, a4 / 2, accentColor);
        c.hDotLine(2, 1, 1, d4, a4 / 2, accentColor);
        c.hDotLine(3, -1, -1, d4, a4 / 2, accentColor);
        c.hDotLine(3, 1, 1, d4, a4 / 2, accentColor);
        c.hDotLine(4, -1, -2, d4, a4 / 2, accentColor);
        c.hDotLine(4, 1, 2, d4, a4 / 2, accentColor);
        c.hDotLine(5, -2, -1, d4, a4 / 2, accentColor);
        c.hDotLine(5, 1, 2, d4, a4 / 2, accentColor);
        c.hDotLine(6, -3, -1, d4, a4 / 2, accentColor);
        c.hDotLine(6, 1, 3, d4, a4 / 2, accentColor);
        c.hDotLine(7, -3, -1, d4, a4 / 2, accentColor);
        c.hDotLine(7, 1, 3, d4, a4 / 2, accentColor);
        c.hDotLine(8, -4, -1, d4, a4 / 2, accentColor);
        c.hDotLine(8, 1, 4, d4, a4 / 2, accentColor);
        c.hDotLine(9, -4, -1, d4, a4 / 2, accentColor);
        c.hDotLine(9, 1, 4, d4, a4 / 2, accentColor);
        // a3 dots
        c.hDotLine(1, -1, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(1, 0.4, 1, d5, a3 / 2, accentColor);
        c.hDotLine(2, -1, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(2, 0.4, 1, d5, a3 / 2, accentColor);
        c.hDotLine(3, -1, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(3, 0.4, 1, d5, a3 / 2, accentColor);
        c.hDotLine(4, -2, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(4, 0.4, 2, d5, a3 / 2, accentColor);
        c.hDotLine(5, -2, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(5, 0.4, 2, d5, a3 / 2, accentColor);
        c.hDotLine(6, -3, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(6, 0.4, 3, d5, a3 / 2, accentColor);
        c.hDotLine(7, -3, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(7, 0.4, 3, d5, a3 / 2, accentColor);
        c.hDotLine(8, -4, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(8, 0.4, 4, d5, a3 / 2, accentColor);
        c.hDotLine(9, -4, -0.4, d5, a3 / 2, accentColor);
        c.hDotLine(9, 0.4, 4, d5, a3 / 2, accentColor);

        PathBuilder pb;

        pb = PathBuilder();
        pb
          ..moveTo(-L - c1, 0)
          ..lineTo(-L - c1 - d2, -a2 / 2)
          ..lineTo(-15, -a2 / 2)
          ..lineTo(-15, a2 / 2)
          ..lineTo(-L - c1 - d2, a2 / 2)
          ..close();
        c.path(pb.d, fill: color);

        pb = PathBuilder();
        pb
          ..moveTo(L + c1, 0)
          ..lineTo(L + c1 + d2, -a2 / 2)
          ..lineTo(15, -a2 / 2)
          ..lineTo(15, a2 / 2)
          ..lineTo(L + c1 + d2, a2 / 2)
          ..close();
        c.path(pb.d, fill: color);

        pb = PathBuilder();
        pb
          ..moveTo(0, -(L + c1))
          ..lineTo(-a2 / 2, -(L + c1 + d2))
          ..lineTo(-a2 / 2, -15)
          ..lineTo(a2 / 2, -15)
          ..lineTo(a2 / 2, -(L + c1 + d2))
          ..close();
        c.path(pb.d, fill: color);

        pb = PathBuilder();
        pb
          ..moveTo(0, L + c1)
          ..lineTo(-a2 / 2, L + c1 + d2)
          ..lineTo(-a2 / 2, 15)
          ..lineTo(a2 / 2, 15)
          ..lineTo(a2 / 2, L + c1 + d2)
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
