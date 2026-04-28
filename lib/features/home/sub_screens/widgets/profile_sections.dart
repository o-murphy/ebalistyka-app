import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';

class ProfileWeaponSection extends StatelessWidget {
  const ProfileWeaponSection({
    required this.data,
    required this.onEdit,
    super.key,
  });

  final ProfileCardData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final twistDirIcon = data.rightHanded ? IconDef.twistR : IconDef.twistL;

    return Column(
      children: [
        ListSectionTile(
          "Weapon",
          onTap: onEdit,
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
}

class ProfileAmmoSection extends StatelessWidget {
  const ProfileAmmoSection({
    required this.data,
    required this.onEdit,
    super.key,
  });

  final ProfileCardData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const TileDivider(),
        ListSectionTile(
          "Ammo",
          onTap: onEdit,
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
}

class ProfileSightSection extends StatelessWidget {
  const ProfileSightSection({
    required this.data,
    required this.onEdit,
    super.key,
  });

  final ProfileCardData data;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fpIcon = switch (data.focalPlane) {
      FocalPlane.ffp => IconDef.ffp,
      FocalPlane.sfp => IconDef.sfp,
      FocalPlane.lwir => IconDef.lwir,
    };

    return Column(
      children: [
        const TileDivider(),
        ListSectionTile(
          "Sight",
          onTap: onEdit,
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
