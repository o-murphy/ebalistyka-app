// ── Profile Card ──────────────────────────────────────────────────────────────

import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onSelect,
    super.key,
  });

  final ShotProfile profile;
  final bool isActive;
  final VoidCallback onSelect;

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
            _ProfileTitleRow(title: profile.name, isActive: isActive),
            const SizedBox(height: 16), // Додаємо відступ
            Expanded(
              child: ListView(
                children: [
                  _ProfileControls(),
                  const ListSectionTile("Rifle"),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined),
                    title: Text(profile.rifle.name),
                    dense: true,
                    onTap: () => debugPrint("edit rifle"),
                  ),
                  const Divider(height: 1),
                  const ListSectionTile("Cartridge"),
                  ListTile(
                    leading: const Icon(Icons.grain_outlined),
                    title: Text(profile.cartridge.name),
                    dense: true,
                    onTap: () => debugPrint("edit cartridge"),
                  ),
                  const Divider(height: 1),
                  const ListSectionTile("Sight"),
                  ListTile(
                    leading: const Icon(Icons.my_location_outlined),
                    title: Text(profile.sight.name),
                    dense: true,
                    onTap: () => debugPrint("edit sight"),
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

class _ProfileTitleRow extends StatelessWidget {
  const _ProfileTitleRow({required this.title, required this.isActive});

  final String title;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        if (isActive) Icon(Icons.check_circle, color: colorScheme.primary),
      ],
    );
  }
}

class _ProfileControls extends StatelessWidget {
  const _ProfileControls();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 200, child: Card());
  }
}
