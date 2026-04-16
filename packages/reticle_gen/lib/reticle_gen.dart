import 'dart:developer' show log;
import 'dart:math';

import 'package:xml/xml.dart';
import 'dart:io';

extension SvgExport on XmlElement {
  void export([String? filePath]) {
    File(filePath ?? 'temp.svg').writeAsStringSync(toXmlString(pretty: true));
  }
}

/// Accumulates SVG path commands into a `d` attribute string.
///
/// Used with [SVGCanvas.batchLines] and the ruler/dash helpers.
/// Coordinates must be in the canvas's native coordinate space
/// (pixels for [SVGCanvas], mils for [MilReticleCanvas]).
class PathBuilder {
  final StringBuffer _buffer = StringBuffer();

  void moveTo(double x, double y) => _buffer.write('M ${_n(x)} ${_n(y)} ');
  void lineTo(double x, double y) => _buffer.write('L ${_n(x)} ${_n(y)} ');
  void close() => _buffer.write('Z ');
  void arcTo(
    double rx,
    double ry,
    double rotation,
    bool largeArc,
    bool sweep,
    double x,
    double y,
  ) => _buffer.write(
    'A ${_n(rx)} ${_n(ry)} ${_n(rotation)} '
    '${largeArc ? 1 : 0} ${sweep ? 1 : 0} ${_n(x)} ${_n(y)} ',
  );

  bool get isEmpty => _buffer.isEmpty;
  String get d => _buffer.toString().trimRight();
  void clear() => _buffer.clear();

  static String _n(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

/// Інтерфейс для малювання на канвасі
abstract interface class CanvasInterface {
  double get width;
  double get height;

  /// Малює лінію
  void line(
    double x1,
    double y1,
    double x2,
    double y2,
    String stroke,
    double strokeWidth,
  );

  /// Малює прямокутник
  void rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    String? stroke,
    double? strokeWidth,
  });

  /// Заповнює весь канвас кольором
  void fill(String fill);

  /// Малює коло
  void circle(
    double cx,
    double cy,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  });

  /// Малює шлях
  void path(String d, String fill, {String? stroke, double? strokeWidth});

  /// Додає текст
  void text(
    String content,
    double x,
    double y,
    String fill, {
    double fontSize,
    String textAnchor,
  });

  /// Малює [draw] з обрізанням по формі [shape].
  /// Форма описується тими ж методами канвасу; колір fill/stroke ігнорується.
  void clip({
    required void Function(CanvasInterface canvas) shape,
    required void Function(CanvasInterface canvas) draw,
  });
}

abstract interface class DrawerInterface {
  void draw(CanvasInterface canvas);
}

class SVGCanvas implements CanvasInterface {
  final double width;
  final double height;
  late final XmlElement _svgElement;
  late XmlElement _target;
  int _clipCounter = 0;

  final Map<String, int> _idCounters = {};
  String? _idHint;

  SVGCanvas({this.width = 640.0, this.height = 640.0});

  XmlElement get svg => _svgElement;

  /// Поточний контейнер для запису елементів.
  /// Підкласи, що додають елементи напряму, мають використовувати його.
  XmlElement get target => _target;

  /// Returns the next auto-generated element id for [prefix] and increments
  /// the internal counter for that prefix.
  ///
  /// If a hint was set by a higher-level helper (e.g. [hRuler] sets `'hruler'`
  /// before calling [path]), the hint is used as the prefix instead, so the
  /// emitted element gets a semantically meaningful id like `hruler-0`.
  /// Subclasses may call this method directly.
  String nextId(String prefix) {
    final p = _idHint ?? prefix;
    _idHint = null;
    final n = _idCounters[p] ?? 0;
    _idCounters[p] = n + 1;
    return '$p-$n';
  }

  // Sets a one-shot hint consumed by the next [nextId] call.
  // Uses ??= so the first caller wins when helpers delegate to each other
  // (e.g. hDashLine sets 'hdashline' before calling dashLine which also hints).
  void _hint(String h) { _idHint ??= h; }

  static void _warn(String method, String reason) =>
      log('$method: $reason', name: 'reticle_gen', level: 900);

  XmlElement generate(DrawerInterface drawer) {
    final double minX = -width / 2;
    final double minY = -height / 2;

    _svgElement = XmlElement(XmlName('svg'), [
      XmlAttribute(XmlName('xmlns'), 'http://www.w3.org/2000/svg'),
      XmlAttribute(XmlName('width'), width.toString()),
      XmlAttribute(XmlName('height'), height.toString()),
      XmlAttribute(XmlName('viewBox'), '$minX $minY $width $height'),
    ]);
    _target = _svgElement;

    drawer.draw(this);

    return _svgElement;
  }

  @override
  void line(
    double x1,
    double y1,
    double x2,
    double y2,
    String stroke,
    double strokeWidth,
  ) {
    _target.children.add(
      XmlElement(XmlName('line'), [
        XmlAttribute(XmlName('id'), nextId('line')),
        XmlAttribute(XmlName('x1'), x1.toString()),
        XmlAttribute(XmlName('y1'), y1.toString()),
        XmlAttribute(XmlName('x2'), x2.toString()),
        XmlAttribute(XmlName('y2'), y2.toString()),
        XmlAttribute(XmlName('stroke'), stroke),
        XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    _target.children.add(
      XmlElement(XmlName('rect'), [
        XmlAttribute(XmlName('id'), nextId('rect')),
        XmlAttribute(XmlName('x'), x.toString()),
        XmlAttribute(XmlName('y'), y.toString()),
        XmlAttribute(XmlName('width'), w.toString()),
        XmlAttribute(XmlName('height'), h.toString()),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void fill(String fill) {
    _hint('fill');
    rect(-width / 2, -height / 2, width, height, fill);
  }

  @override
  void circle(
    double cx,
    double cy,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    _target.children.add(
      XmlElement(XmlName('circle'), [
        XmlAttribute(XmlName('id'), nextId('circle')),
        XmlAttribute(XmlName('cx'), cx.toString()),
        XmlAttribute(XmlName('cy'), cy.toString()),
        XmlAttribute(XmlName('r'), r.toString()),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void path(String d, String fill, {String? stroke, double? strokeWidth}) {
    _target.children.add(
      XmlElement(XmlName('path'), [
        XmlAttribute(XmlName('id'), nextId('path')),
        XmlAttribute(XmlName('d'), d),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void text(
    String content,
    double x,
    double y,
    String fill, {
    double fontSize = 12,
    String textAnchor = 'middle',
  }) {
    _target.children.add(
      XmlElement(
        XmlName('text'),
        [
          XmlAttribute(XmlName('id'), nextId('text')),
          XmlAttribute(XmlName('x'), x.toString()),
          XmlAttribute(XmlName('y'), y.toString()),
          XmlAttribute(XmlName('fill'), fill),
          XmlAttribute(XmlName('font-size'), fontSize.toString()),
          XmlAttribute(XmlName('text-anchor'), textAnchor),
        ],
        [XmlText(content)],
      ),
    );
  }

  /// Обрізає вміст [draw] по формі [shape].
  /// Генерує `<clipPath>` та `<g clip-path="url(#...)">` без використання `<defs>`.
  @override
  void clip({
    required void Function(CanvasInterface canvas) shape,
    required void Function(CanvasInterface canvas) draw,
  }) {
    final clipId = 'clip${_clipCounter++}';

    final clipPathEl = XmlElement(XmlName('clipPath'), [
      XmlAttribute(XmlName('id'), clipId),
    ]);
    final prevTarget = _target;
    _target = clipPathEl;
    shape(this);
    _target = prevTarget;
    _svgElement.children.add(clipPathEl);

    final groupEl = XmlElement(XmlName('g'), [
      XmlAttribute(XmlName('id'), nextId('clipgroup')),
      XmlAttribute(XmlName('clip-path'), 'url(#$clipId)'),
    ]);
    _target = groupEl;
    draw(this);
    _target = prevTarget;
    _svgElement.children.add(groupEl);
  }

  // ── Aliases that delegate to virtual interface methods ──────────────────────
  // Subclasses (e.g. MilReticleCanvas) override line/circle/path, so all
  // helpers below pick up coordinate scaling for free via polymorphic dispatch.

  void hLine(double y, double x1, double x2, String stroke, double strokeWidth) {
    _hint('hline');
    line(x1, y, x2, y, stroke, strokeWidth);
  }

  void vLine(double x, double y1, double y2, String stroke, double strokeWidth) {
    _hint('vline');
    line(x, y1, x, y2, stroke, strokeWidth);
  }

  void dot(
    double cx,
    double cy,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    _hint('dot');
    circle(cx, cy, r, fill, stroke: stroke, strokeWidth: strokeWidth);
  }

  // ── Multi-element helpers that emit a single <path> ─────────────────────────
  // Each builds a PathBuilder in the canvas's native coordinate space, then
  // calls this.path() so MilReticleCanvas.path() applies the scale transform.

  /// Tick marks along X, centred at [y], from [start] to [end] with [step]
  /// spacing. Each tick is [tickLength] tall.
  void hRuler(
    double start,
    double end,
    double step,
    double tickLength,
    String stroke,
    double strokeWidth, {
    double y = 0,
  }) {
    if (step == 0) { _warn('hRuler', 'step must not be zero'); return; }
    final pb = PathBuilder();
    final half = tickLength / 2;
    double x = start;
    while (step > 0 ? x <= end + 1e-9 : x >= end - 1e-9) {
      pb.moveTo(x, y - half);
      pb.lineTo(x, y + half);
      x += step;
    }
    if (!pb.isEmpty) {
      _hint('hruler');
      path(pb.d, 'none', stroke: stroke, strokeWidth: strokeWidth);
    }
  }

  /// Tick marks along Y, centred at [x], from [start] to [end] with [step]
  /// spacing. Each tick is [tickLength] wide.
  void vRuler(
    double start,
    double end,
    double step,
    double tickLength,
    String stroke,
    double strokeWidth, {
    double x = 0,
  }) {
    if (step == 0) { _warn('vRuler', 'step must not be zero'); return; }
    final pb = PathBuilder();
    final half = tickLength / 2;
    double y = start;
    while (step > 0 ? y <= end + 1e-9 : y >= end - 1e-9) {
      pb.moveTo(x - half, y);
      pb.lineTo(x + half, y);
      y += step;
    }
    if (!pb.isEmpty) {
      _hint('vruler');
      path(pb.d, 'none', stroke: stroke, strokeWidth: strokeWidth);
    }
  }

  /// Crosshair centred at ([cx], [cy]) with total arm length [size].
  void cross(
    double cx,
    double cy,
    double size,
    String stroke,
    double strokeWidth,
  ) {
    final half = size / 2;
    final pb = PathBuilder()
      ..moveTo(cx - half, cy)
      ..lineTo(cx + half, cy)
      ..moveTo(cx, cy - half)
      ..lineTo(cx, cy + half);
    _hint('cross');
    path(pb.d, 'none', stroke: stroke, strokeWidth: strokeWidth);
  }

  /// Dashed line from ([x1],[y1]) to ([x2],[y2]).
  void dashLine(
    double x1,
    double y1,
    double x2,
    double y2,
    double dashLen,
    double gapLen,
    String stroke,
    double strokeWidth,
  ) {
    if (dashLen <= 0 && gapLen <= 0) { _warn('dashLine', 'dashLen and gapLen are both <= 0'); return; }
    final dx = x2 - x1;
    final dy = y2 - y1;
    final length = sqrt(dx * dx + dy * dy);
    if (length < 1e-9) return;
    final ux = dx / length;
    final uy = dy / length;
    final pb = PathBuilder();
    bool drawing = true;
    double t = 0;
    while (t < length - 1e-9) {
      final seg = drawing ? dashLen : gapLen;
      final endT = min(t + seg, length);
      if (drawing) {
        pb.moveTo(x1 + ux * t, y1 + uy * t);
        pb.lineTo(x1 + ux * endT, y1 + uy * endT);
      }
      t = endT;
      drawing = !drawing;
    }
    if (!pb.isEmpty) {
      _hint('dashline');
      path(pb.d, 'none', stroke: stroke, strokeWidth: strokeWidth);
    }
  }

  void hDashLine(
    double y,
    double x1,
    double x2,
    double dashLen,
    double gapLen,
    String stroke,
    double strokeWidth,
  ) {
    _hint('hdashline');
    dashLine(x1, y, x2, y, dashLen, gapLen, stroke, strokeWidth);
  }

  void vDashLine(
    double x,
    double y1,
    double y2,
    double dashLen,
    double gapLen,
    String stroke,
    double strokeWidth,
  ) {
    _hint('vdashline');
    dashLine(x, y1, x, y2, dashLen, gapLen, stroke, strokeWidth);
  }

  /// Evenly spaced dots along the line from ([x1],[y1]) to ([x2],[y2]).
  void dotLine(
    double x1,
    double y1,
    double x2,
    double y2,
    double spacing,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final length = sqrt(dx * dx + dy * dy);
    if (length < 1e-9) {
      dot(x1, y1, r, fill, stroke: stroke, strokeWidth: strokeWidth);
      return;
    }
    if (spacing <= 0) {
      _warn('dotLine', 'spacing must be > 0, drawing single dot');
      dot(x1, y1, r, fill, stroke: stroke, strokeWidth: strokeWidth);
      return;
    }
    final ux = dx / length;
    final uy = dy / length;
    double t = 0;
    while (t <= length + 1e-9) {
      dot(x1 + ux * t, y1 + uy * t, r, fill, stroke: stroke, strokeWidth: strokeWidth);
      t += spacing;
    }
  }

  void hDotLine(
    double y,
    double x1,
    double x2,
    double spacing,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) => dotLine(x1, y, x2, y, spacing, r, fill, stroke: stroke, strokeWidth: strokeWidth);

  void vDotLine(
    double x,
    double y1,
    double y2,
    double spacing,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) => dotLine(x, y1, x, y2, spacing, r, fill, stroke: stroke, strokeWidth: strokeWidth);

  /// Calls [draw] for every grid point in [x1..x2] × [y1..y2].
  void repeat(
    double x1,
    double y1,
    double x2,
    double y2,
    double xStep,
    double yStep,
    void Function(double x, double y) draw,
  ) {
    if (xStep == 0 || yStep == 0) return;
    for (
      double y = y1;
      yStep > 0 ? y <= y2 + 1e-9 : y >= y2 - 1e-9;
      y += yStep
    ) {
      for (
        double x = x1;
        xStep > 0 ? x <= x2 + 1e-9 : x >= x2 - 1e-9;
        x += xStep
      ) {
        draw(x, y);
      }
    }
  }

  /// Calls [build] with a [PathBuilder] and emits the result as one `<path>`.
  /// Use this to combine arbitrary line segments with the same style.
  void batchLines(
    String stroke,
    double strokeWidth,
    void Function(PathBuilder pb) build,
  ) {
    final pb = PathBuilder();
    build(pb);
    if (!pb.isEmpty) {
      _hint('batch');
      path(pb.d, 'none', stroke: stroke, strokeWidth: strokeWidth);
    }
  }
}

class CrossDrawer implements DrawerInterface {
  final double size;
  final double strokeWidth;
  final String color;

  CrossDrawer({this.size = 200, this.strokeWidth = 2, this.color = 'red'});

  @override
  void draw(CanvasInterface canvas) {
    canvas
      // Горизонтальна лінія через центр
      ..line(-size / 2, 0, size / 2, 0, color, strokeWidth)
      // Вертикальна лінія через центр
      ..line(0, -size / 2, 0, size / 2, color, strokeWidth);
  }
}

// Хрест з колом (як приціл)
class ScopeDrawer extends DrawerInterface {
  final double radius;
  final double lineLength;
  final double strokeWidth;
  final String color;

  ScopeDrawer({
    this.radius = 100,
    this.lineLength = 150,
    this.strokeWidth = 2,
    this.color = '#00FF00',
  });

  @override
  void draw(CanvasInterface canvas) {
    final diagLength = radius * 0.7;

    canvas
      // Зовнішнє коло
      ..circle(0, 0, radius, 'none', stroke: color, strokeWidth: strokeWidth)
      // Хрест
      ..line(-lineLength / 2, 0, lineLength / 2, 0, color, strokeWidth)
      ..line(0, -lineLength / 2, 0, lineLength / 2, color, strokeWidth)
      // Діагональні лінії (опційно)
      ..line(
        -diagLength,
        -diagLength,
        diagLength,
        diagLength,
        color,
        strokeWidth * 0.7,
      )
      ..line(
        -diagLength,
        diagLength,
        diagLength,
        -diagLength,
        color,
        strokeWidth * 0.7,
      )
      // Центральна точка
      ..circle(0, 0, strokeWidth * 2, color);

    // Розмітка (риски на колі)
    for (int i = 0; i < 360; i += 30) {
      final rad = i * 3.14159 / 180;
      final x1 = radius * cos(rad);
      final y1 = radius * sin(rad);
      final x2 = (radius - 10) * cos(rad);
      final y2 = (radius - 10) * sin(rad);
      canvas.line(x1, y1, x2, y2, color, strokeWidth * 0.5);
    }
  }
}

// Комбінований drawer (можна комбінувати кілька)
class CompositeDrawer extends DrawerInterface {
  final List<DrawerInterface> drawers;

  CompositeDrawer(this.drawers);

  @override
  void draw(CanvasInterface canvas) {
    for (var drawer in drawers) {
      drawer.draw(canvas);
    }
  }
}

// Приклад кастомного drawer для малювання галактики
class _CustomGalaxyDrawer extends DrawerInterface {
  @override
  void draw(CanvasInterface canvas) {
    final random = Random();

    // Малюємо фоновий градієнт (через rect)
    canvas.rect(-400, -400, 800, 800, '#0a0a2a');

    // Малюємо спіраль галактики
    for (double r = 20; r <= 300; r += 15) {
      final angle = r * 0.1;
      final x = r * cos(angle);
      final y = r * sin(angle);

      canvas.circle(x, y, 2, 'white', stroke: 'cyan', strokeWidth: 0.5);

      // Друге плече спіралі
      final x2 = r * cos(angle + 3.14159);
      final y2 = r * sin(angle + 3.14159);
      canvas.circle(x2, y2, 2, 'white', stroke: 'cyan', strokeWidth: 0.5);
    }

    // Додаємо зірки випадково
    for (int i = 0; i < 500; i++) {
      final x = random.nextDouble() * 700 - 350;
      final y = random.nextDouble() * 700 - 350;
      final brightness = random.nextDouble() * 0.5 + 0.5;
      final size = random.nextDouble() * 2 + 0.5;

      canvas.circle(x, y, size, 'rgba(255,255,255,$brightness)');
    }

    // Ядро галактики
    for (int i = 0; i < 100; i++) {
      final angle = random.nextDouble() * 2 * 3.14159;
      final r = random.nextDouble() * 30;
      final x = r * cos(angle);
      final y = r * sin(angle);
      canvas.circle(
        x,
        y,
        random.nextDouble() * 3 + 1,
        'rgba(255,200,100,${random.nextDouble() * 0.8 + 0.2})',
      );
    }
  }
}

void main() {
  // Приклад 1: Простий хрест
  print('Створюємо SVG з простим хрестом...');
  final crossDrawer = CrossDrawer(size: 300, strokeWidth: 3, color: '#FF0000');
  SVGCanvas().generate(crossDrawer).export('cross.svg');

  // Приклад 2: Приціл з колом
  print('Створюємо SVG з прицілом...');
  final scopeDrawer = ScopeDrawer(
    radius: 200,
    lineLength: 350,
    strokeWidth: 2,
    color: '#00FF00',
  );
  SVGCanvas().generate(scopeDrawer).export('scope.svg');

  // Приклад 3: Комбінований малюнок
  print('Створюємо SVG з комбінованим малюнком...');
  final combinedDrawer = CompositeDrawer([
    ScopeDrawer(
      radius: 250,
      lineLength: 450,
      strokeWidth: 1.5,
      color: '#FF6600',
    ),
    CrossDrawer(size: 100, strokeWidth: 1, color: '#FFFFFF'),
  ]);
  SVGCanvas().generate(combinedDrawer).export('combined.svg');

  // Приклад 4: Кастомний малюнок (галактика)
  print('Створюємо SVG з кастомним малюнком...');
  final customDrawer = _CustomGalaxyDrawer();
  SVGCanvas().generate(customDrawer).export('galaxy.svg');

  print('Всі SVG файли успішно створено!');
  print('- cross.svg');
  print('- scope.svg');
  print('- combined.svg');
  print('- galaxy.svg');
}
