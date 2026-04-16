import 'package:reticle_gen/reticle_gen.dart';
import 'package:xml/xml.dart';

/// Відношення cap-height до em-square для типових sans-serif шрифтів.
/// Дозволяє задавати [fontSize] у реальних мілах (видима висота великих літер),
/// а не в одиницях em-квадрата SVG.
const double _capHeightRatio = 0.72;

class MilReticleCanvas extends SVGCanvas {
  final int factor;
  final double milWidth;
  final double milHeight;

  MilReticleCanvas({
    this.milWidth = 30.0,
    this.milHeight = 30.0,
    this.factor = 100,
  }) : super(width: milWidth * factor, height: milHeight * factor);

  @override
  XmlElement generate(DrawerInterface drawer) {
    final el = super.generate(drawer);
    el.setAttribute('data-mil-width', milWidth.toString());
    el.setAttribute('data-mil-height', milHeight.toString());
    el.setAttribute('data-factor', factor.toString());
    el.setAttribute('shape-rendering', 'crispEdges');
    return el;
  }

  @override
  void text(
    String content,
    double x,
    double y,
    String fill, {
    double fontSize = 12,
    String textAnchor = 'middle',
  }) => super.text(
    content,
    x * factor,
    y * factor,
    fill,
    fontSize: fontSize / _capHeightRatio * factor,
    textAnchor: textAnchor,
  );

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
    // SVG transform="scale(factor)" scales both coordinates AND stroke-width,
    // so coordinates and strokeWidth stay in mil units — no manual multiplication.
    target.children.add(XmlElement(XmlName('path'), [
      XmlAttribute(XmlName('d'), d),
      XmlAttribute(XmlName('fill'), fill),
      if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
      if (strokeWidth != null)
        XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      XmlAttribute(XmlName('transform'), 'scale($factor)'),
    ]));
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
    const String color = "onSurface";
    const double thickness = 0.05; // Товщина ліній
    const double tickHalfLength =
        0.5; // Половина довжини риски (щоб загальна була 1 міл)

    const double fontSize = 0.45; // мілів
    const double labelOffset = 0.2; // відступ від краю риски

    canvas
      ..clip(
        shape: (c) => c.circle(0, 0, 15, 'white'),
        draw: (c) {
          c
            // 1. Основні осі
            ..line(-10, 0, 10, 0, color, thickness) // Горизонтальна
            ..line(0, -10, 0, 14, color, thickness); // Вертикальна

          // 2а. Риски на ГОРИЗОНТАЛЬНІЙ осі (-10..10)
          for (int i = -10; i <= 10; i++) {
            if (i == 0) continue;
            final double pos = i.toDouble();
            final bool showLabel = i.abs() % 2 == 0;

            c.line(pos, -tickHalfLength, pos, tickHalfLength, color, thickness);
            if (showLabel) {
              c.text(
                i.abs().toStringAsFixed(0),
                pos,
                -(tickHalfLength + labelOffset + fontSize),
                color,
                fontSize: fontSize,
                textAnchor: 'middle',
              );
            }
          }

          // 2б. Риски на ВЕРТИКАЛЬНІЙ осі (-10..14)
          for (int i = -10; i <= 14; i++) {
            if (i == 0) continue;
            final double pos = i.toDouble();
            final bool showLabel = i.abs() % 2 == 0;

            c.line(-tickHalfLength, pos, tickHalfLength, pos, color, thickness);
            if (showLabel) {
              c.text(
                i.abs().toStringAsFixed(0),
                -(tickHalfLength + labelOffset),
                pos + fontSize * 0.35, // компенсація baseline
                color,
                fontSize: fontSize,
                textAnchor: 'end',
              );
            }
          }
        },
      )
      // Обідок кола поверх обрізаного вмісту
      ..circle(0, 0, 15, "transparent", stroke: color, strokeWidth: thickness);
  }
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args.first : 'default.svg';
  final drawer = MilReticleDrawer();
  MilReticleCanvas()
    ..generate(drawer)
    // ..drawAdjustment(0.53, 4.6)
    ..svg.export(outputPath);
}
