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
/// Used with [MilReticleSVGCanvas.batchLines] and the ruler/dash helpers.
/// Coordinates must be in the canvas's native coordinate space (mils).
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

abstract interface class SVGDrawerInterface {
  void draw(MilReticleSVGCanvas canvas);
}

// ─── Stroke font — 7-segment style, platform-independent ─────────────────────

class _StrokeFont {
  static const double widthRatio = 0.55;

  static const _segT = 0; // top horizontal
  static const _segM = 1; // middle horizontal
  static const _segB = 2; // bottom horizontal
  static const _segUl = 3; // upper-left vertical
  static const _segUr = 4; // upper-right vertical
  static const _segLl = 5; // lower-left vertical
  static const _segLr = 6; // lower-right vertical
  static const _segCv = 7; // center vertical (full height, for '1')

  static const _glyphs = <String, List<int>>{
    '0': [_segT, _segUl, _segUr, _segLl, _segLr, _segB],
    '1': [_segCv],
    '2': [_segT, _segUr, _segM, _segLl, _segB],
    '3': [_segT, _segUr, _segM, _segLr, _segB],
    '4': [_segUl, _segUr, _segM, _segLr],
    '5': [_segT, _segUl, _segM, _segLr, _segB],
    '6': [_segT, _segUl, _segM, _segLl, _segLr, _segB],
    '7': [_segT, _segUr, _segLr],
    '8': [_segT, _segUl, _segUr, _segM, _segLl, _segLr, _segB],
    '9': [_segT, _segUl, _segUr, _segM, _segLr, _segB],
    '-': [_segM],
  };

  static bool hasGlyph(String c) => _glyphs.containsKey(c);

  static void drawGlyph(
    String char,
    double ox,
    double oy,
    double w,
    double h,
    PathBuilder pb,
  ) {
    final segs = _glyphs[char];
    if (segs == null) return;
    final hh = h / 2;
    for (final seg in segs) {
      switch (seg) {
        case _segT:
          pb
            ..moveTo(ox, oy)
            ..lineTo(ox + w, oy);
        case _segM:
          pb
            ..moveTo(ox, oy + hh)
            ..lineTo(ox + w, oy + hh);
        case _segB:
          pb
            ..moveTo(ox, oy + h)
            ..lineTo(ox + w, oy + h);
        case _segUl:
          pb
            ..moveTo(ox, oy)
            ..lineTo(ox, oy + hh);
        case _segUr:
          pb
            ..moveTo(ox + w, oy)
            ..lineTo(ox + w, oy + hh);
        case _segLl:
          pb
            ..moveTo(ox, oy + hh)
            ..lineTo(ox, oy + h);
        case _segLr:
          pb
            ..moveTo(ox + w, oy + hh)
            ..lineTo(ox + w, oy + h);
        case _segCv:
          pb
            ..moveTo(ox + w / 2, oy)
            ..lineTo(ox + w / 2, oy + h);
      }
    }
  }
}

/// A canvas whose coordinate system is in mils.
///
/// The SVG [viewBox] spans [−milWidth/2 .. milWidth/2] × [−milHeight/2 ..
/// milHeight/2] in mil units, while the physical pixel dimensions are
/// [milWidth × factor] × [milHeight × factor].
/// The SVG renderer handles all scaling — no per-element multiplication needed.
///
/// When [unitScale] ≠ 1.0, all drawing coordinates are wrapped in a
/// `<g transform="scale(unitScale)">` so callers can work in a different unit
/// (e.g. `unitScale = moaToMil` lets the drawer use MOA while the viewBox
/// stays in MIL).
class MilReticleSVGCanvas {
  final double milWidth;
  final double milHeight;
  final int factor;
  final double unitScale;

  /// Convenience aliases so helpers can reference [width]/[height] uniformly.
  double get width => milWidth;
  double get height => milHeight;

  late final XmlElement _svgElement;
  late XmlElement _target;
  late XmlElement _contentRoot;
  int _clipCounter = 0;

  final Map<String, int> _idCounters = {};
  String? _idHint;

  /// Correction from em-square to cap-height for typical sans-serif fonts.
  /// Lets callers specify [fontSize] as the visible height of capital letters
  /// rather than the SVG em-square unit.
  static const double _capHeightRatio = 0.72;

  MilReticleSVGCanvas({
    this.milWidth = 30.0,
    this.milHeight = 30.0,
    this.factor = 100,
    this.unitScale = 1.0,
  });

  XmlElement get svg => _svgElement;

  /// Current container for writing elements.
  /// Subclasses that add elements directly must use this.
  XmlElement get target => _target;

  /// Returns the next auto-generated element id for [prefix] and increments
  /// the internal counter for that prefix.
  String nextId(String prefix) {
    final p = _idHint ?? prefix;
    _idHint = null;
    final n = _idCounters[p] ?? 0;
    _idCounters[p] = n + 1;
    return '$p-$n';
  }

  void _hint(String h) {
    _idHint ??= h;
  }

  static void _warn(String method, String reason) =>
      log('$method: $reason', name: 'reticle_gen', level: 900);

  XmlElement generate(SVGDrawerInterface drawer) {
    final double minX = -milWidth / 2;
    final double minY = -milHeight / 2;

    _svgElement = XmlElement(XmlName('svg'), [
      XmlAttribute(XmlName('xmlns'), 'http://www.w3.org/2000/svg'),
      XmlAttribute(XmlName('width'), _fmtNum(milWidth * factor)),
      XmlAttribute(XmlName('height'), _fmtNum(milHeight * factor)),
      XmlAttribute(
        XmlName('viewBox'),
        '${_fmtNum(minX)} ${_fmtNum(minY)} ${_fmtNum(milWidth)} ${_fmtNum(milHeight)}',
      ),
      XmlAttribute(XmlName('data-mil-width'), _fmtNum(milWidth)),
      XmlAttribute(XmlName('data-mil-height'), _fmtNum(milHeight)),
      XmlAttribute(XmlName('data-factor'), factor.toString()),
      XmlAttribute(XmlName('shape-rendering'), 'crispEdges'),
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
    final w = milWidth / unitScale;
    final h = milHeight / unitScale;
    rect(-w / 2, -h / 2, w, h, fill);
  }

  void circle(
    double cx,
    double cy,
    double r, {
    String? fill,
    String? stroke,
    double? strokeWidth,
  }) {
    _target.children.add(
      XmlElement(XmlName('circle'), [
        XmlAttribute(XmlName('id'), nextId('circle')),
        XmlAttribute(XmlName('cx'), _fmtNum(cx)),
        XmlAttribute(XmlName('cy'), _fmtNum(cy)),
        XmlAttribute(XmlName('r'), _fmtNum(r)),
        XmlAttribute(XmlName('fill'), fill ?? "none"),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), _fmtNum(strokeWidth)),
      ]),
    );
  }

  void path(
    String d,
    String fill, {
    String? stroke,
    double? strokeWidth,
    String? strokeLineJoin = 'miter', // Додайте цей параметр
    String? strokeLineCap = 'miter', // І цей для кінців ліній
  }) {
    _target.children.add(
      XmlElement(XmlName('path'), [
        XmlAttribute(XmlName('id'), nextId('path')),
        XmlAttribute(XmlName('d'), d),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), _fmtNum(strokeWidth)),
        if (strokeLineJoin != null)
          XmlAttribute(XmlName('stroke-linejoin'), strokeLineJoin),
        if (strokeLineCap != null)
          XmlAttribute(XmlName('stroke-linecap'), strokeLineCap),
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
          XmlAttribute(
            XmlName('font-size'),
            _fmtNum(fontSize / _capHeightRatio),
          ),
          XmlAttribute(XmlName('text-anchor'), textAnchor),
        ],
        [XmlText(content)],
      ),
    );
  }

  /// Draws [content] as a stroke-font (7-segment) label.
  ///
  /// [cx, cy] — center of the glyph bounding box in mils.
  /// [h] — glyph height (= visual cap-height) in mils.
  /// [sw] — stroke width in mils; defaults to h × 0.09.
  /// [anchor]: 'middle' = horizontal center at cx (default),
  ///           'start'  = left edge at cx,
  ///           'end'    = right edge at cx.
  void label(
    String content,
    double cx,
    double cy,
    String stroke, {
    double h = 1.0,
    double sw = 0.0,
    String anchor = 'middle',
  }) {
    final effectiveSw = sw > 0 ? sw : h * 0.09;
    final w = h * _StrokeFont.widthRatio;
    final gap = h * 0.15;
    final step = w + gap;

    final chars = content.split('').where(_StrokeFont.hasGlyph).toList();
    if (chars.isEmpty) return;

    final totalWidth = chars.length * w + (chars.length - 1) * gap;
    final startX = switch (anchor) {
      'start' => cx,
      'end' => cx - totalWidth,
      _ => cx - totalWidth / 2,
    };

    _hint('label');
    batchLines(
      stroke, // 1й аргумент: stroke
      effectiveSw, // 2й аргумент: strokeWidth
      (pb) {
        // 3й аргумент: build функція
        for (var i = 0; i < chars.length; i++) {
          _StrokeFont.drawGlyph(
            chars[i],
            startX + i * step,
            cy - h / 2,
            w,
            h,
            pb,
          );
        }
      },
      strokeLineJoin: 'round',
      strokeLineCap: 'round',
    );
  }

  /// Clips [draw] to the shape defined by [shape].
  /// Generates `<clipPath>` + `<g clip-path="url(#...)">` directly in SVG (no `<defs>`).
  void clip({
    required void Function(MilReticleSVGCanvas canvas) shape,
    required void Function(MilReticleSVGCanvas canvas) draw,
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
    circle(cx, cy, r, fill: fill, stroke: stroke, strokeWidth: strokeWidth);
  }

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

  void batchLines(
    String stroke,
    double strokeWidth,
    void Function(PathBuilder pb) build, {
    String fill = 'none',
    String? strokeLineJoin = 'miter', // Додайте цей параметр
    String? strokeLineCap = 'miter', // І цей для кінців ліній
  }) {
    final pb = PathBuilder();
    build(pb);
    if (!pb.isEmpty) {
      _hint('batch');
      path(
        pb.d,
        fill,
        stroke: stroke,
        strokeWidth: strokeWidth,
        strokeLineJoin: strokeLineJoin,
        strokeLineCap: strokeLineCap,
      );
    }
  }

  void drawAdjustment(double x, double y) {
    this
      ..line(x, 0, x, y, 'red', 0.05)
      ..line(0, y, x, y, 'red', 0.05)
      ..circle(x, y, 0.2, fill: 'red');
  }
}

class CrossDrawer implements SVGDrawerInterface {
  final double size;
  final double strokeWidth;
  final String color;

  CrossDrawer({this.size = 200, this.strokeWidth = 2, this.color = 'red'});

  @override
  void draw(MilReticleSVGCanvas canvas) {
    canvas
      ..line(-size / 2, 0, size / 2, 0, color, strokeWidth)
      ..line(0, -size / 2, 0, size / 2, color, strokeWidth);
  }
}

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
  void draw(MilReticleSVGCanvas canvas) {
    final diagLength = radius * 0.7;

    canvas
      ..circle(0, 0, radius, stroke: color, strokeWidth: strokeWidth)
      ..line(-lineLength / 2, 0, lineLength / 2, 0, color, strokeWidth)
      ..line(0, -lineLength / 2, 0, lineLength / 2, color, strokeWidth)
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
      ..circle(0, 0, strokeWidth * 2, fill: color);

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

class CompositeSVGDrawer extends SVGDrawerInterface {
  final List<SVGDrawerInterface> drawers;

  CompositeSVGDrawer(this.drawers);

  @override
  void draw(MilReticleSVGCanvas canvas) {
    for (var drawer in drawers) {
      drawer.draw(canvas);
    }
  }
}

class _CustomGalaxyDrawer extends SVGDrawerInterface {
  @override
  void draw(MilReticleSVGCanvas canvas) {
    final random = math.Random();

    canvas.rect(-400, -400, 800, 800, '#0a0a2a');

    for (double r = 20; r <= 300; r += 15) {
      final angle = r * 0.1;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);

      canvas.circle(x, y, 2, fill: 'white', stroke: 'cyan', strokeWidth: 0.5);

      final x2 = r * math.cos(angle + 3.14159);
      final y2 = r * math.sin(angle + 3.14159);
      canvas.circle(x2, y2, 2, fill: 'white', stroke: 'cyan', strokeWidth: 0.5);
    }

    for (int i = 0; i < 500; i++) {
      final x = random.nextDouble() * 700 - 350;
      final y = random.nextDouble() * 700 - 350;
      final brightness = random.nextDouble() * 0.5 + 0.5;
      final size = random.nextDouble() * 2 + 0.5;

      canvas.circle(x, y, size, fill: 'rgba(255,255,255,$brightness)');
    }

    for (int i = 0; i < 100; i++) {
      final angle = random.nextDouble() * 2 * 3.14159;
      final r = random.nextDouble() * 30;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      canvas.circle(
        x,
        y,
        random.nextDouble() * 3 + 1,
        fill: 'rgba(255,200,100, ${random.nextDouble() * 0.8 + 0.2})',
      );
    }
  }
}

void main() {
  print('Creating an SVG with a simple cross...');
  final crossDrawer = CrossDrawer(size: 300, strokeWidth: 3, color: '#FF0000');
  MilReticleSVGCanvas(milWidth: 640, milHeight: 640, factor: 1)
    ..generate(crossDrawer)
    ..svg.export('cross.svg');

  print('Creating an SVG with a scope...');
  final scopeDrawer = ScopeDrawer(
    radius: 200,
    lineLength: 350,
    strokeWidth: 2,
    color: '#00FF00',
  );
  MilReticleSVGCanvas(milWidth: 640, milHeight: 640, factor: 1)
    ..generate(scopeDrawer)
    ..svg.export('scope.svg');

  print('Creating an SVG with a combined image...');
  final combinedDrawer = CompositeSVGDrawer([
    ScopeDrawer(
      radius: 250,
      lineLength: 450,
      strokeWidth: 1.5,
      color: '#FF6600',
    ),
    CrossDrawer(size: 100, strokeWidth: 1, color: '#FFFFFF'),
  ]);
  MilReticleSVGCanvas(milWidth: 640, milHeight: 640, factor: 1)
    ..generate(combinedDrawer)
    ..svg.export('combined.svg');

  print('Creating an SVG with a custom image...');
  final customDrawer = _CustomGalaxyDrawer();
  MilReticleSVGCanvas(milWidth: 800, milHeight: 800, factor: 1)
    ..generate(customDrawer)
    ..svg.export('galaxy.svg');

  print('All SVG files created successfully!');
  print('- cross.svg');
  print('- scope.svg');
  print('- combined.svg');
  print('- galaxy.svg');
}
