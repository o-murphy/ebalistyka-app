import 'dart:async';
import 'dart:math';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/helpers/debugHighLight.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:flutter/material.dart';

class WindIndicator extends StatefulWidget {
  final double initialAngle;
  final Function(double, String) onAngleChanged;

  /// Called when the user taps the center degree label. Receives current degrees (0-360).
  final void Function(double degrees)? onDirectionTap;

  const WindIndicator({
    super.key,
    this.initialAngle = -pi / 2,
    required this.onAngleChanged,
    this.onDirectionTap,
  });

  @override
  State<WindIndicator> createState() => _WindIndicatorState();
}

class _WindIndicatorState extends State<WindIndicator>
    with SingleTickerProviderStateMixin {
  late double angle;
  late AnimationController _snapController;
  double _snapStartAngle = 0;
  double _snapDelta = 0;

  @override
  void initState() {
    super.initState();
    angle = widget.initialAngle;
    _snapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 380),
        )..addListener(() {
          setState(() {
            angle =
                _snapStartAngle +
                _snapDelta *
                    Curves.easeOutCubic.transform(_snapController.value);
          });
        });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WindIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAngle != widget.initialAngle) {
      setState(() => angle = widget.initialAngle);
    }
  }

  // Animates to [targetAngle] along the shorter arc, then commits.
  void _snapToAngle(double targetAngle) {
    _snapController.stop();
    _snapStartAngle = angle;
    double delta = targetAngle - angle;
    // Normalize to shorter arc [-π, π]
    while (delta > pi) {
      delta -= 2 * pi;
    }
    while (delta < -pi) {
      delta += 2 * pi;
    }
    _snapDelta = delta;
    unawaited(
      _snapController.forward(from: 0).whenComplete(() {
        if (mounted) {
          setState(() => angle = targetAngle);
          _commit();
        }
      }),
    );
  }

  double _angleFromPosition(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rawAngle = atan2(
      localPosition.dy - center.dy,
      localPosition.dx - center.dx,
    );
    double degrees = (rawAngle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;
    return (degrees.roundToDouble() - 90) * pi / 180;
  }

  // Updates local visual state only — does NOT notify parent.
  void _updateAngle(Offset localPosition, Size size) {
    setState(() => angle = _angleFromPosition(localPosition, size));
  }

  void _reset() => _snapToAngle(-pi / 2);

  // Commits the current angle to the parent (called on gesture end / tap).
  void _commit() {
    double degrees = (angle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;
    degrees = degrees.roundToDouble();
    final totalMin = (degrees * 2).round();
    int hour = (totalMin ~/ 60) % 12;
    if (hour == 0) hour = 12;
    final minute = totalMin % 60;
    final clockFormat =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    widget.onAngleChanged(degrees, clockFormat);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return ht(
          Listener(
            onPointerDown: (event) {
              final center = Offset(size.width / 2, size.height / 2);
              final dist = (event.localPosition - center).distance;
              final innerR = min(size.width, size.height) * 0.5 * 0.8;
              if (dist < innerR * 0.4) {
                if (widget.onDirectionTap != null) {
                  double deg = (angle * 180 / pi + 90) % 360;
                  if (deg < 0) deg += 360;
                  widget.onDirectionTap!(deg.roundToDouble());
                }
              } else {
                _snapToAngle(_angleFromPosition(event.localPosition, size));
              }
            },
            child: GestureDetector(
              onDoubleTap: _reset,
              onPanStart: (details) {
                _snapController.stop();
                setState(
                  () => angle = _angleFromPosition(details.localPosition, size),
                );
              },
              onPanUpdate: (details) =>
                  _updateAngle(details.localPosition, size),
              onPanEnd: (_) => _commit(),
              child: CustomPaint(
                painter: WindPainter(
                  angle: angle,
                  color: cs.onSurface,
                  primaryColor: cs.primary,
                  markerFillColor: cs.primaryContainer,
                  markerIconColor: cs.onPrimaryContainer,
                  l10n: l10n,
                ),
                child: const SizedBox.expand(),
              ),
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
  final Color markerFillColor;
  final Color markerIconColor;
  final AppLocalizations l10n;

  WindPainter({
    required this.angle,
    required this.color,
    required this.primaryColor,
    required this.markerFillColor,
    required this.markerIconColor,
    required this.l10n,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.5;
    final innerRadius = radius * 0.8;

    final ringPaint = Paint()
      ..color = color.withAlpha(25)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = color.withAlpha(12),
    );

    for (int i = 1; i <= 12; i++) {
      double hourAngle = (i * 30 - 90) * pi / 180;

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
          ..color = color.withAlpha(127)
          ..strokeWidth = 2,
      );

      if (i % 3 != 0) continue;
      final hourTextPainter = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: color.withAlpha(216),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final textPos = Offset(
        center.dx +
            (innerRadius - 25) * cos(hourAngle) -
            hourTextPainter.width / 2,
        center.dy +
            (innerRadius - 25) * sin(hourAngle) -
            hourTextPainter.height / 2,
      );
      hourTextPainter.paint(canvas, textPos);
    }

    const markerR = 16.0;
    const markerOver = 6.0;
    final markerCenter = Offset(
      center.dx + (radius - markerR + markerOver) * cos(angle),
      center.dy + (radius - markerR + markerOver) * sin(angle),
    );

    final fx = -cos(angle);
    final fy = -sin(angle);
    final rx = -sin(angle);
    final ry = cos(angle);

    const stemW = 4.0;
    const headW = 11.0;
    const totalL = 45.0;
    const headL = 14.0;

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
        ..color = markerFillColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      markerCenter,
      markerR + 1,
      Paint()
        ..color = Colors.black.withAlpha(64)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(markerCenter, markerR, Paint()..color = markerFillColor);
    canvas.drawCircle(
      markerCenter,
      markerR,
      Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.save();
    canvas.translate(markerCenter.dx, markerCenter.dy);

    // canvas.rotate(angle);

    final fingerPrintIcon = IconDef.fingerPrint;
    final iconTp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(fingerPrintIcon.codePoint),
        style: TextStyle(
          fontFamily: fingerPrintIcon.fontFamily,
          fontSize: markerR * 1.2,
          color: markerIconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconTp.paint(canvas, Offset(-iconTp.width / 2, -iconTp.height / 2));

    canvas.restore();

    double degrees = (angle * 180 / pi + 90) % 360;
    if (degrees < 0) degrees += 360;

    final totalMin = (degrees * 2).round();
    int hour = (totalMin ~/ 60) % 12;
    if (hour == 0) hour = 12;
    final minute = totalMin % 60;
    final clockStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final directionTextPainter = TextPainter(
      text: TextSpan(
        text: l10n.windDirection,
        style: TextStyle(color: color.withAlpha(140), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    directionTextPainter.paint(
      canvas,
      Offset(
        center.dx - directionTextPainter.width / 2,
        center.dy - directionTextPainter.height / 2 - 28,
      ),
    );

    final degreesTextPainter = TextPainter(
      text: TextSpan(
        text: '${degrees.toStringAsFixed(0)}°',
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    degreesTextPainter.paint(
      canvas,
      Offset(
        center.dx - degreesTextPainter.width / 2,
        center.dy - degreesTextPainter.height / 2,
      ),
    );

    final clockTextPainter = TextPainter(
      text: TextSpan(
        text: clockStr,
        style: TextStyle(color: color.withAlpha(216), fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    clockTextPainter.paint(
      canvas,
      Offset(
        center.dx - clockTextPainter.width / 2,
        center.dy - clockTextPainter.height / 2 + 28,
      ),
    );
  }

  @override
  bool shouldRepaint(WindPainter oldDelegate) => true;
}
