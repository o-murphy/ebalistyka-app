// ── Profile Card ──────────────────────────────────────────────────────────────
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/shared/widgets/weapon_svg_view.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
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
                  Center(
                    child: Text(
                      data.name,
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
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
                              weaponImage: data.weaponImage,
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
            ColoredBox(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: FilledButton(
                  onPressed: widget.onSelect,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
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
    final twistDirIcon = data.rightHanded ? IconDef.twistR : IconDef.twistL;

    return Column(
      children: [
        ListSectionTile(
          "Weapon",
          onTap: widget.onEditWeapon,
          trailing: Icon(IconDef.edit, size: 16, color: colorScheme.primary),
        ),
        ListTile(
          leading: const Icon(IconDef.weapon),
          title: Text(data.weaponName),
          subtitle: const Text("Weapon name"),
          dense: true,
        ),
        InfoListTile(
          label: "Caliber",
          value: data.weaponCaliber,
          icon: IconDef.caliber,
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
          trailing: Icon(IconDef.edit, size: 16, color: colorScheme.primary),
        ),
        ListTile(
          leading: const Icon(IconDef.grain),
          title: Text(data.cartridgeName),
          subtitle: const Text("Cartridge name"),
          dense: true,
        ),
        ListTile(
          leading: const Icon(IconDef.grain),
          title: Text(data.projectileName),
          subtitle: const Text("Projectile name"),
          dense: true,
        ),
        InfoListTile(
          label: "Drag model",
          value: data.dragModel,
          icon: IconDef.dragModel,
        ),
        InfoListTile(
          label: "Muzzle velocity",
          value: data.muzzleVelocity,
          icon: IconDef.velocity,
        ),
        InfoListTile(
          label: "Caliber",
          value: data.ammoCaliber,
          icon: IconDef.caliber,
        ),
        InfoListTile(label: "Weight", value: data.weight, icon: IconDef.weigth),
      ],
    );
  }

  Widget _buildSightSection(BuildContext context, ProfileCardData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final fpIcon = switch (data.focalPlane) {
      FocalPlane.ffp => IconDef.ffp,
      FocalPlane.sfp => IconDef.sfp,
      FocalPlane.lwir => IconDef.lwir,
    };

    return Column(
      children: [
        const Divider(height: 1),
        ListSectionTile(
          "Sight",
          onTap: widget.onEditSight,
          trailing: Icon(IconDef.edit, size: 16, color: colorScheme.primary),
        ),
        ListTile(
          leading: const Icon(IconDef.sight),
          title: Text(data.sightName),
          subtitle: const Text("Sight name"),
          dense: true,
        ),
        InfoListTile(
          label: "Sight height",
          value: data.sightHeight,
          icon: IconDef.height,
        ),
        InfoListTile(
          label: "Reticle",
          value: data.reticleImage,
          icon: IconDef.sight,
        ),
        InfoListTile(
          label: "Focal plane",
          value: data.focalPlane.name.toUpperCase(),
          icon: fpIcon,
        ),
        InfoListTile(
          label: "Magnification",
          value: data.magnification,
          icon: IconDef.magnificationMax,
        ),
        InfoListTile(
          label: "Vertical click",
          value: data.verticalClick,
          icon: IconDef.verticalClick,
        ),
        InfoListTile(
          label: "Horizontal click",
          value: data.horizontalClick,
          icon: IconDef.horizontalClick,
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
    this.weaponImage,
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
  final String? weaponImage;
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
        icon: IconDef.copy,
        title: 'Duplicate',
        onTap: () async => onDuplicate(),
      ),
      ActionSheetItem(
        icon: IconDef.export,
        title: 'Export',
        onTap: () async => onExport(),
      ),
      ActionSheetItem(
        icon: IconDef.edit,
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
        icon: IconDef.remove,
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
      height: 160,
      child: Card(
        child: Stack(
          children: [
            // Weapon image
            Positioned.fill(child: WeaponSvgView(imageId: weaponImage)),

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
                child: const Icon(IconDef.more, size: 20),
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
                buttonIcon: IconDef.sight,
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
                buttonIcon: IconDef.ammo,
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
