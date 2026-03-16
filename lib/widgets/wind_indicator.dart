import 'dart:math';
import 'package:flutter/material.dart';

class WindIndicator extends StatefulWidget {
  final double initialAngle;
  final Function(double, String) onAngleChanged;

  const WindIndicator({
    super.key,
    this.initialAngle = -pi / 2, // Починаємо з 12:00 (вгору)
    required this.onAngleChanged,
  });

  @override
  State<WindIndicator> createState() => _WindIndicatorState();
}

class _WindIndicatorState extends State<WindIndicator> {
  late double angle;

  @override
  void initState() {
    super.initState();
    angle = widget.initialAngle;
  }

  void _handleGesture(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Отримуємо "сирий" кут від дотику
    double rawAngle = atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );

    // 1. Переводимо в градуси для зручного округлення
    // Додаємо 90, щоб 0 був на 12 годині
    double degrees = (rawAngle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;

    // 2. ОКРУГЛЕННЯ: приводимо до найближчого цілого градуса
    double snappedDegrees = degrees.roundToDouble();

    // 3. Конвертуємо назад у радіани для коректного відображення стрілки
    // Віднімаємо 90, щоб повернути математичну орієнтацію Flutter
    double snappedAngle = (snappedDegrees - 90) * pi / 180;

    setState(() {
      angle = snappedAngle;
    });

    // Розрахунок годин для колбеку (тепер на основі snappedDegrees)
    int hour = ((snappedDegrees / 30).round() % 12);
    if (hour == 0) hour = 12;
    String clockFormat = "${hour.toString().padLeft(2, '0')}:00";

    widget.onAngleChanged(snappedDegrees, clockFormat);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanUpdate: (details) => _handleGesture(details.localPosition, size),
          onTapDown: (details) => _handleGesture(details.localPosition, size),
          child: CustomPaint(
            size: Size.infinite,
            painter: WindPainter(
              angle: angle,
              color: Theme.of(context).colorScheme.onSurface,
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}

class WindPainter extends CustomPainter {
  final double angle;
  final Color color;
  final Color primaryColor;

  WindPainter({
    required this.angle,
    required this.color,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.45;
    final innerRadius = radius * 0.8;

    final ringPaint = Paint()
      ..color = color
          .withValues(alpha: 0.1) // Було withOpacity
      ..style = PaintingStyle.fill;

    // 1. Малюємо зовнішнє кільце
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = color.withOpacity(0.05),
    );

    // 2. Малюємо мітки годин та цифри
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 12; i++) {
      double hourAngle = (i * 30 - 90) * pi / 180;

      // Рисочки
      final tickStart = Offset(
        center.dx + innerRadius * cos(hourAngle),
        center.dy + innerRadius * sin(hourAngle),
      );
      final tickEnd = Offset(
        center.dx + (innerRadius - 10) * cos(hourAngle),
        center.dy + (innerRadius - 10) * sin(hourAngle),
      );
      canvas.drawLine(
        tickStart,
        tickEnd,
        Paint()
          ..color = color.withOpacity(0.5)
          ..strokeWidth = 2,
      );

      // Цифри
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: color.withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      final textPos = Offset(
        center.dx + (innerRadius - 25) * cos(hourAngle) - textPainter.width / 2,
        center.dy +
            (innerRadius - 25) * sin(hourAngle) -
            textPainter.height / 2,
      );
      textPainter.paint(canvas, textPos);
    }

    // 3. Малюємо стрілку-трикутник (указує "звідки")
    final arrowPath = Path();
    double arrowSize = 15;

    // Координати вершин трикутника на зовнішньому колі
    Offset tip = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
    Offset base1 = Offset(
      center.dx + (radius + arrowSize) * cos(angle - 0.2),
      center.dy + (radius + arrowSize) * sin(angle - 0.2),
    );
    Offset base2 = Offset(
      center.dx + (radius + arrowSize) * cos(angle + 0.2),
      center.dy + (radius + arrowSize) * sin(angle + 0.2),
    );

    arrowPath.moveTo(tip.dx, tip.dy);
    arrowPath.lineTo(base1.dx, base1.dy);
    arrowPath.lineTo(base2.dx, base2.dy);
    arrowPath.close();

    canvas.drawPath(arrowPath, Paint()..color = Colors.white);

    // 4. Текст у центрі (Градуси)
    double degrees = (angle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;

    textPainter.text = TextSpan(
      text: '${degrees.toStringAsFixed(0)}°',
      style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) => true;
}
