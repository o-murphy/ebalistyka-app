import 'package:reticle_gen/reticle_gen.dart';

const double reticleSizeMil = 20;
const double targetSize = 0.5;
const double targetHeightMil = targetSize;
const double targetWidthMil = targetSize;

class TargetPointDrawer implements SVGDrawerInterface {
  @override
  void draw(MilReticleSVGCanvas canvas) {
    const String color = '#FF8C00';
    canvas.dot(0, 0, targetSize / 2, color);
  }
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args.first : 'default.svg';
  MilReticleSVGCanvas(
      milHeight: reticleSizeMil,
      milWidth: reticleSizeMil,
      targetMilSize: targetSize,
    )
    ..generate(TargetPointDrawer())
    ..svg.export(outputPath);
}
