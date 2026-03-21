import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:test_app/src/conditions.dart';
import 'package:test_app/src/unit.dart';
import 'package:test_app/src/ffi/bclibc_ffi.dart';
import 'package:test_app/src/ffi/bclibc_bindings.g.dart' show BCTrajFlag;

// ─── G7 standard drag table (Pejsa / py_ballisticcalc TableG7) ──────────────
const _g7 = [
  (0.000, 0.1198), (0.050, 0.1197), (0.100, 0.1196), (0.150, 0.1194),
  (0.200, 0.1193), (0.250, 0.1194), (0.300, 0.1194), (0.350, 0.1194),
  (0.400, 0.1193), (0.450, 0.1193), (0.500, 0.1194), (0.550, 0.1193),
  (0.600, 0.1194), (0.650, 0.1197), (0.700, 0.1202), (0.725, 0.1207),
  (0.750, 0.1215), (0.775, 0.1226), (0.800, 0.1242), (0.825, 0.1266),
  (0.850, 0.1306), (0.875, 0.1368), (0.900, 0.1464), (0.925, 0.1660),
  (0.950, 0.2054), (0.975, 0.2993), (1.000, 0.3803), (1.025, 0.4015),
  (1.050, 0.4043), (1.075, 0.4034), (1.100, 0.4014), (1.150, 0.3955),
  (1.200, 0.3884), (1.300, 0.3750), (1.400, 0.3618), (1.500, 0.3498),
  (1.600, 0.3388), (1.800, 0.3189), (2.000, 0.3018), (2.200, 0.2873),
  (2.400, 0.2744), (2.600, 0.2635), (2.800, 0.2540), (3.000, 0.2456),
];

// ─── Unit helpers ─────────────────────────────────────────────────────────────
const _ftToM   = 1.0 / 3.28084;  // ft → m
const _ftToCm  = 30.48;           // ft → cm
const _fpsToms = 1.0 / 3.28084;  // fps → m/s
const _ftLbToJ = 1.35582;         // ft·lb → J

BcAtmosphere _bcAtmo(Atmo a) => BcAtmosphere(
  t0:           a.temperature.in_(Unit.celsius),
  a0:           a.altitude.in_(Unit.foot),
  p0:           a.pressure.in_(Unit.hPa),
  mach:         a.mach.in_(Unit.fps),
  densityRatio: a.densityRatio,
  cLowestTempC: Atmo.cLowestTempC,
);

// ─── Shot setup: mirrors the Python example ───────────────────────────────────
//   weight=300gr, diameter=0.338", length=1.7", BC G7=0.381
//   MV=815 m/s, sight=9 cm, twist=10"
//   Zero: 150 m alt, 745 mmHg, -1°C, 78% → 100 m
//   Current: 150 m alt, 992 hPa, 23°C, 29%
//   Fire: 1000 m, step 100 m

List<BcTrajectoryData> _runCalc() {
  final bc = BcLibC.open();

  final zeroAtmo = Atmo(
    altitude:    Unit.meter(150),
    pressure:    Unit.mmHg(745),
    temperature: Unit.celsius(-1),
    humidity:    78,
  );
  final curAtmo = Atmo(
    altitude:    Unit.meter(150),
    pressure:    Unit.hPa(992),
    temperature: Unit.celsius(23),
    humidity:    29,
  );

  final dragTable = _g7.map((p) => BcDragPoint(p.$1, p.$2)).toList();

  const mvFps   = 815.0 * 3.28084; // 2673.88 fps
  const sightFt = 9.0 / 30.48;     // 9 cm → ft

  BcShotProps makeProps({
    required BcAtmosphere atmo,
    required double barrelElevationRad,
  }) => BcShotProps(
    bc:                  0.381,
    lookAngleRad:        0.0,
    twistInch:           10.0,
    lengthInch:          1.7,
    diameterInch:        0.338,
    weightGrain:         300.0,
    barrelElevationRad:  barrelElevationRad,
    barrelAzimuthRad:    0.0,
    sightHeightFt:       sightFt,
    alt0Ft:              atmo.a0,
    muzzleVelocityFps:   mvFps,
    atmo:                atmo,
    coriolis:            const BcCoriolis(),
    dragTable:           dragTable,
  );

  // 1. Find zero angle (100 m)
  final zeroAngle = bc.findZeroAngle(
    makeProps(atmo: _bcAtmo(zeroAtmo), barrelElevationRad: 0.0),
    100.0 * 3.28084,
  );

  // 2. Integrate trajectory (1000 m, step 100 m)
  final result = bc.integrate(
    makeProps(atmo: _bcAtmo(curAtmo), barrelElevationRad: zeroAngle),
    BcTrajectoryRequest(
      rangeLimitFt: 1000.0 * 3.28084,
      rangeStepFt:  100.0  * 3.28084,
      filterFlags:  BCTrajFlag.BC_TRAJ_FLAG_RANGE,
    ),
  );

  return result.trajectory;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});
  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  List<BcTrajectoryData>? _traj;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  Future<void> _calculate() async {
    setState(() { _loading = true; _error = null; _traj = null; });
    try {
      final traj = await Future(_runCalc);
      if (mounted) setState(() { _traj = traj; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _calculate, child: const Text('Retry')),
        ]),
      );
    }
    if (_traj == null) return const SizedBox.shrink();

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: LayoutBuilder(builder: (context, constraints) {
      const chartH = 300.0;
      return SingleChildScrollView(            // ← вся сторінка скролиться вертикально
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(                          // ← графік: повна ширина, фіксована висота
              width: constraints.maxWidth,
              height: chartH,
              child: _TrajectoryChart(traj: _traj!),
            ),
            const Divider(height: 1),
            _TrajectoryTable(traj: _traj!, availableWidth: constraints.maxWidth),
          ],
        ),
      );
    }),
    );
  }
}

// ─── Chart ────────────────────────────────────────────────────────────────────

class _TrajectoryChart extends StatelessWidget {
  final List<BcTrajectoryData> traj;
  const _TrajectoryChart({required this.traj});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _ChartPainter(
          traj:        traj,
          heightColor: cs.primary,
          velColor:    Colors.green.shade600,
          gridColor:   cs.outlineVariant,
          textColor:   cs.onSurface,
        ),
        child: const SizedBox.expand(), // дає CustomPaint розмір батька
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<BcTrajectoryData> traj;
  final Color heightColor, velColor, gridColor, textColor;

  // margins
  static const _ml = 52.0, _mr = 56.0, _mt = 20.0, _mb = 36.0;

  _ChartPainter({
    required this.traj,
    required this.heightColor,
    required this.velColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pw = size.width  - _ml - _mr;
    final ph = size.height - _mt - _mb;

    // Data ranges
    final heights = traj.map((r) => r.heightFt * _ftToCm).toList();
    final vels    = traj.map((r) => r.velocityFps * _fpsToms).toList();
    final dists   = traj.map((r) => r.distanceFt * _ftToM).toList();

    final xMin = dists.first, xMax = dists.last;
    final yHMin = (heights.reduce(math.min) * 1.1).floorToDouble();
    final yHMax = (heights.reduce(math.max) * 1.1).ceilToDouble();
    final yVMin = 0.0;
    final yVMax = (vels.reduce(math.max) * 1.05).ceilToDouble();

    double px(double d) => _ml + (d - xMin) / (xMax - xMin) * pw;
    double pyH(double h) => _mt + (1 - (h - yHMin) / (yHMax - yHMin)) * ph;
    double pyV(double v) => _mt + (1 - (v - yVMin) / (yVMax - yVMin)) * ph;

    final gridP = Paint()..color = gridColor..strokeWidth = 0.5;
    final zeroP = Paint()
      ..color = Colors.orange.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    (zeroP as dynamic); // cast silence

    final ts = TextStyle(fontSize: 9, color: textColor.withAlpha(180));
    final tsR = TextStyle(fontSize: 9, color: velColor.withAlpha(200));

    // Grid X (every 100 m)
    for (var d = xMin; d <= xMax + 0.1; d += 100) {
      final x = px(d);
      canvas.drawLine(Offset(x, _mt), Offset(x, _mt + ph), gridP);
      _text(canvas, '${d.toInt()}', Offset(x, _mt + ph + 3), ts, center: true);
    }

    // Grid Y left (height, every round step)
    final hStep = _niceStep(yHMax - yHMin, 5);
    for (var h = (yHMin / hStep).ceil() * hStep; h <= yHMax + 0.01; h += hStep) {
      final y = pyH(h);
      canvas.drawLine(Offset(_ml, y), Offset(_ml + pw, y), gridP);
      _text(canvas, h.toStringAsFixed(0), Offset(2, y - 5), ts);
    }

    // Grid Y right (velocity)
    final vStep = _niceStep(yVMax, 5);
    for (var v = 0.0; v <= yVMax + 0.01; v += vStep) {
      _text(canvas, v.toStringAsFixed(0), Offset(_ml + pw + 3, pyV(v) - 5), tsR);
    }

    // Zero reference line
    final zeroY = pyH(0);
    canvas.drawLine(
      Offset(_ml, zeroY), Offset(_ml + pw, zeroY),
      Paint()
        ..color = Colors.orange.shade400
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    // Velocity line
    _drawLine(canvas, dists, vels, px, pyV, velColor, 1.5, dashed: true);

    // Height line (on top)
    _drawLine(canvas, dists, heights, px, pyH, heightColor, 2.0);

    // Border
    canvas.drawRect(
      Rect.fromLTWH(_ml, _mt, pw, ph),
      Paint()..color = textColor.withAlpha(80)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // Axis labels
    _text(canvas, 'Distance (m)', Offset(_ml + pw / 2, size.height - 2),
        TextStyle(fontSize: 10, color: textColor), center: true);
    _textRotated(canvas, 'Height (cm)',
        Offset(10, _mt + ph / 2), TextStyle(fontSize: 10, color: heightColor));
    _textRotated(canvas, 'Velocity (m/s)',
        Offset(size.width - 10, _mt + ph / 2), TextStyle(fontSize: 10, color: velColor),
        rightAligned: true);

    // Legend
    _drawLegendItem(canvas, Offset(_ml + 8, _mt + 8), heightColor, 'Height');
    _drawLegendItem(canvas, Offset(_ml + 80, _mt + 8), velColor, 'Velocity', dashed: true);
    _drawLegendItem(canvas, Offset(_ml + 160, _mt + 8), Colors.orange.shade400, 'Zero line');
  }

  void _drawLine(
    Canvas canvas,
    List<double> xs,
    List<double> ys,
    double Function(double) px,
    double Function(double) py,
    Color color,
    double width, {
    bool dashed = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    if (!dashed) {
      final path = Path();
      for (var i = 0; i < xs.length; i++) {
        final p = Offset(px(xs[i]), py(ys[i]));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    } else {
      // Proper pixel dashes: walk along the polyline in fixed-length steps
      const dashLen = 8.0;
      const gapLen  = 5.0;
      bool drawing = true;
      double remaining = dashLen;
      for (var i = 0; i < xs.length - 1; i++) {
        var a = Offset(px(xs[i]), py(ys[i]));
        final b = Offset(px(xs[i + 1]), py(ys[i + 1]));
        var seg = (b - a).distance;
        while (seg > 0) {
          final step = math.min(seg, remaining);
          final frac = step / seg;
          final c = Offset(a.dx + (b.dx - a.dx) * frac, a.dy + (b.dy - a.dy) * frac);
          if (drawing) canvas.drawLine(a, c, paint);
          remaining -= step;
          seg -= step;
          a = c;
          if (remaining <= 0) {
            drawing = !drawing;
            remaining = drawing ? dashLen : gapLen;
          }
        }
      }
    }
  }

  void _drawLegendItem(Canvas canvas, Offset pos, Color color, String label,
      {bool dashed = false}) {
    canvas.drawLine(
      pos, pos.translate(24, 0),
      Paint()..color = color..strokeWidth = dashed ? 1.5 : 2.0..style = PaintingStyle.stroke,
    );
    _text(canvas, label, pos.translate(28, -5),
        TextStyle(fontSize: 9, color: color));
  }

  void _text(Canvas c, String t, Offset o, TextStyle s, {bool center = false}) {
    final tp = TextPainter(
        text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, center ? o.translate(-tp.width / 2, 0) : o);
  }

  void _textRotated(Canvas c, String t, Offset center, TextStyle s,
      {bool rightAligned = false}) {
    final tp = TextPainter(
        text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)
      ..layout();
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rightAligned ? math.pi / 2 : -math.pi / 2);
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
  }

  double _niceStep(double range, int targetSteps) {
    final rough = range / targetSteps;
    final magnitude = math.pow(10, (math.log(rough) / math.ln10).floor());
    final normalized = rough / magnitude;
    double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude.toDouble();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.traj != traj;
}

// ─── Table ────────────────────────────────────────────────────────────────────

class _TrajectoryTable extends StatelessWidget {
  final List<BcTrajectoryData> traj;
  final double availableWidth;
  const _TrajectoryTable({required this.traj, required this.availableWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Find "zero row" = smallest |slantHeight|
    int zeroIdx = 0;
    double minAbs = 1e9;
    for (var i = 0; i < traj.length; i++) {
      final a = traj[i].slantHeightFt.abs();
      if (a < minAbs) { minAbs = a; zeroIdx = i; }
    }

    final hdr = theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold, color: cs.onSurface);
    final sub = theme.textTheme.bodySmall?.copyWith(
        color: cs.onSurfaceVariant);
    final cell = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final zeroCell = cell?.copyWith(color: cs.error, fontWeight: FontWeight.bold);

    final cols = [
      ('Time',   's'),
      ('Range',  'm'),
      ('V',      'm/s'),
      ('Height', 'cm'),
      ('Drop',   'cm'),
      ('Adj',    'mil'),
      ('Wind',   'cm'),
      ('W.Adj',  'mil'),
      ('Mach',   ''),
      ('Density',''),
      ('Drag',   ''),
      ('Energy', 'J'),
    ];

    List<String> rowData(BcTrajectoryData r) => [
      r.time.toStringAsFixed(3),
      (r.distanceFt * _ftToM).toStringAsFixed(0),
      (r.velocityFps * _fpsToms).toStringAsFixed(0),
      (r.heightFt * _ftToCm).toStringAsFixed(1),
      (r.slantHeightFt * _ftToCm).toStringAsFixed(1),
      (r.dropAngleRad * 1000).toStringAsFixed(2),
      (r.windageFt * _ftToCm).toStringAsFixed(1),
      (r.windageAngleRad * 1000).toStringAsFixed(2),
      r.mach.toStringAsFixed(2),
      r.densityRatio.toStringAsFixed(3),
      r.drag.toStringAsFixed(4),
      (r.energyFtLb * _ftLbToJ).toStringAsFixed(0),
    ];

    List<TableRow> rows() => [
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHighest),
        children: cols.map((c) => _cell(c.$1, hdr)).toList(),
      ),
      TableRow(
        decoration: BoxDecoration(color: cs.surfaceContainerHigh),
        children: cols.map((c) => _cell(c.$2, sub)).toList(),
      ),
      for (var i = 0; i < traj.length; i++)
        TableRow(
          decoration: BoxDecoration(
            color: i == zeroIdx
                ? cs.errorContainer.withAlpha(80)
                : (i.isEven ? null : cs.surfaceContainerLowest),
          ),
          children: rowData(traj[i])
              .map((v) => _cell(v, i == zeroIdx ? zeroCell : cell))
              .toList(),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: availableWidth),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(flex: 1.0),
          border: TableBorder.all(color: cs.outlineVariant, width: 0.5),
          children: rows(),
        ),
      ),
    );
  }

  Widget _cell(String text, TextStyle? style) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(text, style: style, textAlign: TextAlign.right),
      );
}
