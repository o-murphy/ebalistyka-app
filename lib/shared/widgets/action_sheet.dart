import 'package:flutter/material.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

// ── Entries ───────────────────────────────────────────────────────────────────

sealed class ActionSheetEntry {
  const ActionSheetEntry();
}

/// A tappable item in an action sheet.
/// [onTap] may be async; it is called after the sheet is dismissed.
class ActionSheetItem extends ActionSheetEntry {
  ActionSheetItem({
    required this.title,
    this.onTap,
    this.icon,
    this.subtitle,
    this.isDestructive = false,
    this.isDisabled = false,
  });

  IconData? icon;
  final String title;
  final String? subtitle;
  final Future<void> Function()? onTap;
  final bool isDestructive;
  final bool isDisabled;
}

/// A thin horizontal divider between groups of items.
class ActionSheetDivider extends ActionSheetEntry {
  const ActionSheetDivider();
}

// ── Public function ───────────────────────────────────────────────────────────

/// Shows a modal bottom sheet styled consistently across the app.
///
/// The sheet is dismissed before each [ActionSheetItem.onTap] is awaited,
/// so async navigation/dialogs work correctly.
Future<void> showActionSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<ActionSheetEntry> entries,
}) async {
  Future<void> Function()? pending;

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, subtitle != null ? 4 : 8),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                subtitle,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const TileDivider(),
          for (final entry in entries)
            switch (entry) {
              ActionSheetDivider() => const TileDivider(),
              ActionSheetItem(
                :final icon,
                :final title,
                :final onTap,
                :final isDestructive,
                :final subtitle,
                :final isDisabled,
              ) =>
                _ActionSheetItem(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  isDestructive: isDestructive,
                  isDisabled: isDisabled || onTap == null,
                  onTap: onTap,
                  onSelected: () {
                    pending = onTap;
                    Navigator.of(ctx).pop();
                  },
                ),
            },
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  // Sheet is fully dismissed — now safe to push routes or show dialogs.
  await pending?.call();
}

class _ActionSheetItem extends StatelessWidget {
  const _ActionSheetItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDestructive,
    required this.isDisabled,
    required this.onTap,
    required this.onSelected,
  });

  final IconData? icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final bool isDisabled;
  final Future<void> Function()? onTap;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: icon != null
          ? Icon(
              icon,
              color: isDisabled
                  ? cs.onSurface.withValues(alpha: 0.38)
                  : isDestructive
                  ? cs.error
                  : null,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: isDisabled
              ? cs.onSurface.withValues(alpha: 0.38)
              : isDestructive
              ? cs.error
              : null,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: isDisabled
                    ? cs.onSurface.withValues(alpha: 0.38)
                    : cs.onSurfaceVariant,
              ),
            )
          : null,
      onTap: isDisabled ? null : onSelected,
    );
  }
}
