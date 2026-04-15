import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _kRowCount = 5;

/// Multi-BC breakpoint table editor for G1/G7 drag models.
///
/// Receives initial data via constructor (passed from router extra).
/// Returns `List<({double vMps, double bc})>` via [context.pop]:
///   - empty list → table cleared
///   - null → discarded (no change)
class MultiBcEditorScreen extends ConsumerStatefulWidget {
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
  ConsumerState<MultiBcEditorScreen> createState() =>
      _MultiBcEditorScreenState();
}

class _MultiBcEditorScreenState extends ConsumerState<MultiBcEditorScreen> {
  late final List<TextEditingController> _vCtrls;
  late final List<TextEditingController> _bcCtrls;

  @override
  void initState() {
    super.initState();
    _vCtrls = List.generate(_kRowCount, (_) => TextEditingController());
    _bcCtrls = List.generate(_kRowCount, (_) => TextEditingController());

    final velocityUnit = ref.read(unitSettingsProvider).velocityUnit;
    _initRows(velocityUnit);
  }

  void _initRows(Unit velocityUnit) {
    final table = widget.initialTable;
    final isEmpty = table == null || table.isEmpty;

    if (isEmpty &&
        widget.initialMvMps != null &&
        (widget.initialMvMps! > 0) &&
        widget.initialBc != null &&
        (widget.initialBc! > 0)) {
      // Auto-fill row 0 with current MV and BC
      final vDisplay = Velocity.mps(widget.initialMvMps!).in_(velocityUnit);
      final vAcc = FC.muzzleVelocity.accuracyFor(velocityUnit);
      _vCtrls[0].text = vDisplay.toStringAsFixed(vAcc);
      _bcCtrls[0].text = widget.initialBc!.toStringAsFixed(3);
    } else if (!isEmpty) {
      final rows = table.length > _kRowCount
          ? table.sublist(0, _kRowCount)
          : table;
      final vAcc = FC.muzzleVelocity.accuracyFor(velocityUnit);
      for (var i = 0; i < rows.length; i++) {
        final vDisplay = Velocity.mps(rows[i].vMps).in_(velocityUnit);
        _vCtrls[i].text = vDisplay.toStringAsFixed(vAcc);
        _bcCtrls[i].text = rows[i].bc.toStringAsFixed(3);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _vCtrls) {
      c.dispose();
    }
    for (final c in _bcCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<({double vMps, double bc})> _buildResult(Unit velocityUnit) {
    final rows = <({double vMps, double bc})>[];
    for (var i = 0; i < _kRowCount; i++) {
      final vDisplay = double.tryParse(_vCtrls[i].text.trim()) ?? 0.0;
      final bc = double.tryParse(_bcCtrls[i].text.trim()) ?? 0.0;
      if (vDisplay <= 0 || bc <= 0) continue;
      final vMps = Velocity(vDisplay, velocityUnit).in_(Unit.mps);
      rows.add((vMps: vMps, bc: bc));
    }
    // Sort descending — highest velocity first (bclibc convention)
    rows.sort((a, b) => b.vMps.compareTo(a.vMps));
    return rows;
  }

  void _onSave() {
    final velocityUnit = ref.read(unitSettingsProvider).velocityUnit;
    context.pop(_buildResult(velocityUnit));
  }

  void _onDiscard() => context.pop(null);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final velocityUnit = ref.watch(unitSettingsProvider).velocityUnit;
    final dtName = widget.dragType.name.toUpperCase();

    return BaseScreen(
      title: '$dtName Multi-BC Table',
      isSubscreen: true,
      showBack: false,
      bottomBar: _ActionBar(onDiscard: _onDiscard, onSave: _onSave),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _Header(velocityUnit: velocityUnit),
          const Divider(height: 16),
          for (var i = 0; i < _kRowCount; i++) ...[
            _RowEditor(index: i, vCtrl: _vCtrls[i], bcCtrl: _bcCtrls[i]),
            if (i < _kRowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Text(
            'Rows where any value is 0 are ignored on save.\n'
            'Rows are sorted by velocity (highest first).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.velocityUnit});
  final Unit velocityUnit;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        Expanded(
          child: Text(
            'V (${velocityUnit.symbol})',
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'BC (fraction)',
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _RowEditor extends StatelessWidget {
  const _RowEditor({
    required this.index,
    required this.vCtrl,
    required this.bcCtrl,
  });

  final int index;
  final TextEditingController vCtrl;
  final TextEditingController bcCtrl;

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
            controller: vCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: bcCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0.000',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onDiscard, required this.onSave});

  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            OutlinedButton(onPressed: onDiscard, child: const Text('Discard')),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: onSave, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
