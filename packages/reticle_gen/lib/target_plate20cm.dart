import 'package:reticle_gen/reticle_gen.dart';

const double reticleSizeMil = 20;
const double targetSize = 2;
const double targetHeightMil = targetSize;
const double targetWidthMil = targetSize;

class TargetPlate20cmDrawer implements SVGDrawerInterface {
  @override
  void draw(MilReticleSVGCanvas canvas) {
    const String color = '#FF8C00';
    canvas
      ..dot(0, 0, 0.5 / 2, color)
      ..circle(0, 0, targetSize / 2, stroke: color, strokeWidth: 0.1);
  }
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args.first : 'default.svg';
  MilReticleSVGCanvas(milHeight: reticleSizeMil, milWidth: reticleSizeMil)
    ..generate(TargetPlate20cmDrawer())
    ..svg.export(outputPath);
}
