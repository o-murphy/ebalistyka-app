export 'shot_details_screen.dart';
export 'profiles_screen.dart';
export 'my_ammo_screen.dart';
export 'my_sights_screen.dart';

import 'package:ebalistyka/shared/widgets/_stub_screen.dart';
import 'package:flutter/material.dart';

// ── Weapon ────────────────────────────────────────────────────────────────────

class SelectWeaponCollectionScreen extends StatelessWidget {
  const SelectWeaponCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Weapon Collection');
}

// ── Ammo ──────────────────────────────────────────────────────────────────────

/// Shared collection screen for both cartridges and bullets.
/// [filterBullet] — true → show bullets only, false → show cartridges only.
class AmmoCollectionScreen extends StatelessWidget {
  const AmmoCollectionScreen({required this.filterBullet, super.key});
  final bool filterBullet;
  @override
  Widget build(BuildContext context) => StubScreen(
    title: filterBullet ? 'Bullet Collection' : 'Cartridge Collection',
  );
}

class CreateAmmoWizardScreen extends StatelessWidget {
  const CreateAmmoWizardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Create Ammo');
}

class AmmoEditScreen extends StatelessWidget {
  const AmmoEditScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Edit Ammo');
}

// ── Sight ─────────────────────────────────────────────────────────────────────

class CreateSightWizardScreen extends StatelessWidget {
  const CreateSightWizardScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Create Sight');
}

class SelectSightCollectionScreen extends StatelessWidget {
  const SelectSightCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Sight Collection');
}

class SightEditScreen extends StatelessWidget {
  const SightEditScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Edit Sight');
}
