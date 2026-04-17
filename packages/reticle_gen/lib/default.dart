import 'package:reticle_gen/reticle_gen.dart';

class MilReticleDrawer implements SVGDrawerInterface {
  @override
  void draw(SVGCanvas canvas) {
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
            ..line(0, -10, 0, 14, color, thickness)
            ..hRuler(-10, -1, 1, 1, color, thickness)
            ..hRuler(10, 1, -1, 1, color, thickness)
            ..vRuler(-10, 1, 1, 1, color, thickness)
            ..vRuler(14, 1, -1, 1, color, thickness);

          for (int i = -10; i <= 10; i++) {
            if (i == 0) continue;
            final double pos = i.toDouble();
            final bool showLabel = i.abs() % 2 == 0;

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
  MilReticleSVGCanvas()
    ..generate(MilReticleDrawer())
    ..svg.export(outputPath);
}
