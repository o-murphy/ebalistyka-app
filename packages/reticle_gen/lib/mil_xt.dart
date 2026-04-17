import 'package:reticle_gen/reticle_gen.dart';

const double epsilon = 1e-6;

// ─── Геометричні константи (спільні для всіх варіантів) ───────────────────────
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

// ─── Варіант сітки (subtension chart) ────────────────────────────────────────

/// Параметри subtension для конкретної моделі прицілу.
/// [a]  — товщина ліній (мілів)
/// [f]  — розмір великого шрифту (мілів)
/// [k]  — розмір малого шрифту (мілів)
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

  /// Ідентифікатор для імені файлу: «ATACR 7-35» → «atacr_7-35»
  String get fileId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '-');

  // ── Предефайнені варіанти ─────────────────────────────────────────────────

  // defaultVariant — окремий const, бо використовується як default-значення параметра
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

  /// Знаходить варіант за назвою (регістр не важливий).
  /// Повертає [defaultVariant] якщо не знайдено.
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
  void draw(SVGCanvas canvas) {
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

    const String bgColor = "white";
    const String color = "black"; //"onSurface";
    const String accentColor = "red";
    const double halfI = I / 2;
    const double labelOffset = 0.4;

    canvas.clip(
      shape: (c) => c.circle(0, 0, 24, 'white'),
      draw: (c) {
        c.fill(bgColor);

        // ── Лейбли + точкова сітка для одного рядка по j ────────────────
        void zoneRow(double j, double xOff, double dotRange) {
          final fontSize = j % 2 == 0 ? F : K;
          c
            ..text(
              j.toStringAsFixed(0),
              xOff,
              j + fontSize * 0.35,
              color,
              fontSize: fontSize,
            )
            ..text(
              j.toStringAsFixed(0),
              -xOff,
              j + fontSize * 0.35,
              color,
              fontSize: fontSize,
            )
            // Large dots every E, skip center (i==0):
            ..hDotLine(j, -dotRange, -E, E, M / 2, color)
            ..hDotLine(j, E, dotRange, E, M / 2, color)
            // Small dots every D, skip |i|≤D:
            ..hDotLine(j, -dotRange, -2 * D, D, N / 2, color)
            ..hDotLine(j, 2 * D, dotRange, D, N / 2, color);
        }

        c
          // ..fill("white")
          // 1. Основні осі
          ..hLine(0, 0.1, 10, accentColor, A)
          ..hLine(0, -0.1, -10, accentColor, A)
          ..vLine(0, -0.1, -5, accentColor, A);

        // Горизонтальне продовження осі + рамки
        final double minI = I - 0.2;
        final double minHalfI = halfI - 0.1;
        c
          ..hLine(0, -15, -10.2, color, A)
          ..hLine(0, 15, 10.2, color, A)
          ..line(11, -minHalfI, 10.2, 0, color, A)
          ..line(11, minHalfI, 10.2, 0, color, A)
          ..line(-11, -minHalfI, -10.2, 0, color, A)
          ..line(-11, minHalfI, -10.2, 0, color, A)
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

        // Додаткові риски 11..15 (за рамками)
        c
          ..hRuler(11, 15, E, I, color, A)
          ..hRuler(-11, -15, -E, I, color, A);

        // 2а. Риски на горизонтальній осі (±1..10)
        for (double i = -10; i <= 10; i += E) {
          if (i == 0) continue;
          c.text(
            i.abs().toStringAsFixed(0),
            i,
            -(halfI + labelOffset + F / 2),
            color,
            fontSize: K,
            textAnchor: 'middle',
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

        // 2б. Риски на вертикальній осі (0..24) — позитивна частина + центр
        // 2в. Риски на вертикальній осі (-5..-1) — негативна частина

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
          c.text(
            i.abs().toStringAsFixed(0),
            -(halfI + labelOffset),
            i + F * 0.35,
            color,
            fontSize: K,
            textAnchor: 'end',
          );
        }

        // 3. Точкова сітка між рисками
        c
          ..dotGrid(-(2 + G), G, 2 + G, 4 + G, E, E, L / 2, color)
          ..dotGrid(-(3 + G), 5 + G, 3 + G, 8 + G, E, E, L / 2, color)
          ..dotGrid(-(4 + G), 9 + G, 4 + G, 24 + G, E, E, L / 2, color);

        // 4. Лейбли + сітка точок по зонах (±дзеркально через zoneRow)
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
  //   variant — назва або fileId (напр. "ATACR 7-35" або "atacr_7-35")
  //             якщо не вказано або не знайдено — використовується defaultVariant
  //   output  — шлях до файлу; якщо не вказано — "<fileId>.svg"
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
