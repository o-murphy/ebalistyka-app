import 'dart:developer' show log;
import 'dart:math' as math;

import 'package:xml/xml.dart';
import 'dart:io';

extension SvgExport on XmlElement {
  void export([String? filePath]) {
    File(filePath ?? 'temp.svg').writeAsStringSync(toXmlString(pretty: true));
  }
}

/// Formats [v] as a compact SVG number, rounded to 3 decimal places.
/// Trailing zeros after the decimal point are stripped (e.g. 1.500 → "1.5").
String _fmtNum(double v) {
  final rounded = (v * 1000).roundToDouble() / 1000;
  if (rounded == rounded.truncateToDouble()) {
    return rounded.toInt().toString();
  }
  return rounded
      .toStringAsFixed(3)
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

/// Accumulates SVG path commands into a `d` attribute string.
///
/// Used with [SVGCanvas.batchLines] and the ruler/dash helpers.
/// Coordinates must be in the canvas's native coordinate space
/// (pixels for [SVGCanvas], mils for [MilReticleSVGCanvas]).
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

  /// Appends a full circle as four clockwise quarter-arcs.
  /// Four arcs avoid the 180° ambiguity of two-arc approaches.
  void dotCircle(double cx, double cy, double r) {
    moveTo(cx - r, cy);
    arcTo(r, r, 0, false, true, cx, cy + r);
    arcTo(r, r, 0, false, true, cx + r, cy);
    arcTo(r, r, 0, false, true, cx, cy - r);
    arcTo(r, r, 0, false, true, cx - r, cy);
    close();
  }

  bool get isEmpty => _buffer.isEmpty;
  String get d => _buffer.toString().trimRight();
  void clear() => _buffer.clear();

  static String _n(double v) => _fmtNum(v);
}

// /// Інтерфейс для малювання на канвасі
// abstract interface class CanvasInterface {
//   double get width;
//   double get height;

//   /// Малює лінію
//   void line(
//     double x1,
//     double y1,
//     double x2,
//     double y2,
//     String stroke,
//     double strokeWidth,
//   );

//   /// Малює прямокутник
//   void rect(
//     double x,
//     double y,
//     double w,
//     double h,
//     String fill, {
//     String? stroke,
//     double? strokeWidth,
//   });

//   /// Заповнює весь канвас кольором
//   void fill(String fill);

//   /// Малює коло
//   void circle(
//     double cx,
//     double cy,
//     double r,
//     String fill, {
//     String? stroke,
//     double? strokeWidth,
//   });

//   /// Малює шлях
//   void path(String d, String fill, {String? stroke, double? strokeWidth});

//   /// Додає текст
//   void text(
//     String content,
//     double x,
//     double y,
//     String fill, {
//     double fontSize,
//     String textAnchor,
//   });

//   /// Малює [draw] з обрізанням по формі [shape].
//   /// Форма описується тими ж методами канвасу; колір fill/stroke ігнорується.
//   void clip({
//     required void Function(CanvasInterface canvas) shape,
//     required void Function(CanvasInterface canvas) draw,
//   });
// }

abstract interface class SVGDrawerInterface {
  void draw(SVGCanvas canvas);
}

class SVGCanvas {
  final double width;
  final double height;
  late final XmlElement _svgElement;
  late XmlElement _target;
  late XmlElement _contentRoot;
  int _clipCounter = 0;

  /// Scale factor applied to all drawing coordinates.
  /// Use it when the drawer works in a different unit than the SVG viewBox
  /// (e.g. `unitScale = moaToMil` lets the drawer use MOA while the viewBox
  /// stays in MIL).  Implemented as a `<g transform="scale(unitScale)">` so
  /// every element — including `<path>` d-strings — is scaled automatically.
  final double unitScale;

  final Map<String, int> _idCounters = {};
  String? _idHint;

  SVGCanvas({this.width = 640.0, this.height = 640.0, this.unitScale = 1.0});

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
  void _hint(String h) {
    _idHint ??= h;
  }

  static void _warn(String method, String reason) =>
      log('$method: $reason', name: 'reticle_gen', level: 900);

  XmlElement generate(SVGDrawerInterface drawer) {
    final double minX = -width / 2;
    final double minY = -height / 2;

    _svgElement = XmlElement(XmlName('svg'), [
      XmlAttribute(XmlName('xmlns'), 'http://www.w3.org/2000/svg'),
      XmlAttribute(XmlName('width'), _fmtNum(width)),
      XmlAttribute(XmlName('height'), _fmtNum(height)),
      XmlAttribute(
        XmlName('viewBox'),
        '${_fmtNum(minX)} ${_fmtNum(minY)} ${_fmtNum(width)} ${_fmtNum(height)}',
      ),
    ]);
    _idCounters.clear();
    _clipCounter = 0;

    if (unitScale != 1.0) {
      final scaleGroup = XmlElement(XmlName('g'), [
        XmlAttribute(XmlName('transform'), 'scale(${_fmtNum(unitScale)})'),
      ]);
      _svgElement.children.add(scaleGroup);
      _contentRoot = scaleGroup;
    } else {
      _contentRoot = _svgElement;
    }
    _target = _contentRoot;

    drawer.draw(this);

    return _svgElement;
  }

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
        XmlAttribute(XmlName('x1'), _fmtNum(x1)),
        XmlAttribute(XmlName('y1'), _fmtNum(y1)),
        XmlAttribute(XmlName('x2'), _fmtNum(x2)),
        XmlAttribute(XmlName('y2'), _fmtNum(y2)),
        XmlAttribute(XmlName('stroke'), stroke),
        XmlAttribute(XmlName('stroke-width'), _fmtNum(strokeWidth)),
      ]),
    );
  }

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
        XmlAttribute(XmlName('x'), _fmtNum(x)),
        XmlAttribute(XmlName('y'), _fmtNum(y)),
        XmlAttribute(XmlName('width'), _fmtNum(w)),
        XmlAttribute(XmlName('height'), _fmtNum(h)),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), _fmtNum(strokeWidth)),
      ]),
    );
  }

  void fill(String fill) {
    _hint('fill');
    final w = width / unitScale;
    final h = height / unitScale;
    rect(-w / 2, -h / 2, w, h, fill);
  }

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
        XmlAttribute(XmlName('cx'), _fmtNum(cx)),
        XmlAttribute(XmlName('cy'), _fmtNum(cy)),
        XmlAttribute(XmlName('r'), _fmtNum(r)),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), _fmtNum(strokeWidth)),
      ]),
    );
  }

  void path(String d, String fill, {String? stroke, double? strokeWidth}) {
    _target.children.add(
      XmlElement(XmlName('path'), [
        XmlAttribute(XmlName('id'), nextId('path')),
        XmlAttribute(XmlName('d'), d),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), _fmtNum(strokeWidth)),
      ]),
    );
  }

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
          XmlAttribute(XmlName('x'), _fmtNum(x)),
          XmlAttribute(XmlName('y'), _fmtNum(y)),
          XmlAttribute(XmlName('fill'), fill),
          XmlAttribute(XmlName('font-size'), _fmtNum(fontSize)),
          XmlAttribute(XmlName('text-anchor'), textAnchor),
        ],
        [XmlText(content)],
      ),
    );
  }

  /// Обрізає вміст [draw] по формі [shape].
  /// Генерує `<clipPath>` та `<g clip-path="url(#...)">` без використання `<defs>`.
  void clip({
    required void Function(SVGCanvas canvas) shape,
    required void Function(SVGCanvas canvas) draw,
  }) {
    final clipId = 'clip${_clipCounter++}';

    final clipPathEl = XmlElement(XmlName('clipPath'), [
      XmlAttribute(XmlName('id'), clipId),
    ]);
    final prevTarget = _target;
    _target = clipPathEl;
    shape(this);
    _target = prevTarget;
    _contentRoot.children.add(clipPathEl);

    final groupEl = XmlElement(XmlName('g'), [
      XmlAttribute(XmlName('id'), nextId('clipgroup')),
      XmlAttribute(XmlName('clip-path'), 'url(#$clipId)'),
    ]);
    _target = groupEl;
    draw(this);
    _target = prevTarget;
    _contentRoot.children.add(groupEl);
  }

  // ── Aliases that delegate to virtual interface methods ──────────────────────
  // Subclasses (e.g. MilReticleCanvas) override line/circle/path, so all
  // helpers below pick up coordinate scaling for free via polymorphic dispatch.

  void hLine(
    double y,
    double x1,
    double x2,
    String stroke,
    double strokeWidth,
  ) {
    _hint('hline');
    line(x1, y, x2, y, stroke, strokeWidth);
  }

  void vLine(
    double x,
    double y1,
    double y2,
    String stroke,
    double strokeWidth,
  ) {
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
    if (step == 0) {
      _warn('hRuler', 'step must not be zero');
      return;
    }
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
    if (step == 0) {
      _warn('vRuler', 'step must not be zero');
      return;
    }
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
    if (dashLen <= 0 && gapLen <= 0) {
      _warn('dashLine', 'dashLen and gapLen are both <= 0');
      return;
    }
    final dx = x2 - x1;
    final dy = y2 - y1;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < 1e-9) return;
    final ux = dx / length;
    final uy = dy / length;
    final pb = PathBuilder();
    bool drawing = true;
    double t = 0;
    while (t < length - 1e-9) {
      final seg = drawing ? dashLen : gapLen;
      final endT = math.min(t + seg, length);
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
  ///
  /// Emits a single `<path>` with arc sub-paths — flutter_svg compatible.
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
    _hint('dotline');
    final dx = x2 - x1;
    final dy = y2 - y1;
    final length = math.sqrt(dx * dx + dy * dy);
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
    final pb = PathBuilder();
    for (var t = 0.0; t <= length + 1e-9; t += spacing) {
      pb.dotCircle(x1 + t * ux, y1 + t * uy, r);
    }
    if (!pb.isEmpty) {
      path(pb.d, fill, stroke: stroke, strokeWidth: strokeWidth);
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
  }) => dotLine(
    x1,
    y,
    x2,
    y,
    spacing,
    r,
    fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
  );

  void vDotLine(
    double x,
    double y1,
    double y2,
    double spacing,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) => dotLine(
    x,
    y1,
    x,
    y2,
    spacing,
    r,
    fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
  );

  /// Fills the axis-aligned rectangle [x1..x2] × [y1..y2] with a uniform
  /// grid of dots at every ([xStep], [yStep]) interval.
  ///
  /// Emits a single `<path>` with arc sub-paths — flutter_svg compatible.
  /// Use [repeat] when the per-point drawing varies; use [dotGrid] when every
  /// point gets an identical dot.
  void dotGrid(
    double x1,
    double y1,
    double x2,
    double y2,
    double xStep,
    double yStep,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    if (xStep <= 0 || yStep <= 0) return;
    _hint('dotgrid');
    final pb = PathBuilder();
    for (double y = y1; y <= y2 + 1e-9; y += yStep) {
      for (double x = x1; x <= x2 + 1e-9; x += xStep) {
        pb.dotCircle(x, y, r);
      }
    }
    if (!pb.isEmpty) {
      path(pb.d, fill, stroke: stroke, strokeWidth: strokeWidth);
    }
  }

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
    void Function(PathBuilder pb) build, {
    String fill = 'none',
  }) {
    final pb = PathBuilder();
    build(pb);
    if (!pb.isEmpty) {
      _hint('batch');
      path(pb.d, fill, stroke: stroke, strokeWidth: strokeWidth);
    }
  }
}

class CrossDrawer implements SVGDrawerInterface {
  final double size;
  final double strokeWidth;
  final String color;

  CrossDrawer({this.size = 200, this.strokeWidth = 2, this.color = 'red'});

  @override
  void draw(SVGCanvas canvas) {
    canvas
      // Горизонтальна лінія через центр
      ..line(-size / 2, 0, size / 2, 0, color, strokeWidth)
      // Вертикальна лінія через центр
      ..line(0, -size / 2, 0, size / 2, color, strokeWidth);
  }
}

// Хрест з колом (як приціл)
class ScopeDrawer extends SVGDrawerInterface {
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
  void draw(SVGCanvas canvas) {
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
      final x1 = radius * math.cos(rad);
      final y1 = radius * math.sin(rad);
      final x2 = (radius - 10) * math.cos(rad);
      final y2 = (radius - 10) * math.sin(rad);
      canvas.line(x1, y1, x2, y2, color, strokeWidth * 0.5);
    }
  }
}

// Комбінований drawer (можна комбінувати кілька)
class CompositeSVGDrawer extends SVGDrawerInterface {
  final List<SVGDrawerInterface> drawers;

  CompositeSVGDrawer(this.drawers);

  @override
  void draw(SVGCanvas canvas) {
    for (var drawer in drawers) {
      drawer.draw(canvas);
    }
  }
}

// Приклад кастомного drawer для малювання галактики
class _CustomGalaxyDrawer extends SVGDrawerInterface {
  @override
  void draw(SVGCanvas canvas) {
    final random = math.Random();

    // Малюємо фоновий градієнт (через rect)
    canvas.rect(-400, -400, 800, 800, '#0a0a2a');

    // Малюємо спіраль галактики
    for (double r = 20; r <= 300; r += 15) {
      final angle = r * 0.1;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);

      canvas.circle(x, y, 2, 'white', stroke: 'cyan', strokeWidth: 0.5);

      // Друге плече спіралі
      final x2 = r * math.cos(angle + 3.14159);
      final y2 = r * math.sin(angle + 3.14159);
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
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      canvas.circle(
        x,
        y,
        random.nextDouble() * 3 + 1,
        'rgba(255,200,100,${random.nextDouble() * 0.8 + 0.2})',
      );
    }
  }
}

/// A canvas whose coordinate system is in mils.
///
/// The SVG [viewBox] spans [−milWidth/2 .. milWidth/2] × [−milHeight/2 ..
/// milHeight/2] in mil units, while the physical [width]/[height] attributes
/// are in pixels ([milWidth] × [factor] and [milHeight] × [factor]).
/// The SVG renderer handles all scaling — no per-element multiplication needed.
class MilReticleSVGCanvas extends SVGCanvas {
  final int factor;
  final double milWidth;
  final double milHeight;

  /// Correction from em-square to cap-height for typical sans-serif fonts.
  /// Lets callers specify [fontSize] as the visible height of capital letters
  /// rather than the SVG em-square unit.
  static const double _capHeightRatio = 0.72;

  MilReticleSVGCanvas({
    this.milWidth = 30.0,
    this.milHeight = 30.0,
    this.factor = 100,
    super.unitScale = 1.0,
  }) : super(width: milWidth, height: milHeight);

  @override
  XmlElement generate(SVGDrawerInterface drawer) {
    final el = super.generate(drawer);
    // super.generate() sets width/height to milWidth/milHeight (user-unit values).
    // Override them with the intended pixel dimensions.
    el.setAttribute('width', _fmtNum(milWidth * factor));
    el.setAttribute('height', _fmtNum(milHeight * factor));
    el.setAttribute('data-mil-width', _fmtNum(milWidth));
    el.setAttribute('data-mil-height', _fmtNum(milHeight));
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
  final combinedDrawer = CompositeSVGDrawer([
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
