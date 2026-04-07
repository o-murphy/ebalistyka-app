export 'shot_details_screen.dart';
export 'profiles_screen.dart';
export 'my_cartridges_screen.dart';
export 'my_sights_screen.dart';

import 'package:ebalistyka/shared/widgets/_stub_screen.dart';
import 'package:flutter/material.dart';

// ── Rifle ─────────────────────────────────────────────────────────────────────

class CreateRifleWizardScreen extends StatelessWidget {
  const CreateRifleWizardScreen({super.key});
  @override
  Widget build(BuildContext context) => const StubScreen(title: 'Create Rifle');
}

class SelectRifleCollectionScreen extends StatelessWidget {
  const SelectRifleCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Rifle Collection');
}

// ── Cartridge ─────────────────────────────────────────────────────────────────

class SelectCartridgeCollectionScreen extends StatelessWidget {
  const SelectCartridgeCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Select Cartridge');
}

class CreateCartridgeWizardScreen extends StatelessWidget {
  const CreateCartridgeWizardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Create Cartridge');
}

class CartridgeEditScreen extends StatelessWidget {
  const CartridgeEditScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Edit Cartridge');
}

// ── Projectile (future) ───────────────────────────────────────────────────────

class ProjectileSelectScreen extends StatelessWidget {
  const ProjectileSelectScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Select Projectile');
}

class CreateProjectileWizardScreen extends StatelessWidget {
  const CreateProjectileWizardScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Create Projectile');
}

class SelectProjectileCollectionScreen extends StatelessWidget {
  const SelectProjectileCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Projectile Collection');
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
