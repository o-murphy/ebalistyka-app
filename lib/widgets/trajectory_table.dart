import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';

import '../viewmodels/shared/formatted_row.dart';
import '../viewmodels/tables_vm.dart';

// ─── Trajectory Table ─────────────────────────────────────────────────────────
//
// Layout: rows = metrics (Time, V, Height, ...), columns = trajectory distances.
// The distance header row sticks to the top; columns scroll horizontally.

class TrajectoryTable extends StatefulWidget {
  final FormattedTableData mainTable;
  final FormattedTableData? zeroCrossings;
  final TablesSpoilerData spoiler;

  const TrajectoryTable({
    super.key,
    required this.mainTable,
    this.zeroCrossings,
    required this.spoiler,
  });

  @override
  State<TrajectoryTable> createState() => _TrajectoryTableState();
}

class _TrajectoryTableState extends State<TrajectoryTable> {
  final _trajHdrCtrl  = ScrollController();
  final _trajDataCtrl = ScrollController();
  bool _syncingH = false;

  @override
  void initState() {
    super.initState();
    _trajDataCtrl.addListener(_onDataScroll);
    _trajHdrCtrl.addListener(_onHdrScroll);
  }

  void _onDataScroll() {
    if (_syncingH || !_trajHdrCtrl.hasClients || !_trajDataCtrl.hasClients) return;
    _syncingH = true;
    _trajHdrCtrl.jumpTo(_trajDataCtrl.offset);
    _syncingH = false;
  }

  void _onHdrScroll() {
    if (_syncingH || !_trajDataCtrl.hasClients || !_trajHdrCtrl.hasClients) return;
    _syncingH = true;
    _trajDataCtrl.jumpTo(_trajHdrCtrl.offset);
    _syncingH = false;
  }

  @override
  void dispose() {
    _trajDataCtrl.removeListener(_onDataScroll);
    _trajHdrCtrl.removeListener(_onHdrScroll);
    _trajDataCtrl.dispose();
    _trajHdrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final table = widget.mainTable;

    const colPad  = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    const labelW  = 72.0;
    const colW    = 72.0;

    final hdrStyle      = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface);
    final subStyle      = theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);
    final cellStyle     = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final zeroCellStyle = cellStyle?.copyWith(color: cs.error, fontWeight: FontWeight.bold);
    final subsCellStyle = cellStyle?.copyWith(color: cs.tertiary, fontWeight: FontWeight.bold);
    final zeroBannerStyle = theme.textTheme.bodySmall?.copyWith(
        color: cs.primary, fontWeight: FontWeight.bold, fontFamily: 'monospace');
    final labelStyle    = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface);
    final unitLabelStyle = theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);

    // ── Helpers ──────────────────────────────────────────────────────────────

    Widget hCell(String text, TextStyle? style, {double width = colW}) => SizedBox(
      width: width,
      child: Padding(
        padding: colPad,
        child: Text(text, style: style, textAlign: TextAlign.right),
      ),
    );

    Widget dCell(String text, TextStyle? style, {Color? bg, VoidCallback? onTap}) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: colW,
            color: bg,
            padding: colPad,
            child: Text(text, style: style, textAlign: TextAlign.right),
          ),
        );

    Widget labelCell(String label, String unit) => SizedBox(
      width: labelW,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            Text(unit, style: unitLabelStyle),
          ],
        ),
      ),
    );

    Widget rowDivider() => Divider(height: 1, color: cs.outlineVariant, thickness: 0.5);

    // ── Section title ─────────────────────────────────────────────────────────

    Widget sectionTitle(String text) => Container(
      color: cs.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onSurface.withAlpha(160),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );

    // ── Detail dialog ─────────────────────────────────────────────────────────

    void showDetail(FormattedTableData t, int colIndex) => showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(
            'Range: ${colIndex < t.distanceHeaders.length ? t.distanceHeaders[colIndex] : "—"} ${t.distanceUnit}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: t.rows.map((row) => ListTile(
              dense: true,
              title: Text('${row.label}  (${row.unitSymbol})'),
              trailing: Text(
                colIndex < row.cells.length ? row.cells[colIndex].value : '—',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            )).toList(),
          ),
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(dlgCtx),
          child: const Text('Close'),
        )],
      ),
    );

    // ── Single table renderer ─────────────────────────────────────────────────

    Widget buildTable(FormattedTableData t, {bool isZero = false}) {
      final nCols = t.distanceHeaders.length;
      final totalW = labelW + colW * nCols;

      // Distance header row
      Widget headerRow() => Container(
        color: cs.surfaceContainerHighest,
        child: Row(
          children: [
            SizedBox(
              width: labelW,
              child: Padding(
                padding: colPad,
                child: Text(t.distanceUnit, style: subStyle),
              ),
            ),
            ...List.generate(nCols, (ci) => hCell(t.distanceHeaders[ci],
                isZero ? zeroBannerStyle : hdrStyle)),
          ],
        ),
      );

      // Data rows
      Widget dataRows() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var ri = 0; ri < t.rows.length; ri++) ...[
            if (ri > 0) rowDivider(),
            GestureDetector(
              onTap: null, // row tap shows nothing; tap cells for detail
              child: Row(
                children: [
                  labelCell(t.rows[ri].label, t.rows[ri].unitSymbol),
                  ...List.generate(
                    min(nCols, t.rows[ri].cells.length),
                    (ci) {
                      final cell = t.rows[ri].cells[ci];
                      final isZ  = cell.isZeroCrossing;
                      final isS  = cell.isSubsonic;
                      final bg   = isZ
                          ? cs.errorContainer.withAlpha(80)
                          : isS
                              ? cs.tertiaryContainer.withAlpha(80)
                              : (ci.isEven ? null : cs.surfaceContainerLowest);
                      final style = isZ ? zeroCellStyle : isS ? subsCellStyle : cellStyle;
                      return dCell(cell.value, style,
                          bg: bg, onTap: () => showDetail(t, ci));
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      );

      Widget hScroll(Widget child, {ScrollController? ctrl}) =>
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: ctrl,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: totalW),
              child: child,
            ),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StickyHeader(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hScroll(headerRow(), ctrl: _trajHdrCtrl),
                Divider(height: 1, color: cs.outlineVariant, thickness: 0.5),
              ],
            ),
            content: hScroll(dataRows(), ctrl: _trajDataCtrl),
          ),
        ],
      );
    }

    // ── Layout ────────────────────────────────────────────────────────────────

    return ListView(
      children: [
        // 1. Details spoiler
        _DetailsSpoiler(spoiler: widget.spoiler),

        // 2. Zero crossings
        if (widget.zeroCrossings != null &&
            widget.zeroCrossings!.distanceHeaders.isNotEmpty) ...[
          sectionTitle('Zero Crossings'),
          buildTable(widget.zeroCrossings!, isZero: true),
        ],

        // 3. Main trajectory table
        sectionTitle('Trajectory'),
        buildTable(table),
      ],
    );
  }
}

// ─── Details spoiler ──────────────────────────────────────────────────────────

class _DetailsSpoiler extends StatelessWidget {
  const _DetailsSpoiler({required this.spoiler});

  final TablesSpoilerData spoiler;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;

    final labelStyle   = theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final valueStyle   = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: cs.onSurface);
    final sectionStyle = theme.textTheme.labelSmall?.copyWith(
        color: cs.primary, fontWeight: FontWeight.w700, letterSpacing: 0.6);

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: labelStyle)),
        Text(value, style: valueStyle),
      ]),
    );

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Text(title.toUpperCase(), style: sectionStyle),
    );

    final items = <Widget>[];

    // Rifle
    final hasRifle = spoiler.caliber != null || spoiler.twist != null;
    if (hasRifle) {
      items.add(section('Rifle'));
      items.add(row('Name', spoiler.rifleName));
      if (spoiler.caliber    != null) items.add(row('Caliber', spoiler.caliber!));
      if (spoiler.twist      != null) items.add(row('Twist',   spoiler.twist!));
    }

    // Projectile
    final hasProj = spoiler.dragModel != null || spoiler.bc != null ||
        spoiler.zeroMv != null || spoiler.currentMv != null ||
        spoiler.zeroDist != null || spoiler.bulletLen != null ||
        spoiler.bulletDiam != null || spoiler.bulletWeight != null ||
        spoiler.formFactor != null || spoiler.sectionalDensity != null ||
        spoiler.gyroStability != null;
    if (hasProj) {
      items.add(section('Projectile'));
      if (spoiler.dragModel       != null) items.add(row('Drag model',         spoiler.dragModel!));
      if (spoiler.bc              != null) items.add(row('BC',                 spoiler.bc!));
      if (spoiler.zeroMv          != null) items.add(row('Zero MV',            spoiler.zeroMv!));
      if (spoiler.currentMv       != null) items.add(row('Current MV',         spoiler.currentMv!));
      if (spoiler.zeroDist        != null) items.add(row('Zero distance',       spoiler.zeroDist!));
      if (spoiler.bulletLen       != null) items.add(row('Length',             spoiler.bulletLen!));
      if (spoiler.bulletDiam      != null) items.add(row('Diameter',           spoiler.bulletDiam!));
      if (spoiler.bulletWeight    != null) items.add(row('Weight',             spoiler.bulletWeight!));
      if (spoiler.formFactor      != null) items.add(row('Form factor',        spoiler.formFactor!));
      if (spoiler.sectionalDensity != null) items.add(row('Sectional density', spoiler.sectionalDensity!));
      if (spoiler.gyroStability   != null) items.add(row('Gyrostability (Sg)', spoiler.gyroStability!));
    }

    // Atmosphere
    final hasAtmo = spoiler.temperature != null || spoiler.humidity != null ||
        spoiler.pressure != null || spoiler.windSpeed != null || spoiler.windDir != null;
    if (hasAtmo) {
      items.add(section('Atmosphere'));
      if (spoiler.temperature != null) items.add(row('Temperature',    spoiler.temperature!));
      if (spoiler.humidity    != null) items.add(row('Humidity',       spoiler.humidity!));
      if (spoiler.pressure    != null) items.add(row('Pressure',       spoiler.pressure!));
      if (spoiler.windSpeed   != null) items.add(row('Wind speed',     spoiler.windSpeed!));
      if (spoiler.windDir     != null) items.add(row('Wind direction', spoiler.windDir!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text('Shot details',
            style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        backgroundColor: cs.surfaceContainerLowest,
        collapsedBackgroundColor: cs.surfaceContainerLowest,
        children: items,
      ),
    );
  }
}
