import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

// ─── Геометричні константи (спільні для всіх варіантів) ───────────────────────
class MilCf1Sizes {
  static const double C = 0.04;
  static const double D = 0.4;
  static const double E = 0.2;
  static const double F = 1;
  static const double G = 0.05;
  static const double H = 0.35;
  static const double I = 0.2;
  static const double J = 0.6;
  static const double K = 0.2;
  static const double L = 0.1;
  static const double M = 0.03;
  static const double N = 2;
}

// ─── Варіант сітки (subtension chart) ────────────────────────────────────────

/// Параметри subtension для конкретної моделі прицілу.
/// [a]  — горизонтальна лінійка (мілів)
/// [b]  — товщина ліній (мілів)
class MilCf1Variant {
  final String name;
  final double a;
  final double b;

  const MilCf1Variant({required this.name, required this.a, required this.b});

  /// Ідентифікатор для імені файлу: «ATACR 7-35» → «atacr_7-35»
  String get fileId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '-');

  // ── Предефайнені варіанти ─────────────────────────────────────────────────

  // defaultVariant — окремий const, бо використовується як default-значення параметра
  static const defaultVariant = MilCf1Variant(name: 'NX8 20x', a: 20, b: 0.041);

  static const all = [
    defaultVariant,
    MilCf1Variant(name: 'NX8 32x', a: 20, b: 0.036),
    MilCf1Variant(name: 'ATACR 16x', a: 20, b: 0.04),
    MilCf1Variant(name: 'ATACR 20x', a: 10, b: 0.04),
    MilCf1Variant(name: 'ATACR 25x', a: 20, b: 0.033),
    MilCf1Variant(name: 'ATACR 35x', a: 10, b: 0.033),
  ];

  /// Знаходить варіант за назвою (регістр не важливий).
  /// Повертає [defaultVariant] якщо не знайдено.
  static MilCf1Variant byName(String name) {
    final lower = name.toLowerCase();
    return all.firstWhere(
      (v) => v.name.toLowerCase() == lower || v.fileId == lower,
      orElse: () => defaultVariant,
    );
  }
}

// ─── Drawer ───────────────────────────────────────────────────────────────────

class MilCf1ReticleDrawer implements SVGDrawerInterface {
  final MilCf1Variant variant;

  MilCf1ReticleDrawer({this.variant = MilCf1Variant.defaultVariant});

  @override
  void draw(SVGCanvas canvas) {
    final A = variant.a;
    final B = variant.b;
    const C = MilCf1Sizes.C;
    const D = MilCf1Sizes.D;
    const E = MilCf1Sizes.E;
    final F = MilCf1Sizes.F;
    const G = MilCf1Sizes.G;
    const H = MilCf1Sizes.H;
    const I = MilCf1Sizes.I;
    const J = MilCf1Sizes.J;
    final K = MilCf1Sizes.K;
    const L = MilCf1Sizes.L;
    const M = MilCf1Sizes.M;
    const N = MilCf1Sizes.N;

    const String bgColor = "white";
    const String color = "black"; //"onSurface";
    const String clipColor = "white"; //"surface";
    const String accentColor = "red";

    canvas.clip(
      shape: (c) => c.circle(0, 0, 30, 'white'),
      draw: (c) {
        c.fill(bgColor);

        c
          ..dot(0, 0, G / 2, accentColor)
          ..hLine(0, A / 2, 0.1, accentColor, B)
          ..hLine(0, -A / 2, -0.1, accentColor, B)
          ..vLine(0, -5, -0.1, accentColor, B)
          ..vLine(0, 30, 0.1, accentColor, B)
          ..hRuler(A / 2, 1, -F, J, accentColor, B)
          ..hRuler(-A / 2, -1, F, J, accentColor, B)
          ..vRuler(-5, -1, F, J, accentColor, B)
          ..vRuler(30, 1, -F, J, accentColor, B);

        c
          ..hRuler(1 + E, A / 2, F, K, accentColor, B, y: K / 2)
          ..hRuler(-(1 + E), -A / 2, -F, K, accentColor, B, y: K / 2)
          ..hRuler(2 * E, A / 2, F, K, accentColor, B, y: -K / 2)
          ..hRuler(-2 * E, -A / 2, -F, K, accentColor, B, y: -K / 2)
          ..hRuler(3 * E, A / 2, F, K, accentColor, B, y: -K / 2)
          ..hRuler(-3 * E, -A / 2, -F, K, accentColor, B, y: -K / 2)
          ..hRuler(4 * E, A / 2, F, K, accentColor, B, y: K / 2)
          ..hRuler(-4 * E, -A / 2, -F, K, accentColor, B, y: K / 2)
          ..vLine(E, 0, L, accentColor, B)
          ..vLine(-E, 0, L, accentColor, B)
          ..vRuler(-(1 + E), -5, -F, K, accentColor, B, x: -K / 2)
          ..vRuler(-2 * E, -5, -F, K, accentColor, B, x: K / 2)
          ..vRuler(-3 * E, -5, -F, K, accentColor, B, x: K / 2)
          ..vRuler(-4 * E, -5, -F, K, accentColor, B, x: -K / 2)
          ..vRuler(1 + E, 30, F, K, accentColor, B, x: -K / 2)
          ..vRuler(2 * E, 30, F, K, accentColor, B, x: K / 2)
          ..vRuler(3 * E, 30, F, K, accentColor, B, x: K / 2)
          ..vRuler(4 * E, 30, F, K, accentColor, B, x: -K / 2)
          ..hLine(E, -K / 2, K / 2, accentColor, B)
          ..hLine(-E, -K / 2, K / 2, accentColor, B);

        for (double i = -A / 2; i <= A / 2; i += F) {
          if (i == 0) continue;
          c.text(i.abs().toStringAsFixed(0), i, -1 + H, color, fontSize: H);
        }

        for (double i = 1; i <= 30; i += F) {
          c.text(
            i.abs().toStringAsFixed(0),
            -0.5,
            i + H * 0.35,
            color,
            fontSize: H,
            textAnchor: "middle",
          );
        }

        c
          ..vLine(3.1, 1, 3.3, color, B)
          ..hLine(3, 3.1 - 1, 3.1 + 1, color, B)
          ..vRuler(1, 2, F, J, color, M, x: 3.1)
          ..vRuler(1, 3, 0.2, 0.1, color, M, x: 3.1 + 0.05)
          ..vRuler(1 + 0.1, 3 - 0.1, 0.2, 0.1, color, M, x: 3.1 - 0.05)
          ..hRuler(3.1 - N / 2, 3.1 + N / 2, 2 * F, J, color, M, y: 3)
          ..hRuler(
            3.1 + 0.1 - N / 2,
            3.1 - 0.1 + N / 2,
            0.2,
            0.1,
            color,
            M,
            y: 3 + 0.05,
          )
          ..hRuler(
            3.1 + 0.2 - N / 2,
            3.1 - 0.2 + N / 2,
            0.2,
            0.1,
            color,
            M,
            y: 3 - 0.05,
          );

        for (double i = -N / 2; i <= N / 2; i += F) {
          c.text(
            i.abs().toStringAsFixed(0),
            3.1 + i,
            3 + 0.5 + H,
            color,
            fontSize: H,
            textAnchor: "middle",
          );
        }

        for (double i = 1; i <= 2; i += F) {
          c.text(
            i.abs().toStringAsFixed(0),
            3.1 + 0.5,
            i + H * 0.35,
            color,
            fontSize: H,
            textAnchor: "middle",
          );
        }

        c
          ..hRuler(A / 2 + 5, A / 2 + I, -F, J, color, C)
          ..hRuler(-(A / 2 + 5), -(A / 2 + I), F, J, color, C)
          ..rect(A / 2 + 1, -D / 2, 4 - M, D, clipColor)
          ..rect(-(A / 2 + 1 + 4 - M), -D / 2, 4, D, clipColor)
          ..hLine(0, 30, A / 2 + I, color, C)
          ..hLine(0, -30, -(A / 2 + I), color, C)
          ..hLine(D / 2, 30, A / 2 + 1, color, C)
          ..hLine(-D / 2, 30, A / 2 + 1, color, C)
          ..hLine(D / 2, -30, -(A / 2 + 1), color, C)
          ..hLine(-D / 2, -30, -(A / 2 + 1), color, C)
          ..line(A / 2 + I, 0, A / 2 + 1, D / 2, color, C)
          ..line(A / 2 + I, 0, A / 2 + 1, -D / 2, color, C)
          ..line(-(A / 2 + I), 0, -(A / 2 + 1), D / 2, color, C)
          ..line(-(A / 2 + I), 0, -(A / 2 + 1), -D / 2, color, C);
      },
    );
  }
}

void main(List<String> args) {
  // Usage: dart mil_xt.dart [variant] [output.svg]
  //   variant — назва або fileId (напр. "ATACR 7-35" або "atacr_7-35")
  //             якщо не вказано або не знайдено — використовується defaultVariant
  //   output  — шлях до файлу; якщо не вказано — "<fileId>.svg"
  final variant = args.isNotEmpty
      ? MilCf1Variant.byName(args[0])
      : MilCf1Variant.defaultVariant;
  final outputPath = args.length >= 2 ? args[1] : '${variant.fileId}.svg';

  print('Generating "${variant.name}"  →  $outputPath');
  print('  A=${variant.a}  B=${variant.b}');

  MilReticleSVGCanvas(milWidth: 60, milHeight: 60)
    ..generate(MilCf1ReticleDrawer(variant: variant))
    ..svg.export(outputPath);
}
