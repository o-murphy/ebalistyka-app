import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/constants/ui_dimensions.dart';
import 'package:ebalistyka/shared/widgets/two_column_table_editor.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      initialRows = table.map((r) {
        final vDisplay = Velocity.mps(r.vMps).in_(velocityUnit);
        return (vDisplay.toStringAsFixed(vAcc), r.bc.toStringAsFixed(3));
      }).toList();
    }

    return TwoColumnTableEditorScreen(
      title: '$dtName Multi-BC Table',
      rowCount: kMultiBcRowCount,
      col1Header: 'V (${velocityUnit.symbol})',
      col2Header: 'BC (fraction)',
      col1Hint: '0',
      col2Hint: '0.000',
      initialRows: initialRows,
      sortAscending: false,
      footerText: 'Rows where any value is 0 are ignored on save.',
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

    return TwoColumnTableEditorScreen(
      title: 'Custom Drag Table',
      rowCount: kDragTableRowCount,
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
