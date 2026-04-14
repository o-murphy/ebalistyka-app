import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/profile_card.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/pages_dots_indicator.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/confirm_dialog.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:ebalistyka/shared/widgets/text_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  String? _currentProfileId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page, List<String> orderedIds) {
    setState(() {
      _currentPage = page;
      if (page < orderedIds.length) {
        _currentProfileId = orderedIds[page];
      }
    });
  }

  void _navigateTo(int page, String profileId, {bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _currentProfileId = profileId;
      });
      if (_pageController.hasClients) {
        if (animate) {
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.jumpToPage(page);
        }
      }
    });
  }

  // ── Add (bottom sheet) ────────────────────────────────────────────────────

  Future<String?> _askProfileName({String? initial}) => showTextInputDialog(
    context,
    title: 'New Profile',
    initialValue: initial,
    labelText: 'Profile name',
    confirmLabel: 'Next',
  );

  Future<void> _showAddSheet() => showActionSheet(
    context,
    title: 'Add Profile',
    entries: [
      ActionSheetItem(
        icon: IconDef.addCircle,
        title: 'Create new',
        onTap: () async {
          final name = await _askProfileName();
          if (name == null || !mounted) return;
          final weapon = await context.push<Weapon?>(
            Routes.profileAddWeaponCreate,
          );
          if (weapon != null && mounted) {
            await ref
                .read(profilesActionsProvider.notifier)
                .createProfile(name, weapon);
          }
        },
      ),
      ActionSheetItem(
        icon: IconDef.openCollection,
        title: 'From collection',
        onTap: () async {
          final name = await _askProfileName();
          if (name != null && mounted) {
            context.push(Routes.profileAddWeaponCollection, extra: name);
          }
        },
      ),
      ActionSheetItem(
        icon: IconDef.import,
        title: 'Import from file',
        onTap: () async => showNotAvailableSnackBar(context, 'Import'),
      ),
    ],
  );

  // ── Actions (by profile ID) ───────────────────────────────────────────────

  Future<void> _onDuplicate(String profileId) async {
    final originalName = ref.read(profileCardProvider(profileId))?.name;
    if (originalName == null || !mounted) return;
    final name = await _askProfileName(initial: 'Copy of $originalName');
    if (name == null || !mounted) return;
    await ref
        .read(profilesActionsProvider.notifier)
        .duplicateProfile(profileId, name);
  }

  Future<void> _onRemove(String profileId) async {
    final name = ref.read(profileCardProvider(profileId))?.name;
    if (name == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove profile',
      content: 'Remove "$name" and its weapon?',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed) {
      await ref.read(profilesActionsProvider.notifier).removeProfile(profileId);
    }
  }

  Future<void> _onExport(String profileId) async {
    // TODO: serialize profile and share (Phase 5+)
  }

  Future<void> _onEditRifle(String profileId) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles
        .where((p) => p.id.toString() == profileId)
        .firstOrNull;
    if (profile == null) return;

    final weapon = appState.weapons
        .where((w) => w.id == profile.weapon.targetId)
        .firstOrNull;

    final result = await context.push<Weapon?>(
      Routes.profileEditWeapon,
      extra: weapon,
    );
    if (result != null && mounted) {
      await ref.read(appStateProvider.notifier).saveWeapon(result);
    }
  }

  Future<void> _onEditAmmo(String profileId) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles
        .where((p) => p.id.toString() == profileId)
        .firstOrNull;
    if (profile == null) return;

    final weapon = appState.weapons
        .where((w) => w.id == profile.weapon.targetId)
        .firstOrNull;
    final ammo = appState.cartridges
        .where((a) => a.id == profile.ammo.targetId)
        .firstOrNull;

    final result = await context.push<Ammo?>(
      Routes.profileEditAmmo,
      extra: (ammo, weapon?.caliberInch),
    );
    if (result != null && mounted) {
      await ref.read(appStateProvider.notifier).saveAmmo(result);
    }
  }

  Future<void> _onEditSight(String profileId) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles
        .where((p) => p.id.toString() == profileId)
        .firstOrNull;
    if (profile == null) return;

    final sight = appState.sights
        .where((s) => s.id == profile.sight.targetId)
        .firstOrNull;

    final result = await context.push<Sight?>(
      Routes.profileEditSight,
      extra: sight,
    );
    if (result != null && mounted) {
      await ref.read(appStateProvider.notifier).saveSight(result);
    }
  }

  Future<void> _onRename(String profileId, String name) async {
    await ref
        .read(profilesActionsProvider.notifier)
        .renameProfile(profileId, name);
  }

  Future<void> _onSelect(String profileId) async {
    await ref.read(profilesActionsProvider.notifier).selectProfile(profileId);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // ── Paging listener ───────────────────────────────────────────────────────
    // Fires ONLY when profiles are added/removed or the active profile changes.
    // Content-only changes (ammo, sight, weapon edits) do NOT fire this because
    // profilesPagingProvider uses proper == on its output.
    ref.listen<ProfilesPagingState>(profilesPagingProvider, (prev, next) {
      if (next.orderedIds.isEmpty) return;

      if (prev == null) {
        // Initial — seed current profile ID without jumping.
        _currentProfileId ??=
            next.orderedIds[_currentPage.clamp(0, next.orderedIds.length - 1)];
        return;
      }

      if (next.orderedIds.length > prev.orderedIds.length) {
        // Profile added → jump to last page.
        final last = next.orderedIds.length - 1;
        _navigateTo(last, next.orderedIds[last], animate: true);
      } else if (next.orderedIds.length < prev.orderedIds.length) {
        // Profile deleted → stay on nearest valid page, only if current gone.
        final exists = next.orderedIds.contains(_currentProfileId);
        if (!exists) {
          final page = _currentPage.clamp(0, next.orderedIds.length - 1);
          _navigateTo(page, next.orderedIds[page]);
        }
      } else if (next.activeId != prev.activeId) {
        // Active profile changed → sort changed → jump to page 0.
        _navigateTo(0, next.orderedIds.first);
      }
      // Same structure → content-only change → no paging update.
    });

    // ── Paging state ──────────────────────────────────────────────────────────
    final paging = ref.watch(profilesPagingProvider);

    if (paging.orderedIds.isEmpty) {
      return BaseScreen(
        title: 'Select Profile',
        floatingActionButton: FloatingActionButton(
          heroTag: 'generalFab',
          onPressed: _showAddSheet,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 6,
          child: const Icon(IconDef.add),
        ),
        body: const Center(child: Text('No profiles. Tap + to add one.')),
      );
    }

    return BaseScreen(
      title: "My Profiles",
      floatingActionButton: FloatingActionButton(
        heroTag: 'generalFab',
        onPressed: _showAddSheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 6,
        child: const Icon(IconDef.add),
      ),
      body: _ProfilePageView(
        orderedIds: paging.orderedIds,
        activeProfileId: paging.activeId,
        pageController: _pageController,
        currentPage: _currentPage,
        onPageChanged: (page) => _onPageChanged(page, paging.orderedIds),
        onSelect: _onSelect,
        onEditRifle: _onEditRifle,
        onEditAmmo: _onEditAmmo,
        onEditSight: _onEditSight,
        onDuplicate: _onDuplicate,
        onExport: _onExport,
        onRemove: _onRemove,
        onRename: _onRename,
      ),
    );
  }
}

// ── Profile Page View ─────────────────────────────────────────────────────────

class _ProfilePageView extends StatelessWidget {
  const _ProfilePageView({
    required this.orderedIds,
    required this.activeProfileId,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSelect,
    required this.onEditRifle,
    required this.onEditAmmo,
    required this.onEditSight,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
    required this.onRename,
  });

  final List<String> orderedIds;
  final String? activeProfileId;
  final PageController pageController;
  final int currentPage;
  final void Function(int) onPageChanged;
  final void Function(String) onSelect;
  final void Function(String) onEditRifle;
  final void Function(String) onEditAmmo;
  final void Function(String) onEditSight;
  final void Function(String) onDuplicate;
  final void Function(String) onExport;
  final void Function(String) onRemove;
  final void Function(String, String) onRename;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: orderedIds
                .map(
                  (id) => Padding(
                    key: ValueKey(id),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ProfileCard(
                      profileId: id,
                      activeProfileId: activeProfileId,
                      onSelect: () => onSelect(id),
                      onEditWeapon: () => onEditRifle(id),
                      onEditAmmo: () => onEditAmmo(id),
                      onEditSight: () => onEditSight(id),
                      onDuplicate: () => onDuplicate(id),
                      onExport: () => onExport(id),
                      onRemove: () => onRemove(id),
                      onRename: (name) => onRename(id, name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        PageDotsIndicator(
          current: currentPage,
          count: orderedIds.length,
          onPageChanged: (page) {
            pageController.animateToPage(
              page,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
