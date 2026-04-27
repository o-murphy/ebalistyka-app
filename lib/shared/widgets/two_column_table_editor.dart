import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:flutter/material.dart';

/// Generic two-column numeric table editor.
///
/// Each row is a pair of numeric text fields. Invalid or filtered-out rows are
/// excluded on save.
///
/// Behaviour flags:
/// - [col1Signed]          — allow negative values in col1 (e.g. temperature).
/// - [col1RequirePositive] — when `false`, col1 values ≤ 0 are kept (only
///                           unparseable values are skipped). Default `true`.
/// - [readOnly]            — fields are disabled; action bar shows Close only.
///
/// Extension points:
/// - [headerChild]   — optional widget shown above column headers (e.g. live preview).
/// - [onRowsParsed]  — called after every controller change with the current
///                     valid (col1, col2) double pairs (display units).
/// - [footerText]    — hint shown below the rows when `!readOnly`.
class TwoColumnTableEditorScreen extends StatefulWidget {
  const TwoColumnTableEditorScreen({
    required this.title,
    required this.rowCount,
    required this.col1Header,
    required this.col2Header,
    required this.col1Hint,
    required this.col2Hint,
    required this.sortAscending,
    required this.onSave,
    required this.onDiscard,
    this.initialRows,
    this.readOnly = false,
    this.col1Signed = false,
    this.col1RequirePositive = true,
    this.headerChild,
    this.onRowsParsed,
    this.footerText,
    super.key,
  });

  final String title;
  final int rowCount;
  final String col1Header;
  final String col2Header;
  final String col1Hint;
  final String col2Hint;

  /// Pre-formatted string pairs to populate controllers on first build.
  /// Subsequent widget updates do NOT reset controllers.
  final List<(String, String)>? initialRows;

  /// `true`  → sort col1 ascending  (e.g. Mach for drag table)
  /// `false` → sort col1 descending (e.g. velocity for Multi-BC)
  final bool sortAscending;

  final bool readOnly;

  /// Passes `signed: true` to col1 keyboard (e.g. for temperature).
  final bool col1Signed;

  /// When `false`, col1 values of 0 or below are accepted; only unparseable
  /// cells are skipped. Default `true` (col1 must be > 0).
  final bool col1RequirePositive;

  /// Optional widget displayed above the column headers (e.g. live preview card).
  final Widget? headerChild;

  /// Called on every controller change with the current valid (col1, col2) pairs.
  final ValueChanged<List<(double, double)>>? onRowsParsed;

  /// Footer note shown below the rows when `!readOnly`.
  final String? footerText;

  final void Function(List<(double, double)>) onSave;
  final VoidCallback onDiscard;

  @override
  State<TwoColumnTableEditorScreen> createState() =>
      _TwoColumnTableEditorScreenState();
}

class _TwoColumnTableEditorScreenState
    extends State<TwoColumnTableEditorScreen> {
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

    if (widget.onRowsParsed != null) {
      for (final c in [..._col1Ctrls, ..._col2Ctrls]) {
        c.addListener(_notifyRows);
      }
      // Notify after first frame so parent setState is safe during initial build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notifyRows();
      });
    }
  }

  @override
  void dispose() {
    if (widget.onRowsParsed != null) {
      for (final c in [..._col1Ctrls, ..._col2Ctrls]) {
        c.removeListener(_notifyRows);
      }
    }
    for (final c in _col1Ctrls) {
      c.dispose();
    }
    for (final c in _col2Ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<(double, double)> _parseRows() {
    final rows = <(double, double)>[];
    for (var i = 0; i < widget.rowCount; i++) {
      final v1 = double.tryParse(_col1Ctrls[i].text.trim());
      final v2 = double.tryParse(_col2Ctrls[i].text.trim()) ?? 0.0;
      if (v1 == null) continue;
      if (widget.col1RequirePositive && v1 <= 0) continue;
      if (v2 <= 0) continue;
      rows.add((v1, v2));
    }
    return rows;
  }

  void _notifyRows() => widget.onRowsParsed?.call(_parseRows());

  void _handleSave() {
    final rows = _parseRows();
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
      bottomBar: _TableActionBar(
        readOnly: widget.readOnly,
        onDiscard: widget.onDiscard,
        onSave: widget.readOnly ? null : _handleSave,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          if (widget.headerChild != null) ...[
            widget.headerChild!,
            const SizedBox(height: 8),
          ],
          _TableHeader(col1: widget.col1Header, col2: widget.col2Header),
          const Divider(height: 16),
          for (var i = 0; i < widget.rowCount; i++) ...[
            _TableRowEditor(
              index: i,
              col1Ctrl: _col1Ctrls[i],
              col2Ctrl: _col2Ctrls[i],
              col1Hint: widget.col1Hint,
              col2Hint: widget.col2Hint,
              readOnly: widget.readOnly,
              col1Signed: widget.col1Signed,
            ),
            if (i < widget.rowCount - 1) const SizedBox(height: 8),
          ],
          if (!widget.readOnly && widget.footerText != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.footerText!,
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

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.col1, required this.col2});

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

class _TableRowEditor extends StatelessWidget {
  const _TableRowEditor({
    required this.index,
    required this.col1Ctrl,
    required this.col2Ctrl,
    required this.col1Hint,
    required this.col2Hint,
    required this.readOnly,
    this.col1Signed = false,
  });

  final int index;
  final TextEditingController col1Ctrl;
  final TextEditingController col2Ctrl;
  final String col1Hint;
  final String col2Hint;
  final bool readOnly;
  final bool col1Signed;

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
            keyboardType: TextInputType.numberWithOptions(
              decimal: true,
              signed: col1Signed,
            ),
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

class _TableActionBar extends StatelessWidget {
  const _TableActionBar({
    required this.readOnly,
    required this.onDiscard,
    this.onSave,
  });

  final bool readOnly;
  final VoidCallback onDiscard;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            if (readOnly)
              Expanded(
                child: FilledButton(
                  onPressed: onDiscard,
                  child: Text(l10n.closeButton),
                ),
              )
            else ...[
              OutlinedButton(
                onPressed: onDiscard,
                child: Text(l10n.discardButton),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  child: Text(l10n.saveButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
