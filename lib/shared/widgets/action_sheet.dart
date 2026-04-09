import 'package:flutter/material.dart';

// ── Entries ───────────────────────────────────────────────────────────────────

sealed class ActionSheetEntry {
  const ActionSheetEntry();
}

/// A tappable item in an action sheet.
/// [onTap] may be async; it is called after the sheet is dismissed.
class ActionSheetItem extends ActionSheetEntry {
  const ActionSheetItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final Future<void> Function() onTap;
  final bool isDestructive;
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          for (final entry in entries)
            switch (entry) {
              ActionSheetDivider() => const Divider(height: 1),
              ActionSheetItem(
                :final icon,
                :final title,
                :final onTap,
                :final isDestructive,
              ) =>
                ListTile(
                  leading: Icon(icon, color: isDestructive ? Colors.red : null),
                  title: Text(
                    title,
                    style: isDestructive
                        ? const TextStyle(color: Colors.red)
                        : null,
                  ),
                  onTap: () {
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
