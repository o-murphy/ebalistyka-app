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

    // Розрахунок год:хв (360° = 720 хв)
    final totalMin = (snappedDegrees * 2).round();
    int hour = (totalMin ~/ 60) % 12;
    if (hour == 0) hour = 12;
    final minute = totalMin % 60;
    String clockFormat =
        "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

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
            painter: WindPainter(
              angle: angle,
              color: Theme.of(context).colorScheme.onSurface,
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
            child: const SizedBox.expand(),
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
    final radius = min(size.width, size.height) * 0.5;
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

      // Цифри тільки на 12, 3, 6, 9
      if (i % 3 != 0) continue;
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

    // 3. Маркер + стрілка
    const markerR = 16.0;
    const markerOver = 6.0; // виступ за radius
    final markerCenter = Offset(
      center.dx + (radius - markerR + markerOver) * cos(angle),
      center.dy + (radius - markerR + markerOver) * sin(angle),
    );

    // Вектори напрямку
    final fx = -cos(angle); // до центру
    final fy = -sin(angle);
    final rx = -sin(angle); // перпендикуляр
    final ry = cos(angle);

    // --- Стрілка (малюємо ПЕРШОЮ, кружечок перекриє основу) ---
    const stemW = 4.0;
    const headW = 11.0;
    const totalL = 45.0;
    const headL = 14.0;

    // Основа стрілки = центр кружечка
    final bx = markerCenter.dx;
    final by = markerCenter.dy;
    final mx = bx + fx * (totalL - headL);
    final my = by + fy * (totalL - headL);
    final tx = bx + fx * totalL;
    final ty = by + fy * totalL;

    final arrowPath = Path()
      ..moveTo(bx + rx * stemW, by + ry * stemW)
      ..lineTo(mx + rx * stemW, my + ry * stemW)
      ..lineTo(mx + rx * headW, my + ry * headW)
      ..lineTo(tx, ty)
      ..lineTo(mx - rx * headW, my - ry * headW)
      ..lineTo(mx - rx * stemW, my - ry * stemW)
      ..lineTo(bx - rx * stemW, by - ry * stemW)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill,
    );

    // --- Кружечок (поверх основи стрілки) ---
    // Тінь
    canvas.drawCircle(
      markerCenter,
      markerR + 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Заливка
    canvas.drawCircle(markerCenter, markerR, Paint()..color = primaryColor);

    // Fingerprint іконка
    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.fingerprint.codePoint),
        style: TextStyle(
          fontFamily: Icons.fingerprint.fontFamily,
          fontSize: markerR * 1.2,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconTp.paint(
      canvas,
      Offset(
        markerCenter.dx - iconTp.width / 2,
        markerCenter.dy - iconTp.height / 2,
      ),
    );

    // 4. Текст у центрі
    double degrees = (angle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;

    final totalMin = (degrees * 2).round();
    int hour = (totalMin ~/ 60) % 12;
    if (hour == 0) hour = 12;
    final minute = totalMin % 60;
    final clockStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    // Мітка "Wind direction"
    textPainter.text = TextSpan(
      text: 'Wind direction',
      style: TextStyle(color: color.withValues(alpha: 0.55), fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 - 28,
      ),
    );

    // Градуси (великий текст)
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

    // Годинний формат
    textPainter.text = TextSpan(
      text: clockStr,
      style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2 + 28,
      ),
    );
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) => true;
}
