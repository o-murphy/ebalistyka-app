// ── Profile Card ──────────────────────────────────────────────────────────────
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileCard extends StatefulWidget {
  const ProfileCard({
    required this.data,
    required this.isActive,
    required this.onSelect,
    required this.onEditWeapon,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
    required this.onRename,
    super.key,
  });

  final ProfileCardData data;
  final bool isActive;
  final VoidCallback onSelect;
  final VoidCallback onEditWeapon;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onRemove;
  final ValueChanged<String> onRename;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ProfileCardData get data => widget.data;
  bool get isActive => widget.isActive;
  VoidCallback get onSelect => widget.onSelect;
  VoidCallback get onEditWeapon => widget.onEditWeapon;
  VoidCallback get onDuplicate => widget.onDuplicate;
  VoidCallback get onExport => widget.onExport;
  VoidCallback get onRemove => widget.onRemove;
  ValueChanged<String> get onRename => widget.onRename;

  @override
  Widget build(BuildContext context) {
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
                              hasAmmo: data.hasAmmo,
                              hasSight: data.hasSight,
                              onDuplicate: onDuplicate,
                              onExport: onExport,
                              onEditWeapon: onEditWeapon,
                              onRemove: onRemove,
                              onRename: onRename,
                            ),
                          ),
                          // Використання функцій для побудови секцій
                          _buildWeaponSection(context),
                          if (data.hasAmmo) _buildAmmoSection(context),
                          if (data.hasAmmo) _buildSightSection(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Bottom action ───────────────────────────────────────────────
          if (data.hasAmmo && data.hasSight)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Align(
                alignment: Alignment.center,
                child: FilledButton(
                  onPressed: onSelect,
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

  // Функція для створення секції Weapon
  Widget _buildWeaponSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final twistDirIcon = data.rightHanded
        ? Icons.rotate_right_outlined
        : Icons.rotate_left_outlined;

    return Column(
      children: [
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

  // Функція для створення секції Ammo
  Widget _buildAmmoSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
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

  // Функція для створення секції Sight (додано!)
  Widget _buildSightSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const Divider(height: 1),
        ListSectionTile(
          "Sight",
          onTap: () => context.go(
            Routes.profileEditAmmo,
          ), // Можливо має бути Routes.profileEditSight?
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
      ],
    );
  }
}

// ── Profile Control Tile (покращений з об'єднаними парами) ─────────────────────
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

            // Sight: кнопка + хінт (ліворуч зверху)
            Positioned(
              top: 8,
              left: 8,
              child: _ButtonWithHint(
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

            // Ammo: кнопка + хінт (праворуч знизу)
            Positioned(
              bottom: 8,
              right: 8,
              child: _ButtonWithHint(
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

// ── Віджет: кнопка + текстовий хінт поряд (не на кнопці!) ─────────────────────
class _ButtonWithHint extends StatelessWidget {
  const _ButtonWithHint({
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
      mini: true,
      onPressed: onPressed,
      backgroundColor: buttonColor,
      foregroundColor: buttonForegroundColor,
      child: Icon(buttonIcon, size: 20),
    );

    // Якщо значення є - показуємо тільки кнопку
    if (hasValue) return button;

    // Якщо значення немає - показуємо кнопку + хінт поряд
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
