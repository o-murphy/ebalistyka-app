// ── Profile Card ──────────────────────────────────────────────────────────────
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.data,
    required this.isActive,
    required this.onSelect,
    required this.onEditRifle,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
    super.key,
  });

  final ProfileCardData data;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEditRifle;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ProfileTitleRow(
              title: data.name,
              isActive: isActive,
              onDuplicate: onDuplicate,
              onExport: onExport,
              onRemove: onRemove,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _ProfileControlTile(profileId: data.id),
                  ListSectionTile("Rifle"),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined),
                    title: Text(data.rifleName),
                    dense: true,
                    trailing: IconButton(
                      onPressed: onEditRifle,
                      icon: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InfoListTile(
                    label: "Caliber",
                    value: data.caliber,
                    icon: Icons.circle_outlined,
                  ),
                  InfoListTile(
                    label: "Twist",
                    value: data.twist,
                    icon: Icons.rotate_left_outlined,
                  ),
                  InfoListTile(
                    label: "Twist direction",
                    value: data.twistDirection,
                    icon: Icons.rotate_left_outlined,
                  ),
                  const Divider(height: 1),
                  ListSectionTile("Cartridge"),
                  ListTile(
                    leading: const Icon(Icons.grain_outlined),
                    title: Text(data.cartridgeName),
                    dense: true,
                    trailing: IconButton(
                      onPressed: () => context.go(Routes.profileEditCartridge),
                      icon: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                  InfoListTile(
                    label: "Drag model",
                    value: data.dragModel,
                    icon: Icons.trending_up_outlined,
                  ),
                  InfoListTile(
                    label: "Muzzle velocity",
                    value: data.muzzleVelocity,
                    icon: Icons.speed_outlined,
                  ),
                  InfoListTile(
                    label: "Caliber",
                    value: data.caliber,
                    icon: Icons.circle_outlined,
                  ),
                  InfoListTile(
                    label: "Weight",
                    value: data.weight,
                    icon: Icons.balance_outlined,
                  ),
                  const Divider(height: 1),
                  ListSectionTile("Sight"),
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: Text(data.sightName),
                    dense: true,
                    trailing: IconButton(
                      onPressed: () => context.go(Routes.profileEditSight),
                      icon: Icon(Icons.edit_outlined, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: FilledButton(
                onPressed: onSelect,
                child: Text(!isActive ? 'Select' : 'Go to calculations'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProfileMenuAction { duplicate, export, remove }

class _ProfileTitleRow extends StatelessWidget {
  const _ProfileTitleRow({
    required this.title,
    required this.isActive,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
  });

  final String title;
  final bool isActive;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (isActive) Icon(Icons.check_circle, color: colorScheme.primary),
        PopupMenuButton<_ProfileMenuAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _ProfileMenuAction.duplicate:
                onDuplicate();
              case _ProfileMenuAction.export:
                onExport();
              case _ProfileMenuAction.remove:
                onRemove();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _ProfileMenuAction.duplicate,
              child: ListTile(
                leading: Icon(Icons.copy_outlined),
                title: Text('Duplicate'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: _ProfileMenuAction.export,
              child: ListTile(
                leading: Icon(Icons.file_upload_outlined),
                title: Text('Export'),
                dense: true,
              ),
            ),
            PopupMenuDivider(),
            PopupMenuItem(
              value: _ProfileMenuAction.remove,
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('Remove'),
                dense: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileControlTile extends StatelessWidget {
  const _ProfileControlTile({required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 200,
      child: Card(
        child: Stack(
          children: [
            // Main content
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.control_point, size: 48),
                  SizedBox(height: 8),
                  Text('Profile Controls Area'),
                ],
              ),
            ),

            // Top left button
            Positioned(
              top: 8,
              left: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'sight_btn_$profileId',
                onPressed: () => context.push(Routes.sightSelect),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.my_location_outlined, size: 20),
              ),
            ),

            // Bottom right button
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'cartridge_btn_$profileId',
                onPressed: () => context.push(Routes.cartridgeSelect),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: const Icon(Icons.rocket_launch_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
