import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:ebalistyka/shared/widgets/weapon_svg_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileControlTile extends StatelessWidget {
  const ProfileControlTile({
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
    super.key,
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
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: 160,
      child: Card(
        child: Stack(
          children: [
            Positioned.fill(child: WeaponSvgView(imageId: weaponImage)),

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
                hintText: l10n.selectSightHint,
                hintIcon: Icons.arrow_back,
                hintColor: colorScheme.tertiary,
                hintPosition: _HintPosition.right,
              ),
            ),

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
                hintText: l10n.selectAmmoHint,
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
