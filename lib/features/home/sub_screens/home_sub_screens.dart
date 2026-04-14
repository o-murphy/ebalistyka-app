export 'shot_details_screen.dart';
export 'my_profiles_screen.dart';
export 'my_ammo_screen.dart';
export 'my_sights_screen.dart';
export 'sight_wizard_screen.dart';
export 'ammo_wizard_screen.dart';

import 'package:ebalistyka/shared/widgets/_stub_screen.dart';
import 'package:flutter/material.dart';

// ── Weapon ────────────────────────────────────────────────────────────────────

class WeaponCollectionScreen extends StatelessWidget {
  const WeaponCollectionScreen({super.key});
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

// ── Sight ─────────────────────────────────────────────────────────────────────

class SightCollectionScreen extends StatelessWidget {
  const SightCollectionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StubScreen(title: 'Sight Collection');
}
