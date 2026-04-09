import 'package:ebalistyka/core/models/collection_item.dart';
import 'package:flutter/material.dart';

class CollectionItemTile extends StatelessWidget {
  const CollectionItemTile({
    required this.item,
    this.body,
    required this.onSelect,
    this.onEdit,
    super.key,
  });

  final CollectionItem item;
  final Widget? body;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 200,
      child: Card(
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

            // Top right button - показуємо тільки якщо onEdit не null
            if (onEdit != null)
              Positioned(
                top: 8,
                right: 8,
                child: FloatingActionButton(
                  elevation: 0,
                  mini: true,
                  heroTag: 'sight_btn_${item.id}',
                  onPressed: onEdit,
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  child: const Icon(Icons.edit_outlined, size: 20),
                ),
              ),

            // Bottom right button - завжди показуємо
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton(
                elevation: 0,
                mini: true,
                heroTag: 'cartridge_btn_${item.id}',
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
