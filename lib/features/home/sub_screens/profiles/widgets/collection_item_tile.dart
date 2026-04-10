import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:flutter/material.dart';

class CollectionItemTile extends StatelessWidget {
  const CollectionItemTile({
    required this.item,
    this.body,
    required this.onSelect,
    this.onEdit,
    this.onRemove,
    this.onDuplicate,
    this.onExport,
    this.isSelected = false,
    super.key,
  });

  final CollectionItem item;
  final Widget? body;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onDuplicate;
  final VoidCallback? onExport;
  final bool isSelected;

  bool get _hasActions =>
      onEdit != null || onRemove != null || onDuplicate != null || onExport != null;

  Future<void> _showActionsSheet(BuildContext context) => showActionSheet(
    context,
    title: 'Actions',
    entries: [
      if (onEdit != null)
        ActionSheetItem(
          icon: Icons.edit_outlined,
          title: 'Edit',
          onTap: () async => onEdit!(),
        ),
      if (onDuplicate != null)
        ActionSheetItem(
          icon: Icons.copy_outlined,
          title: 'Duplicate',
          onTap: () async => onDuplicate!(),
        ),
      if (onExport != null)
        ActionSheetItem(
          icon: Icons.file_upload_outlined,
          title: 'Export',
          onTap: () async => onExport!(),
        ),
      if (onRemove != null) ...[
        const ActionSheetDivider(),
        ActionSheetItem(
          icon: Icons.delete_outline,
          title: 'Remove',
          isDestructive: true,
          onTap: () async => onRemove!(),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 200,
      child: Card(
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.primaryContainer, width: 3),
              )
            : null,
        child: Stack(
          children: [
            // Main content
            Center(
              child:
                  body ??
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.control_point_outlined, size: 48),
                      SizedBox(height: 8),
                      Text('Body area'),
                    ],
                  ),
            ),

            // Top right — actions button (⋮), shown only if any action provided
            if (_hasActions)
              Positioned(
                top: 8,
                right: 8,
                child: FloatingActionButton(
                  elevation: 0,
                  mini: true,
                  heroTag: 'actions_btn_${item.id}',
                  onPressed: () => _showActionsSheet(context),
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  child: const Icon(Icons.more_vert_outlined, size: 20),
                ),
              ),

            // Bottom right — select button
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton(
                elevation: 0,
                mini: true,
                heroTag: 'select_btn_${item.id}',
                onPressed: onSelect,
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.check_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
