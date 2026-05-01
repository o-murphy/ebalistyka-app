import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/profile_control_tile.dart';
import 'package:ebalistyka/features/home/sub_screens/widgets/profile_sections.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final data = ref.watch(profileCardProvider(widget.profileId));
    if (data == null) return const SizedBox.shrink();

    final isActive = widget.profileId == widget.activeProfileId;
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);

    return Card(
      color: cs.surfaceContainer,
      clipBehavior: Clip.antiAlias,
      elevation: isActive ? 0 : 3,
      shape: isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primaryContainer, width: 3),
            )
          : null,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      data.name,
                      style: tt.titleLarge,
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
                            child: ProfileControlTile(
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
                          ProfileWeaponSection(
                            data: data,
                            onEdit: widget.onEditWeapon,
                          ),
                          if (data.ammoId != null)
                            ProfileAmmoSection(
                              data: data,
                              onEdit: widget.onEditAmmo,
                            ),
                          if (data.sightId != null)
                            ProfileSightSection(
                              data: data,
                              onEdit: widget.onEditSight,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _ProfileActionsBar(
            isActive: isActive,
            isComplete: data.ammoId != null && data.sightId != null,
            onSelect: widget.onSelect,
          ),
        ],
      ),
    );
  }
}

// ── Actions Bar ───────────────────────────────────────────────────────────────

class _ProfileActionsBar extends StatelessWidget {
  const _ProfileActionsBar({
    required this.isActive,
    required this.isComplete,
    required this.onSelect,
  });

  final bool isActive;
  final bool isComplete;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (isComplete) {
      return ColoredBox(
        color: cs.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: FilledButton(
            onPressed: onSelect,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
            child: Text(
              !isActive ? l10n.selectButton : l10n.goToCalculationsButton,
            ),
          ),
        ),
      );
    }

    return ColoredBox(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            l10n.selectAmmoSightHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onErrorContainer),
          ),
        ),
      ),
    );
  }
}
