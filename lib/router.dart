import 'package:ebalistyka/features/convertors/sub_screens/convertors_sub_screens.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/features/home/sub_screens/weapon_wizard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/recalc_coordinator.dart';

import 'features/home/home_screen.dart';
import 'features/home/sub_screens/home_sub_screens.dart';
import 'features/conditions/conditions_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/tables/sub_screens/tables_config_screen.dart';
import 'features/convertors/convertor_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/sub_screens/settings_units_screen.dart';
import 'features/settings/sub_screens/settings_adjustment_screen.dart';

// ─── Route paths ─────────────────────────────────────────────────────────────

abstract final class Routes {
  // Primary
  static const home = '/home';
  static const conditions = '/conditions';
  static const tables = '/tables';
  static const convertors = '/convertors';
  static const settings = '/settings';

  // Home stack — shot info
  static const shotDetails = '/home/shot-details';

  // Profile (profiles) stack
  static const profiles = '/home/profiles';

  // Profile add — weapon selection
  static const profileAddWeaponCreate = '/home/profiles/weapon-create';
  static const profileAddWeaponCollection = '/home/profiles/weapon-collection';

  // Ammo select (from profile card)
  static const ammoSelect = '/home/profiles/ammo-select';
  static const ammoCreate = '/home/profiles/ammo-select/create';
  static const cartridgeCollection =
      '/home/profiles/ammo-select/cartridge-collection';
  static const bulletCollection =
      '/home/profiles/ammo-select/bullet-collection';

  // Sight select (from profile card)
  static const sightSelect = '/home/profiles/sight-select';
  static const sightCreate = '/home/profiles/sight-select/create';
  static const sightCollection = '/home/profiles/sight-select/collection';

  // Profile inline edits (from profile card)
  static const profileEditWeapon = '/home/profiles/weapon-edit';
  static const profileEditAmmo = '/home/profiles/ammo-edit';
  static const profileEditSight = '/home/profiles/sight-edit';

  // Tables stack
  static const tableConfig = '/tables/configure';

  // Convertors stack
  static const convertor = '/convertors/:type';
  static String convertorOf(String type) => '/convertors/$type';

  // Settings stack
  static const settingsUnits = '/settings/units';
  static const settingsAdjustment = '/settings/adjustment';
}

// ─── Router ──────────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: Routes.home,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => _ScaffoldWithNav(shell: shell),
      branches: [
        // ── Home branch ──────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'shot-details',
                  builder: (_, _) => const ShotDetailsScreen(),
                ),
                GoRoute(
                  path: 'profiles',
                  builder: (_, _) => const ProfilesScreen(),
                  routes: [
                    // ── Profile add ─────────────────────────────────────────
                    GoRoute(
                      path: 'weapon-create',
                      builder: (_, _) => const WeaponWizardScreen(),
                    ),
                    GoRoute(
                      path: 'weapon-collection',
                      builder: (_, _) => const WeaponCollectionScreen(),
                    ),
                    // ── Ammo select ─────────────────────────────────────────
                    GoRoute(
                      path: 'ammo-select',
                      builder: (_, state) =>
                          MyAmmoScreen(profileId: state.extra as String?),
                      routes: [
                        GoRoute(
                          path: 'create',
                          builder: (_, state) => AmmoWizardScreen(
                            caliberInch: state.extra as double?,
                          ),
                        ),
                        GoRoute(
                          path: 'cartridge-collection',
                          builder: (_, _) =>
                              const AmmoCollectionScreen(filterBullet: false),
                        ),
                        GoRoute(
                          path: 'bullet-collection',
                          builder: (_, _) =>
                              const AmmoCollectionScreen(filterBullet: true),
                        ),
                      ],
                    ),
                    // ── Sight select ────────────────────────────────────────
                    GoRoute(
                      path: 'sight-select',
                      builder: (_, state) => MySightsCollectionScreen(
                        profileId: state.extra as String?,
                      ),
                      routes: [
                        GoRoute(
                          path: 'create',
                          builder: (_, _) => const SightWizardScreen(),
                        ),
                        GoRoute(
                          path: 'collection',
                          builder: (_, _) => const SightCollectionScreen(),
                        ),
                      ],
                    ),
                    // ── Profile inline edits ────────────────────────────────
                    GoRoute(
                      path: 'weapon-edit',
                      builder: (_, state) =>
                          WeaponWizardScreen(initial: state.extra as Weapon?),
                    ),
                    GoRoute(
                      path: 'ammo-edit',
                      builder: (_, state) =>
                          AmmoWizardScreen(initial: state.extra as Ammo?),
                    ),
                    GoRoute(
                      path: 'sight-edit',
                      builder: (_, state) =>
                          SightWizardScreen(initial: state.extra as Sight?),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Conditions branch ────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.conditions,
              builder: (_, _) => const ConditionsScreen(),
            ),
          ],
        ),

        // ── Tables branch ────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.tables,
              builder: (_, _) => const TablesScreen(),
              routes: [
                GoRoute(
                  path: 'configure',
                  builder: (_, _) => const TableConfigScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Convertors branch ────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.convertors,
              builder: (_, _) => const ConvertorScreen(),
              routes: [
                GoRoute(
                  path: 'target-distance',
                  builder: (_, _) => const DistanceConvertorScreen(),
                ),
                GoRoute(
                  path: 'velocity',
                  builder: (_, _) => const VelocityConvertorScreen(),
                ),
                GoRoute(
                  path: 'length',
                  builder: (_, _) => const LengthConvertorScreen(),
                ),
                GoRoute(
                  path: 'weight',
                  builder: (_, _) => const WeightConvertorScreen(),
                ),
                GoRoute(
                  path: 'pressure',
                  builder: (_, _) => const PressureConvertorScreen(),
                ),
                GoRoute(
                  path: 'temperature',
                  builder: (_, _) => const TemperatureConvertorScreen(),
                ),
                GoRoute(
                  path: 'angular',
                  builder: (_, _) => const AnglesConvertorScreen(),
                ),
                GoRoute(
                  path: 'torque',
                  builder: (_, _) => const TorqueConvertorScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Settings branch ──────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'units', builder: (_, _) => const UnitsScreen()),
                GoRoute(
                  path: 'adjustment',
                  builder: (_, _) => const AdjustmentDisplayScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

// ─── Shell with persistent bottom nav ────────────────────────────────────────

class _ScaffoldWithNav extends ConsumerStatefulWidget {
  const _ScaffoldWithNav({required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<_ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<_ScaffoldWithNav> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recalcCoordinatorProvider.notifier)
          .onTabActivated(widget.shell.currentIndex);
    });
  }

  void _onTabSelected(int i) {
    widget.shell.goBranch(i, initialLocation: true);
    ref.read(recalcCoordinatorProvider.notifier).onTabActivated(i);
  }

  @override
  Widget build(BuildContext context) {
    // Initialise the coordinator — it sets up its own listeners.
    ref.watch(recalcCoordinatorProvider);

    return Scaffold(
      body: SafeArea(child: widget.shell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.shell.currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(IconDef.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(IconDef.tables),
            label: 'Conditions',
          ),
          NavigationDestination(icon: Icon(IconDef.tables), label: 'Tables'),
          NavigationDestination(
            icon: Icon(IconDef.convertors),
            label: 'Convertors',
          ),
          NavigationDestination(
            icon: Icon(IconDef.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
