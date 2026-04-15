import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kRowCount = 20;

/// Custom drag table editor.
///
/// Returns `List<({double mach, double cd})>` via [context.pop]:
///   - empty list → table cleared
///   - null       → discarded (no change)
class CustomDragTableEditorScreen extends StatefulWidget {
  const CustomDragTableEditorScreen({this.initialTable, super.key});

  /// Existing breakpoints to pre-fill. null/empty → all rows blank.
  final List<({double mach, double cd})>? initialTable;

  @override
  State<CustomDragTableEditorScreen> createState() =>
      _CustomDragTableEditorScreenState();
}

class _CustomDragTableEditorScreenState
    extends State<CustomDragTableEditorScreen> {
  late final List<TextEditingController> _machCtrls;
  late final List<TextEditingController> _cdCtrls;

  @override
  void initState() {
    super.initState();
    _machCtrls = List.generate(_kRowCount, (_) => TextEditingController());
    _cdCtrls = List.generate(_kRowCount, (_) => TextEditingController());
    _initRows();
  }

  void _initRows() {
    final table = widget.initialTable;
    if (table == null || table.isEmpty) return;
    final rows = table.length > _kRowCount
        ? table.sublist(0, _kRowCount)
        : table;
    for (var i = 0; i < rows.length; i++) {
      _machCtrls[i].text = rows[i].mach.toStringAsFixed(2);
      _cdCtrls[i].text = rows[i].cd.toStringAsFixed(4);
    }
  }

  @override
  void dispose() {
    for (final c in _machCtrls) {
      c.dispose();
    }
    for (final c in _cdCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<({double mach, double cd})> _buildResult() {
    final rows = <({double mach, double cd})>[];
    for (var i = 0; i < _kRowCount; i++) {
      final mach = double.tryParse(_machCtrls[i].text.trim()) ?? 0.0;
      final cd = double.tryParse(_cdCtrls[i].text.trim()) ?? 0.0;
      if (mach <= 0 || cd <= 0) continue;
      rows.add((mach: mach, cd: cd));
    }
    // Sort ascending by Mach (standard convention for drag tables)
    rows.sort((a, b) => a.mach.compareTo(b.mach));
    return rows;
  }

  void _onSave() => context.pop(_buildResult());
  void _onDiscard() => context.pop(null);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Custom Drag Table',
      isSubscreen: true,
      showBack: false,
      bottomBar: _ActionBar(onDiscard: _onDiscard, onSave: _onSave),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const _Header(),
          const Divider(height: 16),
          for (var i = 0; i < _kRowCount; i++) ...[
            _RowEditor(index: i, machCtrl: _machCtrls[i], cdCtrl: _cdCtrls[i]),
            if (i < _kRowCount - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Text(
            'Rows where any value is 0 are ignored on save.\n'
            'Rows are sorted by Mach (ascending).',
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
  const _Header();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Row(
      children: [
        Expanded(
          child: Text('Mach', style: style, textAlign: TextAlign.center),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Cd', style: style, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _RowEditor extends StatelessWidget {
  const _RowEditor({
    required this.index,
    required this.machCtrl,
    required this.cdCtrl,
  });

  final int index;
  final TextEditingController machCtrl;
  final TextEditingController cdCtrl;

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
            controller: machCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0.00',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: cdCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0.0000',
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
