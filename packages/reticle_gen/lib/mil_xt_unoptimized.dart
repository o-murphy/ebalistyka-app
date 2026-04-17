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

  static const atacr735 = MilXtVariant(
    name: 'ATACR 7-35',
    a: 0.033,
    f: 0.40,
    k: 0.20,
  );
  static const atacr525 = MilXtVariant(
    name: 'ATACR 5-25',
    a: 0.030,
    f: 0.40,
    k: 0.20,
  );
  static const atacr420 = MilXtVariant(
    name: 'ATACR 4-20',
    a: 0.040,
    f: 0.50,
    k: 0.25,
  );
  static const atacr416 = MilXtVariant(
    name: 'ATACR 4-16',
    a: 0.040,
    f: 0.60,
    k: 0.30,
  );
  static const nx8432 = MilXtVariant(
    name: 'NX8 4-32',
    a: 0.036,
    f: 0.44,
    k: 0.22,
  );
  static const nx8_2520 = MilXtVariant(
    name: 'NX8 2.5-20',
    a: 0.041,
    f: 0.50,
    k: 0.25,
  );
  static const shv414 = MilXtVariant(
    name: 'SHV 4-14',
    a: 0.044,
    f: 0.40,
    k: 0.20,
  );

  static const all = [
    atacr735,
    atacr525,
    atacr420,
    atacr416,
    nx8432,
    nx8_2520,
    shv414,
  ];

  static const defaultVariant = atacr735;

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

    const String color = "onSurface";
    const String accentColor = "red";
    const double halfI = I / 2;
    const double labelOffset = 0.4; // відступ від краю риски

    canvas
      ..clip(
        shape: (c) => c.circle(0, 0, 24, 'white'),
        draw: (c) {
          c
            // ..fill("white")
            // 1. Основні осі
            ..line(0.1, 0, 10, 0, accentColor, A) // Горизонтальна
            ..line(-0.1, 0, -10, 0, accentColor, A) // Горизонтальна
            ..line(0, -0.1, 0, -5, accentColor, A); // Вертикальна

          final double minI = I - 0.2;
          final double minHalfI = halfI - 0.1;
          c
            ..line(-15, 0, -10.2, 0, color, A)
            ..line(15, 0, 10.2, 0, color, A)
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

          for (double i = 15; i > 10; i -= E) {
            c.line(i, -halfI, i, halfI, color, A);
            c.line(-i, -halfI, -i, halfI, color, A);
          }

          // 2а. Риски на ГОРИЗОНТАЛЬНІЙ осі (-10..10)
          for (double i = 10; i > 0; i -= E) {
            c.line(i - 4 * D, 0, i - 4 * D, i > 1 ? H : C, accentColor, A);

            c
              ..line(i, -halfI, i, halfI, accentColor, A)
              ..line(i - D, 0, i - D, H, accentColor, A)
              ..line(i - 2 * D, 0, i - 2 * D, -H, accentColor, A)
              ..line(i - 3 * D, 0, i - 3 * D, -H, accentColor, A)
              ..text(
                i.abs().toStringAsFixed(0),
                i,
                -(halfI + labelOffset + F / 2),
                color,
                fontSize: K,
                textAnchor: 'middle',
              );
          }

          for (double i = -10; i < 0; i += E) {
            c.line(i + 4 * D, 0, i + 4 * D, i < -1 ? H : C, accentColor, A);

            c
              ..line(i, -halfI, i, halfI, accentColor, A)
              ..line(i + D, 0, i + D, H, accentColor, A)
              ..line(i + 2 * D, 0, i + 2 * D, -H, accentColor, A)
              ..line(i + 3 * D, 0, i + 3 * D, -H, accentColor, A)
              ..text(
                i.abs().toStringAsFixed(0),
                i,
                -(halfI + labelOffset + F / 2),
                color,
                fontSize: K,
                textAnchor: 'middle',
              );
          }

          // 2б. Риски на ВЕРТИКАЛЬНІЙ осі (-10..14)

          for (double i = 0; i <= 24; i += E) {
            c
              ..circle(0, i, B / 2, accentColor)
              ..line(-0.1, i, -J, i, accentColor, A)
              ..line(0.1, i, J, i, accentColor, A)
              ..line(0, i + C, 0, i + 1 - C, accentColor, A);

            if (i > 0) {
              c.line(0, i + D, -H, i + D, accentColor, A);
            } else {
              c.line(C, i + D, -C, i + D, accentColor, A);
            }

            c
              ..line(0, i + 4 * D, -H, i + 4 * D, accentColor, A)
              ..line(0, i + 2 * D, H, i + 2 * D, accentColor, A)
              ..line(0, i + 3 * D, H, i + 3 * D, accentColor, A);
          }

          for (double i = -5; i <= -1; i += E) {
            if (i != 0) {
              c.line(-halfI, i, halfI, i, accentColor, A);
            }

            if (i < -1) {
              c.line(0, i + 4 * D, -H, i + 4 * D, accentColor, A);
            } else {
              c.line(C, i + 4 * D, -C, i + 4 * D, accentColor, A);
            }

            c
              ..line(0, i + D, -H, i + D, accentColor, A)
              ..line(0, i + 2 * D, H, i + 2 * D, accentColor, A)
              ..line(0, i + 3 * D, H, i + 3 * D, accentColor, A);
          }

          for (double i = -5; i <= -2; i += E) {
            if (i == 0) continue;
            c.text(
              i.abs().toStringAsFixed(0),
              -(halfI + labelOffset),
              i + F * 0.35, // компенсація baseline
              color,
              fontSize: K,
              textAnchor: 'end',
            );
          }

          for (double j = G; j <= 4 + G; j++) {
            for (double i = -(2 + G); i <= 2 + G; i += E) {
              c.circle(i, j, L / 2, color);
            }
          }

          for (double j = 5 + G; j <= 8 + G; j++) {
            for (double i = -(3 + G); i <= 3 + G; i += E) {
              c.circle(i, j, L / 2, color);
            }
          }

          for (double j = 9 + G; j <= 24 + G; j++) {
            for (double i = -(4 + G); i <= (4 + G); i += E) {
              c.circle(i, j, L / 2, color);
            }
          }

          for (double j = 1; j <= 4; j++) {
            final double fontSize = (j % 2 == 0 ? F : K);
            final double offset = 3 + labelOffset;
            c
              ..text(
                j.toStringAsFixed(0),
                offset,
                j + fontSize * 0.35,
                color,
                fontSize: fontSize,
              )
              ..text(
                j.toStringAsFixed(0),
                -offset,
                j + fontSize * 0.35,
                color,
                fontSize: fontSize,
              );

            for (double i = -3; i <= 3; i += E) {
              if (i == 0) continue;

              c.circle(i, j, M / 2, color);
            }
            for (double i = -3; i <= 3; i += D) {
              if (i >= -D - epsilon && i <= D + epsilon) continue;

              c.circle(i, j, N / 2, color);
            }
          }

          for (double j = 5; j <= 8; j++) {
            final double fontSize = (j % 2 == 0 ? F : K);
            final double offset = 4 + labelOffset;
            c
              ..text(
                j.toStringAsFixed(0),
                offset,
                j + fontSize * 0.35,
                color,
                fontSize: fontSize,
              )
              ..text(
                j.toStringAsFixed(0),
                -offset,
                j + fontSize * 0.35,
                color,
                fontSize: fontSize,
              );

            for (double i = -4; i <= 4; i += E) {
              if (i == 0) continue;

              c.circle(i, j, M / 2, color);
            }
            for (double i = -4; i <= 4; i += D) {
              if (i >= -D - epsilon && i <= D + epsilon) continue;

              c.circle(i, j, N / 2, color);
            }
          }

          for (double j = 9; j <= 24; j++) {
            final double fontSize = (j % 2 == 0 ? F : K);
            final double offset = 5 + labelOffset;
            c
              ..text(
                j.toStringAsFixed(0),
                offset,
                j + fontSize * 0.35,
                color,
                fontSize: fontSize,
              )
              ..text(
                j.toStringAsFixed(0),
                -offset,
                j + fontSize * 0.35,
                color,
                fontSize: fontSize,
              );

            for (double i = -5; i <= 5; i += E) {
              if (i == 0) continue;

              c.circle(i, j, M / 2, color);
            }
            for (double i = -5; i <= 5; i += D) {
              if (i >= -D - epsilon && i <= D + epsilon) continue;

              c.circle(i, j, N / 2, color);
            }
          }
        },
      )
      // Обідок кола поверх обрізаного вмісту
      ..circle(0, 0, 24, "transparent", stroke: color, strokeWidth: A);
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
