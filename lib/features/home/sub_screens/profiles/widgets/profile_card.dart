// ── Profile Card ──────────────────────────────────────────────────────────────
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileCard extends ConsumerStatefulWidget {
  const ProfileCard({
    required this.profileId,
    required this.activeProfileId,
    required this.onSelect,
    required this.onEditWeapon,
    required this.onEditAmmo,
    required this.onEditSight,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
    required this.onRename,
    super.key,
  });

  final String profileId;
  final String? activeProfileId;
  final VoidCallback onSelect;
  final VoidCallback onEditWeapon;
  final VoidCallback onEditAmmo;
  final VoidCallback onEditSight;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onRemove;
  final ValueChanged<String> onRename;

  @override
  ConsumerState<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<ProfileCard> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuilds when THIS profile's data changes.
    final data = ref.watch(profileCardProvider(widget.profileId));
    if (data == null) return const SizedBox.shrink();

    final isActive = widget.profileId == widget.activeProfileId;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      elevation: isActive ? 0 : 3,
      shape: isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.primaryContainer, width: 3),
            )
          : null,
      child: Column(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.name,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _scrollController,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: _ProfileControlTile(
                              profileId: data.id,
                              profileName: data.name,
                              hasAmmo: data.ammoId != null,
                              hasSight: data.sightId != null,
                              onDuplicate: widget.onDuplicate,
                              onExport: widget.onExport,
                              onEditWeapon: widget.onEditWeapon,
                              onRemove: widget.onRemove,
                              onRename: widget.onRename,
                            ),
                          ),
                          _buildWeaponSection(context, data),
                          if (data.ammoId != null)
                            _buildAmmoSection(context, data),
                          if (data.sightId != null)
                            _buildSightSection(context, data),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Bottom action ───────────────────────────────────────────────
          if (data.ammoId != null && data.sightId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Align(
                alignment: Alignment.center,
                child: FilledButton(
                  onPressed: widget.onSelect,
                  child: Text(!isActive ? 'Select' : 'Go to calculations'),
                ),
              ),
            )
          else
            ColoredBox(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Select ammo and sight first',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeaponSection(BuildContext context, ProfileCardData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final twistDirIcon = data.rightHanded
        ? Icons.rotate_right_outlined
        : Icons.rotate_left_outlined;

    return Column(
      children: [
        ListSectionTile(
          "Weapon",
          onTap: widget.onEditWeapon,
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
          value: data.weaponCaliber,
          icon: Icons.circle_outlined,
        ),
        InfoListTile(label: "Twist", value: data.twist, icon: twistDirIcon),
        InfoListTile(
          label: "Twist direction",
          value: data.rightHanded ? 'right' : 'left',
          icon: twistDirIcon,
        ),
      ],
    );
  }

  Widget _buildAmmoSection(BuildContext context, ProfileCardData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Divider(height: 1),
        ListSectionTile(
          "Ammo",
          onTap: widget.onEditAmmo,
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
          value: data.ammoCaliber,
          icon: Icons.circle_outlined,
        ),
        InfoListTile(
          label: "Weight",
          value: data.weight,
          icon: Icons.balance_outlined,
        ),
      ],
    );
  }

  Widget _buildSightSection(BuildContext context, ProfileCardData data) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Divider(height: 1),
        ListSectionTile(
          "Sight",
          onTap: widget.onEditSight,
          trailing: Icon(
            Icons.edit_outlined,
            size: 16,
            color: colorScheme.primary,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.my_location_outlined),
          title: Text(data.sightName),
          subtitle: const Text("Sight name"),
          dense: true,
        ),
        InfoListTile(
          label: "Sight height",
          value: data.sightHeight,
          icon: Icons.height_outlined,
        ),
        // InfoListTile(
        //   label: "Reticle",
        //   value: data.reticleName,
        //   // icon: Icons.trending_up_outlined,
        // ),
        InfoListTile(
          label: "Focal plane",
          value: data.focalPlane,
          icon: Icons.first_page_outlined,
        ),
        InfoListTile(
          label: "Magnification",
          value: data.magnification,
          icon: Icons.zoom_in_outlined,
        ),
        InfoListTile(
          label: "Vertical click",
          value: data.verticalClick,
          icon: Icons.swap_vert_outlined,
        ),
        InfoListTile(
          label: "Horizontal click",
          value: data.horizontalClick,
          icon: Icons.swap_horiz_outlined,
        ),
      ],
    );
  }
}

// ── Profile Control Tile ──────────────────────────────────────────────────────

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
    required this.onRename,
  });

  final String profileId;
  final String profileName;
  final bool hasAmmo;
  final bool hasSight;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onEditWeapon;
  final VoidCallback onRemove;
  final ValueChanged<String> onRename;

  Future<void> _showEditActionsSheet(BuildContext context) => showActionSheet(
    context,
    title: 'Edit Profile',
    entries: [
      ActionSheetItem(
        icon: Icons.copy_outlined,
        title: 'Duplicate',
        onTap: () async => onDuplicate(),
      ),
      ActionSheetItem(
        icon: Icons.file_upload_outlined,
        title: 'Export',
        onTap: () async => onExport(),
      ),
      ActionSheetItem(
        icon: Icons.edit_outlined,
        title: 'Edit profile name',
        onTap: () async {
          final name = await showTextInputDialog(
            context,
            title: 'Edit Profile Name',
            initialValue: profileName,
            labelText: 'Profile name',
            confirmLabel: 'Save',
          );
          if (name != null) onRename(name);
        },
      ),
      const ActionSheetDivider(),
      ActionSheetItem(
        icon: Icons.delete_outline,
        title: 'Remove',
        isDestructive: true,
        onTap: () async => onRemove(),
      ),
    ],
  );

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

            // Top right button (edit button)
            Positioned(
              top: 8,
              right: 8,
              child: FloatingActionButton(
                mini: true,
                heroTag: 'edit_btn_$profileId',
                onPressed: () async => _showEditActionsSheet(context),
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
                child: const Icon(Icons.more_vert_outlined, size: 20),
              ),
            ),

            // Sight button (top left)
            Positioned(
              top: 8,
              left: 8,
              child: _ButtonWithHint(
                heroTag: 'sight_btn_$profileId',
                hasValue: hasSight,
                onPressed: () =>
                    context.push(Routes.sightSelect, extra: profileId),
                buttonIcon: Icons.my_location_outlined,
                buttonColor: hasSight
                    ? colorScheme.secondaryContainer
                    : colorScheme.tertiaryContainer,
                buttonForegroundColor: hasSight
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onTertiaryContainer,
                hintText: "Select sight",
                hintIcon: Icons.arrow_back,
                hintColor: colorScheme.tertiary,
                hintPosition: _HintPosition.right,
              ),
            ),

            // Ammo button (bottom right)
            Positioned(
              bottom: 8,
              right: 8,
              child: _ButtonWithHint(
                heroTag: 'ammo_btn_$profileId',
                hasValue: hasAmmo,
                onPressed: () =>
                    context.push(Routes.ammoSelect, extra: profileId),
                buttonIcon: Icons.rocket_launch_outlined,
                buttonColor: hasAmmo
                    ? colorScheme.primaryContainer
                    : colorScheme.tertiaryContainer,
                buttonForegroundColor: hasAmmo
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onTertiaryContainer,
                hintText: "Select ammo",
                hintIcon: Icons.arrow_forward,
                hintColor: colorScheme.tertiary,
                hintPosition: _HintPosition.left,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Button with hint ──────────────────────────────────────────────────────────

class _ButtonWithHint extends StatelessWidget {
  const _ButtonWithHint({
    required this.heroTag,
    required this.hasValue,
    required this.onPressed,
    required this.buttonIcon,
    required this.buttonColor,
    required this.buttonForegroundColor,
    required this.hintText,
    required this.hintIcon,
    required this.hintColor,
    required this.hintPosition,
  });

  final Object heroTag;
  final bool hasValue;
  final VoidCallback onPressed;
  final IconData buttonIcon;
  final Color buttonColor;
  final Color buttonForegroundColor;
  final String hintText;
  final IconData hintIcon;
  final Color hintColor;
  final _HintPosition hintPosition;

  @override
  Widget build(BuildContext context) {
    final button = FloatingActionButton(
      heroTag: heroTag,
      mini: true,
      onPressed: onPressed,
      backgroundColor: buttonColor,
      foregroundColor: buttonForegroundColor,
      child: Icon(buttonIcon, size: 20),
    );

    if (hasValue) return button;

    final hint = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hintPosition == _HintPosition.left) ...[
          Text(hintText, style: TextStyle(fontSize: 12, color: hintColor)),
          const SizedBox(width: 4),
          Icon(hintIcon, size: 16, color: hintColor),
        ] else ...[
          Icon(hintIcon, size: 16, color: hintColor),
          const SizedBox(width: 4),
          Text(hintText, style: TextStyle(fontSize: 12, color: hintColor)),
        ],
      ],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: hintPosition == _HintPosition.left
          ? [hint, const SizedBox(width: 8), button]
          : [button, const SizedBox(width: 8), hint],
    );
  }
}

enum _HintPosition { left, right }
