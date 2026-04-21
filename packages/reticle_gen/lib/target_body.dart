import 'dart:math' as math;

import 'package:reticle_gen/reticle_gen.dart';

const double scale = 0.0102;
const double A = 500 * scale;
const double B = 230 * scale;
const double C = 135 * scale;
const double D = 135 * scale;
const double R = 50 * scale;
const double K = 20 * scale;
const double L = 0.01;
const double M = 0.2;

class TargetPointDrawer implements SVGDrawerInterface {
  void _path(MilReticleSVGCanvas c, String color) {
    c.batchLines("none", 0, fill: color, (pb) {
      pb
        ..moveTo(A / 2, A / 2)
        ..lineTo(-A / 2, A / 2)
        ..lineTo(-A / 2, -B / 2)
        ..lineTo(-B / 2, -A / 2 + C)
        ..lineTo(-B / 2, -A / 2)
        ..lineTo(B / 2, -A / 2)
        ..lineTo(B / 2, -A / 2 + C)
        ..lineTo(A / 2, -A / 2 + C)
        ..close();
    });
  }

  @override
  void draw(MilReticleSVGCanvas canvas) {
    const String color = 'green';
    const String lineColor = 'white';
    const String accentColor = 'orange';

    canvas.clip(
      shape: (c) => _path(c, "none"),
      draw: (c) {
        _path(c, color);

        c.dot(0, 0, K, accentColor);

        double co = R * math.cos(math.pi / 4);
        double si = R * math.sin(math.pi / 4);
        for (int i = 1; i <= 5; i++) {
          c
            ..circle(0, 0, R * i, stroke: lineColor, strokeWidth: L)
            ..label(
              (10 - i).toStringAsFixed(0),
              -(i + 0.5) * co,
              (i + 0.5) * si,
              lineColor,
              h: M,
            );
        }
      },
    );
  }
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args.first : 'default.svg';
  MilReticleSVGCanvas(milHeight: A, milWidth: A)
    ..generate(TargetPointDrawer())
    ..svg.export(outputPath);
}
