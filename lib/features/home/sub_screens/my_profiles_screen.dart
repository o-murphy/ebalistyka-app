import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/profile_card.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/pages_dots_indicator.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
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

  void _onPageChanged(int page) {
    final state = ref.read(profilesVmProvider).value;
    setState(() {
      _currentPage = page;
      if (state is ProfilesReady && page < state.profiles.length) {
        _currentProfileId = state.profiles[page].id;
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

  String _titleFor(ProfilesUiState state) {
    if (state is! ProfilesReady || state.profiles.isEmpty) {
      return 'Select Profile';
    }
    final idx = _currentPage.clamp(0, state.profiles.length - 1);
    return state.profiles[idx].name;
  }

  ProfileCardData? _currentProfile(ProfilesUiState state) {
    if (state is! ProfilesReady || state.profiles.isEmpty) return null;
    final idx = _currentPage.clamp(0, state.profiles.length - 1);
    return state.profiles[idx];
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
        icon: Icons.add_circle_outline,
        title: 'Create new',
        onTap: () async {
          final name = await _askProfileName();
          if (name == null || !mounted) return;
          final weapon = await context.push<Weapon?>(
            Routes.profileAddWeaponCreate,
          );
          if (weapon != null && mounted) {
            await ref
                .read(profilesVmProvider.notifier)
                .createProfile(name, weapon);
          }
        },
      ),
      ActionSheetItem(
        icon: Icons.folder_open_outlined,
        title: 'From collection',
        onTap: () async {
          final name = await _askProfileName();
          if (name != null && mounted) {
            context.push(Routes.profileAddWeaponCollection, extra: name);
          }
        },
      ),
      ActionSheetItem(
        icon: Icons.file_open_outlined,
        title: 'Import from file',
        onTap: () async => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import not yet available')),
        ),
      ),
    ],
  );

  // ── FAB actions (current profile) ─────────────────────────────────────────

  Future<void> _onDuplicate(ProfileCardData? profile) async {
    // TODO: make profile copy with name input dialog
  }

  Future<void> _onRemove(ProfileCardData? profile) async {
    if (profile == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove profile'),
        content: Text('Remove "${profile.name}" and its weapon?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profilesVmProvider.notifier).removeProfile(profile.id);
      // _syncPage handles page adjustment when the VM emits the updated list.
    }
  }

  Future<void> _onExport(ProfileCardData? profile) async {
    if (profile == null) return;
    // TODO: serialize profile and share (Phase 5+)
  }

  Future<void> _onEditRifle(ProfileCardData data) async {
    final appState = ref.read(appStateProvider).value;
    if (appState == null) return;

    final profile = appState.profiles
        .where((p) => p.id.toString() == data.id)
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

  Future<void> _onRename(ProfileCardData profile, String name) async {
    await ref.read(profilesVmProvider.notifier).renameProfile(profile.id, name);
  }

  Future<void> _onSelect(ProfileCardData profile) async {
    await ref.read(profilesVmProvider.notifier).selectProfile(profile.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ProfilesUiState>>(profilesVmProvider, (prev, next) {
      final prevData = prev?.value;
      final nextData = next.value;
      if (nextData is! ProfilesReady || nextData.profiles.isEmpty) return;

      if (prevData == null) {
        // Initial load — seed _currentProfileId without jumping.
        _currentProfileId ??= nextData
            .profiles[_currentPage.clamp(0, nextData.profiles.length - 1)]
            .id;
        return;
      }

      if (prevData is! ProfilesReady) return;

      if (nextData.profiles.length > prevData.profiles.length) {
        // Profile added → jump to last page.
        final last = nextData.profiles.length - 1;
        _navigateTo(last, nextData.profiles[last].id, animate: true);
      } else if (nextData.profiles.length < prevData.profiles.length) {
        // Profile deleted → nearest valid page (only if current was removed).
        final exists = nextData.profiles.any((p) => p.id == _currentProfileId);
        if (!exists) {
          final page = _currentPage.clamp(0, nextData.profiles.length - 1);
          _navigateTo(page, nextData.profiles[page].id);
        }
      }
      // Same count → ammo/weapon/sight update — do not change page.
    });
    final vmState = ref.watch(profilesVmProvider);

    return vmState.when(
      skipLoadingOnRefresh: true,
      loading: () => BaseScreen(
        title: 'Select Profile',
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => BaseScreen(
        title: 'Select Profile',
        body: Center(child: Text('Error: $err')),
      ),
      data: (state) {
        final profile = _currentProfile(state);
        return BaseScreen(
          title: _titleFor(state),
          floatingActionButton: FloatingActionButton(
            heroTag: "generalFab",
            onPressed: _showAddSheet,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 6,
            child: const Icon(Icons.add_outlined),
          ),
          body: state is ProfilesReady && state.profiles.isNotEmpty
              ? _ProfilePageView(
                  profiles: state.profiles,
                  activeProfileId: state.activeProfileId,
                  pageController: _pageController,
                  currentPage: _currentPage,
                  onPageChanged: _onPageChanged,
                  onSelect: _onSelect,
                  onEditRifle: _onEditRifle,
                  onDuplicate: () => _onDuplicate(profile),
                  onExport: () => _onExport(profile),
                  onRemove: () => _onRemove(profile),
                  onRename: _onRename,
                )
              : const Center(child: Text('No profiles. Tap + to add one.')),
        );
      },
    );
  }
}

// ── Profile Page View ─────────────────────────────────────────────────────────

class _ProfilePageView extends StatelessWidget {
  const _ProfilePageView({
    required this.profiles,
    required this.activeProfileId,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onSelect,
    required this.onEditRifle,
    required this.onDuplicate,
    required this.onExport,
    required this.onRemove,
    required this.onRename,
  });

  final List<ProfileCardData> profiles;
  final String? activeProfileId;
  final PageController pageController;
  final int currentPage;
  final void Function(int) onPageChanged;
  final void Function(ProfileCardData) onSelect;
  final void Function(ProfileCardData) onEditRifle;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onRemove;
  final void Function(ProfileCardData, String) onRename;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: onPageChanged,
            children: profiles
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ProfileCard(
                      data: p,
                      isActive: p.id == activeProfileId,
                      onSelect: () => onSelect(p),
                      onEditWeapon: () => onEditRifle(p),
                      onDuplicate: onDuplicate,
                      onExport: onExport,
                      onRemove: onRemove,
                      onRename: (name) => onRename(p, name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        PageDotsIndicator(
          current: currentPage,
          count: profiles.length,
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
