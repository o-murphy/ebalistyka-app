import 'package:reticle_gen/reticle_gen.dart';
import 'package:xml/xml.dart';

/// Correction from em-square to cap-height for typical sans-serif fonts.
/// Lets callers specify [fontSize] as the visible height of capital letters
/// rather than the SVG em-square unit.
const double _capHeightRatio = 0.72;

/// A canvas whose coordinate system is in mils.
///
/// The SVG [viewBox] spans [−milWidth/2 .. milWidth/2] × [−milHeight/2 ..
/// milHeight/2] in mil units, while the physical [width]/[height] attributes
/// are in pixels ([milWidth] × [factor] and [milHeight] × [factor]).
/// The SVG renderer handles all scaling — no per-element multiplication needed.
class MilReticleCanvas extends SVGCanvas {
  final int factor;
  final double milWidth;
  final double milHeight;

  MilReticleCanvas({
    this.milWidth = 30.0,
    this.milHeight = 30.0,
    this.factor = 100,
  }) : super(width: milWidth, height: milHeight);

  @override
  XmlElement generate(DrawerInterface drawer) {
    final el = super.generate(drawer);
    // super.generate() sets width/height to milWidth/milHeight (user-unit values).
    // Override them with the intended pixel dimensions.
    el.setAttribute('width', (milWidth * factor).toString());
    el.setAttribute('height', (milHeight * factor).toString());
    el.setAttribute('data-mil-width', milWidth.toString());
    el.setAttribute('data-mil-height', milHeight.toString());
    el.setAttribute('data-factor', factor.toString());
    el.setAttribute('shape-rendering', 'crispEdges');
    return el;
  }

  // Only text() needs an override: apply cap-height ratio so callers can
  // specify fontSize in "visible capital-letter height" mils rather than
  // em-square mils. Coordinates and all other drawing methods work in mils
  // natively via the viewBox — no factor multiplication required.
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
    x,
    y,
    fill,
    fontSize: fontSize / _capHeightRatio,
    textAnchor: textAnchor,
  );

  void drawAdjustment(double x, double y) {
    this
      ..line(x, 0, x, y, 'red', 0.05)
      ..line(0, y, x, y, 'red', 0.05)
      ..circle(x, y, 0.2, 'red');
  }
}

class MilReticleDrawer implements DrawerInterface {
  @override
  void draw(CanvasInterface canvas) {
    const String color = 'onSurface';
    const double thickness = 0.05;
    const double tickHalfLength = 0.5;
    const double fontSize = 0.45; // мілів
    const double labelOffset = 0.2;

    canvas
      ..clip(
        shape: (c) => c.circle(0, 0, 15, 'white'),
        draw: (c) {
          c
            ..line(-10, 0, 10, 0, color, thickness)
            ..line(0, -10, 0, 14, color, thickness);

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

          for (int i = -10; i <= 14; i++) {
            if (i == 0) continue;
            final double pos = i.toDouble();
            final bool showLabel = i.abs() % 2 == 0;

            c.line(-tickHalfLength, pos, tickHalfLength, pos, color, thickness);
            if (showLabel) {
              c.text(
                i.abs().toStringAsFixed(0),
                -(tickHalfLength + labelOffset),
                pos + fontSize * 0.35,
                color,
                fontSize: fontSize,
                textAnchor: 'end',
              );
            }
          }
        },
      )
      ..circle(0, 0, 15, 'transparent', stroke: color, strokeWidth: thickness);
  }
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args.first : 'default.svg';
  MilReticleCanvas()
    ..generate(MilReticleDrawer())
    ..svg.export(outputPath);
}
