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
    required this.onEditWeapon,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
    super.key,
  });

  final ProfileCardData data;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEditWeapon;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onRemove;

  void _showEditActionsSheet(BuildContext context) {
    showModalBottomSheet(
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
              child: Text(
                'Profile Actions',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                onDuplicate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(ctx);
                onExport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Weapon'),
              onTap: () {
                Navigator.pop(ctx);
                onEditWeapon();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onRemove();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final twistDirIcon = data.rightHanded
        ? Icons.rotate_right_outlined
        : Icons.rotate_left_outlined;

    return Card(
      color: colorScheme.surfaceContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Простий рядок з назвою без PopupMenuButton
            Row(
              children: [
                Expanded(
                  child: Text(data.name, style: theme.textTheme.titleLarge),
                ),
                if (isActive)
                  Icon(Icons.check_circle_outline, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _ProfileControlTile(
                    profileId: data.id,
                    profileName: data.name,
                    hasAmmo: data.hasAmmo,
                    hasSight: data.hasSight,
                    onDuplicate: onDuplicate,
                    onExport: onExport,
                    onEditWeapon: onEditWeapon,
                    onRemove: onRemove,
                  ),
                  ListSectionTile(
                    "Weapon",
                    onTap: onEditWeapon,
                    trailing: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined),
                    title: Text(data.weaponName),
                    subtitle: const Text("Weapon name"),
                    dense: true,
                  ),
                  InfoListTile(
                    label: "Caliber",
                    value: data.caliber,
                    icon: Icons.circle_outlined,
                  ),
                  InfoListTile(
                    label: "Twist",
                    value: data.twist,
                    icon: twistDirIcon,
                  ),
                  InfoListTile(
                    label: "Twist direction",
                    value: data.rightHanded ? 'right' : 'left',
                    icon: twistDirIcon,
                  ),
                  const Divider(height: 1),
                  ListSectionTile(
                    "Ammo",
                    onTap: () => context.go(Routes.profileEditAmmo),
                    trailing: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.grain_outlined),
                    title: Text(data.cartridgeName),
                    subtitle: const Text("Cartridge name"),
                    dense: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.grain_outlined),
                    title: Text(data.projectileName),
                    subtitle: const Text("Projectile name"),
                    dense: true,
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
                  ListSectionTile(
                    "Sight",
                    onTap: () => context.go(Routes.profileEditAmmo),
                    trailing: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: Text(data.sightName),
                    dense: true,
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

class _ProfileControlTile extends StatelessWidget {
  const _ProfileControlTile({
    required this.profileId,
    required this.profileName,
    required this.hasAmmo,
    required this.hasSight,
    required this.onDuplicate,
    required this.onExport,
    required this.onEditWeapon,
    required this.onRemove,
  });

  final String profileId;
  final String profileName;
  final bool hasAmmo;
  final bool hasSight;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onEditWeapon;
  final VoidCallback onRemove;

  void _showEditProfileNameDialog(BuildContext context) {
    final controller = TextEditingController(text: profileName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Profile name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: зберегти нове ім'я
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditActionsSheet(BuildContext context) {
    showModalBottomSheet(
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
              child: Text(
                'Edit Profile',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            // ListTile(
            //   leading: const Icon(Icons.my_location_outlined),
            //   title: const Text('Select Sight'),
            //   trailing: !hasSight
            //       ? const Icon(
            //           Icons.warning_amber_outlined,
            //           color: Colors.orange,
            //         )
            //       : null,
            //   onTap: () {
            //     Navigator.pop(ctx);
            //     context.push(Routes.sightSelect);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.rocket_launch_outlined),
            //   title: const Text('Select Ammo'),
            //   trailing: !hasAmmo
            //       ? const Icon(
            //           Icons.warning_amber_outlined,
            //           color: Colors.orange,
            //         )
            //       : null,
            //   onTap: () {
            //     Navigator.pop(ctx);
            //     context.push(Routes.ammoSelect);
            //   },
            // ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () {
                Navigator.pop(ctx);
                onDuplicate();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Export'),
              onTap: () {
                Navigator.pop(ctx);
                onExport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile name'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditProfileNameDialog;
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                onRemove();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
                  Icon(Icons.control_point_outlined, size: 48),
                  SizedBox(height: 8),
                  Text('Profile Controls Area'),
                ],
              ),
            ),

            // Top right button (edit button) - всі функції тут
            Positioned(
              top: 8,
              right: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'edit_btn_$profileId',
                onPressed: () => _showEditActionsSheet(context),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.more_vert_outlined, size: 20),
              ),
            ),

            if (!hasSight)
              const Positioned(
                top: 16,
                left: 56,
                child: Text(
                  "Select sight first",
                  style: TextStyle(color: Colors.red),
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
                backgroundColor: hasSight
                    ? colorScheme.secondaryContainer
                    : colorScheme.tertiaryContainer,
                foregroundColor: hasSight
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onTertiaryContainer,
                child: const Icon(Icons.my_location_outlined, size: 20),
              ),
            ),

            if (!hasAmmo)
              const Positioned(
                bottom: 16,
                right: 56,
                child: Text(
                  "Select ammo first",
                  style: TextStyle(color: Colors.red),
                ),
              ),

            // Bottom right button
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'cartridge_btn_$profileId',
                onPressed: () => context.push(Routes.ammoSelect),
                backgroundColor: hasAmmo
                    ? colorScheme.primaryContainer
                    : colorScheme.tertiaryContainer,
                foregroundColor: hasAmmo
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onTertiaryContainer,
                child: const Icon(Icons.rocket_launch_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
