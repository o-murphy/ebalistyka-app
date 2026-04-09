import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/home/profiles_vm.dart';
import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/profile_card.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/pages_dots_indicator.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

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

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Add Profile',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create new'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(Routes.profileAddWeaponCreate);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('From collection'),
              onTap: () {
                Navigator.pop(ctx);
                context.push(Routes.profileAddWeaponCollection);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text('Import from file'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import not yet available')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

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
        content: Text('Remove "${profile.name}"?'),
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
      if (_currentPage > 0) {
        setState(() => _currentPage = _currentPage - 1);
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
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

  Future<void> _onSelect(ProfileCardData profile) async {
    await ref.read(profilesVmProvider.notifier).selectProfile(profile.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(profilesVmProvider);

    return vmState.when(
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
