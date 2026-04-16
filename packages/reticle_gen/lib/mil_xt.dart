import 'package:reticle_gen/mil_reticle.dart';
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

class MilXtReticleDrawer extends MilReticleDrawer {
  final MilXtVariant variant;

  MilXtReticleDrawer({this.variant = MilXtVariant.defaultVariant});

  @override
  void draw(CanvasInterface canvas) {
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
    const double labelOffset = 0.4;

    canvas
      ..clip(
        shape: (c) => c.circle(0, 0, 24, 'white'),
        draw: (c) {
          // ── Риска горизонтальної осі для позиції x (±) ──────────────────
          // s > 0 → риска справа від центру, s < 0 → зліва
          void hTick(double x) {
            final s = x.sign;
            final abs = x.abs();
            c
              ..line(
                x - s * 4 * D,
                0,
                x - s * 4 * D,
                abs > 1 ? H : C,
                accentColor,
                A,
              )
              ..line(x, -halfI, x, halfI, accentColor, A)
              ..line(x - s * D, 0, x - s * D, H, accentColor, A)
              ..line(x - s * 2 * D, 0, x - s * 2 * D, -H, accentColor, A)
              ..line(x - s * 3 * D, 0, x - s * 3 * D, -H, accentColor, A)
              ..text(
                abs.toStringAsFixed(0),
                x,
                -(halfI + labelOffset + F / 2),
                color,
                fontSize: K,
                textAnchor: 'middle',
              );
          }

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
              );
            for (double i = -dotRange; i <= dotRange; i += E) {
              if (i == 0) continue;
              c.circle(i, j, M / 2, color);
            }
            for (double i = -dotRange; i <= dotRange; i += D) {
              if (i >= -D - epsilon && i <= D + epsilon) continue;
              c.circle(i, j, N / 2, color);
            }
          }

          c
            // ..fill("white")
            // 1. Основні осі
            ..line(0.1, 0, 10, 0, accentColor, A)
            ..line(-0.1, 0, -10, 0, accentColor, A)
            ..line(0, -0.1, 0, -5, accentColor, A);

          // Горизонтальне продовження осі + рамки
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

          // Додаткові риски 11..15 (за рамками)
          for (double i = 11; i <= 15; i += E) {
            c
              ..line(i, -halfI, i, halfI, color, A)
              ..line(-i, -halfI, -i, halfI, color, A);
          }

          // 2а. Риски на горизонтальній осі (±1..10) — дзеркально через hTick
          for (double i = 1; i <= 10; i += E) {
            hTick(i);
            hTick(-i);
          }

          // 2б. Риски на вертикальній осі (0..24) — позитивна частина + центр
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

          // 2в. Риски на вертикальній осі (-5..-1) — негативна частина
          for (double i = -5; i <= -1; i += E) {
            c
              ..line(-halfI, i, halfI, i, accentColor, A)
              ..line(0, i + D, -H, i + D, accentColor, A)
              ..line(0, i + 2 * D, H, i + 2 * D, accentColor, A)
              ..line(0, i + 3 * D, H, i + 3 * D, accentColor, A);

            if (i < -1) {
              c.line(0, i + 4 * D, -H, i + 4 * D, accentColor, A);
            } else {
              c.line(C, i + 4 * D, -C, i + 4 * D, accentColor, A);
            }

            if (i <= -2) {
              c.text(
                i.abs().toStringAsFixed(0),
                -(halfI + labelOffset),
                i + F * 0.35,
                color,
                fontSize: K,
                textAnchor: 'end',
              );
            }
          }

          // 3. Точкова сітка між рисками
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
            for (double i = -(4 + G); i <= 4 + G; i += E) {
              c.circle(i, j, L / 2, color);
            }
          }

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

  MilReticleCanvas(milWidth: 48, milHeight: 48)
    ..generate(MilXtReticleDrawer(variant: variant))
    ..svg.export(outputPath);
}
