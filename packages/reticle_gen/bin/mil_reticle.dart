import 'package:reticle_gen/reticle_gen.dart';
import 'package:xml/xml.dart';

class MilReticleCanvas extends SVGCanvas {
  final int factor;

  MilReticleCanvas({
    double milWidth = 30.0,
    double milHeight = 30.0,
    this.factor = 100,
  }) : super(width: milWidth * factor, height: milHeight * factor);

  @override
  void line(
    double x1,
    double y1,
    double x2,
    double y2,
    String stroke,
    double strokeWidth,
  ) => super.line(
    x1 * factor,
    y1 * factor,
    x2 * factor,
    y2 * factor,
    stroke,
    strokeWidth * factor,
  );

  @override
  void rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) => super.rect(
    x * factor,
    y * factor,
    w * factor,
    h * factor,
    fill,
    stroke: stroke,
    strokeWidth: (strokeWidth ?? 0.0) * factor,
  );

  @override
  void circle(
    double cx,
    double cy,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) => super.circle(
    cx * factor,
    cy * factor,
    r * factor,
    fill,
    stroke: stroke,
    strokeWidth: (strokeWidth ?? 0.0) * factor,
  );

  @override
  void path(String d, String fill, {String? stroke, double? strokeWidth}) {
    // Створюємо групу <g> навколо шляху, щоб застосувати масштаб
    final scaledPath = XmlElement(XmlName('path'), [
      XmlAttribute(XmlName('d'), d),
      XmlAttribute(XmlName('fill'), fill),
      if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
      if (strokeWidth != null)
        XmlAttribute(
          XmlName('stroke-width'),
          (strokeWidth * factor).toString(),
        ),
      // Масштабуємо координати самого шляху
      XmlAttribute(XmlName('transform'), 'scale($factor)'),
    ]);

    svg.children.add(scaledPath);
  }

  void drawAdjustment(double x, double y) {
    this
      ..line(x, 0, x, y, "red", 0.05)
      ..line(0, y, x, y, "red", 0.05)
      ..circle(x, y, 0.2, "red");
  }
}

class MilReticleDrawer implements DrawerInterface {
  @override
  void draw(CanvasInterface canvas) {
    const String color = "black";
    const double thickness = 0.05; // Товщина ліній
    const double tickHalfLength =
        0.5; // Половина довжини риски (щоб загальна була 1 міл)

    canvas
      // Малюємо фон
      ..fill("white")
      // 1. Основні осі (від -10 до 10 мілів)
      ..line(-10, 0, 10, 0, color, thickness) // Горизонтальна
      ..line(0, -10, 0, 10, color, thickness); // Вертикальна

    // 2. Малюємо риски кожний 1 MIL
    for (int i = -10; i <= 10; i++) {
      // Пропускаємо центр (0), бо там основні осі
      if (i == 0) continue;

      double pos = i.toDouble();

      canvas
        // Риски на ГОРИЗОНТАЛЬНІЙ осі (вертикальні палички)
        // Малюємо від -0.5 до 0.5 по осі Y на позиції X = i
        ..line(pos, -tickHalfLength, pos, tickHalfLength, color, thickness)
        // Риски на ВЕРТИКАЛЬНІЙ осі (горизонтальні палички)
        // Малюємо від -0.5 до 0.5 по осі X на позиції Y = i
        ..line(-tickHalfLength, pos, tickHalfLength, pos, color, thickness);
    }
  }
}

void main() {
  final drawer = MilReticleDrawer();
  MilReticleCanvas()
    ..generate(drawer) // Намалювали сітку
    ..drawAdjustment(0.53, 4.6) // Додали червону точку
    ..svg.export('final.svg');
}
