import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _kMultiBcRowCount = 5;
const _kDragTableRowCount = 100;

// ── Multi-BC editor ───────────────────────────────────────────────────────────

/// Multi-BC breakpoint table editor for G1/G7 drag models.
///
/// Returns `List<({double vMps, double bc})>` via [context.pop]:
///   - empty list → table cleared
///   - null       → discarded (no change)
class MultiBcEditorScreen extends ConsumerWidget {
  const MultiBcEditorScreen({
    required this.dragType,
    this.initialTable,
    this.initialMvMps,
    this.initialBc,
    super.key,
  });

  final DragType dragType;

  /// Existing breakpoints to pre-fill. null/empty → auto-fill from [initialMvMps]/[initialBc].
  final List<({double vMps, double bc})>? initialTable;

  /// Current ammo MV in m/s — used for auto-fill when [initialTable] is empty.
  final double? initialMvMps;

  /// Current single BC value — used for auto-fill when [initialTable] is empty.
  final double? initialBc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final velocityUnit = ref.watch(unitSettingsProvider).velocityUnit;
    final vAcc = FC.muzzleVelocity.accuracyFor(velocityUnit);
    final dtName = dragType.name.toUpperCase();

    final table = initialTable;
    final isEmpty = table == null || table.isEmpty;
    // Local vars for Dart nullable field promotion
    final mvMps = initialMvMps;
    final bc = initialBc;

    List<(String, String)>? initialRows;
    if (isEmpty && mvMps != null && mvMps > 0 && bc != null && bc > 0) {
      final vDisplay = Velocity.mps(mvMps).in_(velocityUnit);
      initialRows = [(vDisplay.toStringAsFixed(vAcc), bc.toStringAsFixed(3))];
    } else if (!isEmpty) {
      initialRows = table!.map((r) {
        final vDisplay = Velocity.mps(r.vMps).in_(velocityUnit);
        return (vDisplay.toStringAsFixed(vAcc), r.bc.toStringAsFixed(3));
      }).toList();
    }

    return _TwoColumnTableEditorScreen(
      title: '$dtName Multi-BC Table',
      rowCount: _kMultiBcRowCount,
      col1Header: 'V (${velocityUnit.symbol})',
      col2Header: 'BC (fraction)',
      col1Hint: '0',
      col2Hint: '0.000',
      initialRows: initialRows,
      sortAscending: false,
      readOnly: false,
      onSave: (rows) {
        final result = rows
            .map(
              (r) =>
                  (vMps: Velocity(r.$1, velocityUnit).in_(Unit.mps), bc: r.$2),
            )
            .toList();
        context.pop<List<({double vMps, double bc})>>(result);
      },
      onDiscard: () => context.pop(null),
    );
  }
}

// ── Custom Drag Table editor ──────────────────────────────────────────────────

/// Custom drag table (Mach / Cd) editor.
///
/// [readOnly] defaults to `true` — set to `false` to enable editing.
///
/// Returns `List<({double mach, double cd})>` via [context.pop]:
///   - empty list → table cleared
///   - null       → discarded (no change)
class CustomDragTableEditorScreen extends StatelessWidget {
  const CustomDragTableEditorScreen({
    this.initialTable,
    this.readOnly = true,
    super.key,
  });

  final List<({double mach, double cd})>? initialTable;

  /// When `true` (default), fields are non-editable and only a Close button
  /// is shown. Set to `false` to allow editing.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final initialRows = initialTable
        ?.map((r) => (r.mach.toStringAsFixed(2), r.cd.toStringAsFixed(4)))
        .toList();

    return _TwoColumnTableEditorScreen(
      title: 'Custom Drag Table',
      rowCount: _kDragTableRowCount,
      col1Header: 'Mach',
      col2Header: 'Cd',
      col1Hint: '0.00',
      col2Hint: '0.0000',
      initialRows: initialRows,
      sortAscending: true,
      readOnly: readOnly,
      onSave: (rows) {
        final result = rows.map((r) => (mach: r.$1, cd: r.$2)).toList();
        context.pop<List<({double mach, double cd})>>(result);
      },
      onDiscard: () => context.pop(null),
    );
  }
}

// ── Internal shared screen ────────────────────────────────────────────────────

class _TwoColumnTableEditorScreen extends StatefulWidget {
  const _TwoColumnTableEditorScreen({
    required this.title,
    required this.rowCount,
    required this.col1Header,
    required this.col2Header,
    required this.col1Hint,
    required this.col2Hint,
    required this.sortAscending,
    required this.readOnly,
    required this.onSave,
    required this.onDiscard,
    this.initialRows,
  });

  final String title;
  final int rowCount;
  final String col1Header;
  final String col2Header;
  final String col1Hint;
  final String col2Hint;

  /// Pre-formatted string pairs. State is initialised once; subsequent
  /// widget updates (e.g. unit change) do NOT reset the controllers.
  final List<(String, String)>? initialRows;

  /// `true`  → sort col1 ascending  (Mach for drag table)
  /// `false` → sort col1 descending (velocity for Multi-BC)
  final bool sortAscending;

  final bool readOnly;
  final void Function(List<(double, double)>) onSave;
  final VoidCallback onDiscard;

  @override
  State<_TwoColumnTableEditorScreen> createState() =>
      _TwoColumnTableEditorScreenState();
}

class _TwoColumnTableEditorScreenState
    extends State<_TwoColumnTableEditorScreen> {
  late final List<TextEditingController> _col1Ctrls;
  late final List<TextEditingController> _col2Ctrls;

  @override
  void initState() {
    super.initState();
    _col1Ctrls = List.generate(widget.rowCount, (_) => TextEditingController());
    _col2Ctrls = List.generate(widget.rowCount, (_) => TextEditingController());

    final rows = widget.initialRows;
    if (rows != null) {
      final count = rows.length.clamp(0, widget.rowCount);
      for (var i = 0; i < count; i++) {
        _col1Ctrls[i].text = rows[i].$1;
        _col2Ctrls[i].text = rows[i].$2;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _col1Ctrls) {
      c.dispose();
    }
    for (final c in _col2Ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleSave() {
    final rows = <(double, double)>[];
    for (var i = 0; i < widget.rowCount; i++) {
      final v1 = double.tryParse(_col1Ctrls[i].text.trim()) ?? 0.0;
      final v2 = double.tryParse(_col2Ctrls[i].text.trim()) ?? 0.0;
      if (v1 <= 0 || v2 <= 0) continue;
      rows.add((v1, v2));
    }
    if (widget.sortAscending) {
      rows.sort((a, b) => a.$1.compareTo(b.$1));
    } else {
      rows.sort((a, b) => b.$1.compareTo(a.$1));
    }
    widget.onSave(rows);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.title,
      isSubscreen: true,
      showBack: false,
      bottomBar: _ActionBar(
        readOnly: widget.readOnly,
        onDiscard: widget.onDiscard,
        onSave: widget.readOnly ? null : _handleSave,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _Header(col1: widget.col1Header, col2: widget.col2Header),
          const Divider(height: 16),
          for (var i = 0; i < widget.rowCount; i++) ...[
            _RowEditor(
              index: i,
              col1Ctrl: _col1Ctrls[i],
              col2Ctrl: _col2Ctrls[i],
              col1Hint: widget.col1Hint,
              col2Hint: widget.col2Hint,
              readOnly: widget.readOnly,
            ),
            if (i < widget.rowCount - 1) const SizedBox(height: 8),
          ],
          if (!widget.readOnly) ...[
            const SizedBox(height: 16),
            Text(
              'Rows where any value is 0 are ignored on save.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.col1, required this.col2});
  final String col1;
  final String col2;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        const SizedBox(width: 32), // aligns with row-number gutter
        Expanded(
          child: Text(col1, style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(col2, style: style, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _RowEditor extends StatelessWidget {
  const _RowEditor({
    required this.index,
    required this.col1Ctrl,
    required this.col2Ctrl,
    required this.col1Hint,
    required this.col2Hint,
    required this.readOnly,
  });

  final int index;
  final TextEditingController col1Ctrl;
  final TextEditingController col2Ctrl;
  final String col1Hint;
  final String col2Hint;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: TextField(
            controller: col1Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            enabled: !readOnly,
            decoration: InputDecoration(
              hintText: col1Hint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: col2Ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            enabled: !readOnly,
            decoration: InputDecoration(
              hintText: col2Hint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.readOnly,
    required this.onDiscard,
    this.onSave,
  });

  final bool readOnly;
  final VoidCallback onDiscard;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (readOnly) ...[
              Expanded(
                child: FilledButton(
                  onPressed: onDiscard,
                  child: const Text('Close'),
                ),
              ),
            ] else ...[
              OutlinedButton(
                onPressed: onDiscard,
                child: const Text('Discard'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  child: const Text('Save'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
