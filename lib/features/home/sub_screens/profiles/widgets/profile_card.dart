// ── Profile Card ──────────────────────────────────────────────────────────────

import 'package:eballistica/core/models/shot_profile.dart';
import 'package:eballistica/core/solver/unit.dart' show Unit;
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
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // Контент, що скроллиться, з обмеженою висотою
                _ProfileTitleRow(title: profile.name, isActive: isActive),
                SizedBox(
                  height: constraints.maxHeight - 160, // Відступ для кнопки
                  child: ListView(
                    children: [
                      _ProfileControls(),
                      _ProfileRifleSection(profile: profile),
                      _ProfileCartridgeSection(),
                    ],
                  ),
                ),
                // Кнопка внизу
                Align(
                  alignment: Alignment.center,
                  child: isActive
                      ? FilledButton(
                          onPressed: onSelect,
                          child: const Text('Select'),
                        )
                      : FilledButton(
                          onPressed: onSelect,
                          child: const Text('Go to calculations'),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileRifleSection extends StatelessWidget {
  const _ProfileRifleSection({required this.profile});

  final ShotProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          SectionHeader("Rifle"),
          _InfoRow(
            icon: Icons.military_tech_outlined,
            label: profile.rifle.name,
          ),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.grain_outlined, label: profile.cartridge.name),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.my_location_outlined,
            label:
                '${profile.zeroDistance.in_(Unit.meter).toStringAsFixed(0)} m zero',
          ),
        ],
      ),
    );
  }
}

class _ProfileCartridgeSection extends StatelessWidget {
  const _ProfileCartridgeSection();

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: [SectionHeader("Cartridge")]));
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
