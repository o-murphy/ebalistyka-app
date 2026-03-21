import 'package:flutter/material.dart';
import 'package:test_app/src/ffi/bclibc_ffi.dart';

const _ftToM   = 1.0 / 3.28084;
const _ftToCm  = 30.48;
const _fpsToms = 1.0 / 3.28084;
const _ftLbToJ = 1.35582;

class TrajectoryTable extends StatelessWidget {
  final List<BcTrajectoryData> traj;
  final double availableWidth;

  const TrajectoryTable({
    super.key,
    required this.traj,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Highlight the row closest to zero height
    int zeroIdx = 0;
    double minAbs = 1e9;
    for (var i = 0; i < traj.length; i++) {
      final a = traj[i].slantHeightFt.abs();
      if (a < minAbs) { minAbs = a; zeroIdx = i; }
    }

    final hdr      = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface);
    final sub      = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final cell     = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final zeroCell = cell?.copyWith(color: cs.error, fontWeight: FontWeight.bold);

    const cols = [
      ('Time',    's'),
      ('Range',   'm'),
      ('V',       'm/s'),
      ('Height',  'cm'),
      ('Drop',    'cm'),
      ('Adj',     'mil'),
      ('Wind',    'cm'),
      ('W.Adj',   'mil'),
      ('Mach',    ''),
      ('Density', ''),
      ('Drag',    ''),
      ('Energy',  'J'),
    ];

    List<String> rowData(BcTrajectoryData r) => [
      r.time.toStringAsFixed(3),
      (r.distanceFt  * _ftToM).toStringAsFixed(0),
      (r.velocityFps * _fpsToms).toStringAsFixed(0),
      (r.heightFt    * _ftToCm).toStringAsFixed(1),
      (r.slantHeightFt * _ftToCm).toStringAsFixed(1),
      (r.dropAngleRad    * 1000).toStringAsFixed(2),
      (r.windageFt   * _ftToCm).toStringAsFixed(1),
      (r.windageAngleRad * 1000).toStringAsFixed(2),
      r.mach.toStringAsFixed(2),
      r.densityRatio.toStringAsFixed(3),
      r.drag.toStringAsFixed(4),
      (r.energyFtLb  * _ftLbToJ).toStringAsFixed(0),
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
