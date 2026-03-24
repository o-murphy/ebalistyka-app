import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calculation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shot_profile_provider.dart';
import '../router.dart';
import '../src/models/field_constraints.dart';
import '../src/solver/conditions.dart' as solver;
import '../src/solver/unit.dart' as solver;
import '../src/solver/unit.dart';
import '../widgets/home_chart_page.dart';
import '../widgets/home_reticle_page.dart';
import '../widgets/home_table_page.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/side_control_block.dart';
import '../widgets/unit_value_field.dart';
import '../widgets/wind_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(shotProfileProvider).value;
    final units   = ref.watch(unitSettingsProvider);

    final rifleName     = profile?.rifle.name     ?? '—';
    final cartridgeName = profile?.cartridge.name ?? '—';

    String dimStr(dynamic dim, Unit rawUnit, Unit dispUnit, {int dec = 0}) {
      if (dim == null) return '—';
      final raw  = (dim as dynamic).in_(rawUnit) as double;
      final disp = (rawUnit(raw) as dynamic).in_(dispUnit) as double;
      return '${disp.toStringAsFixed(dec)} ${dispUnit.symbol}';
    }

    final windDirDeg     = profile?.winds.isNotEmpty == true
        ? (profile!.winds.first.directionFrom as dynamic).in_(solver.Unit.degree) as double
        : 0.0;
    final windInitialAngle = (windDirDeg - 90) * math.pi / 180;

    final conditions = profile?.conditions;
    final tempStr    = dimStr(conditions?.temperature, Unit.celsius,  units.temperature);
    final altStr     = dimStr(conditions?.altitude,    Unit.meter,    units.distance);
    final pressStr   = dimStr(conditions?.pressure,    Unit.hPa,      units.pressure);
    final humidStr   = conditions != null
        ? '${(conditions.humidity * 100).toStringAsFixed(0)}%'
        : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTopH = 350.0;
        const minBotH = 300.0;
        final totalH        = math.max(constraints.maxHeight, minTopH + minBotH);
        final topBlockHeight = math.max(totalH * 0.55, minTopH);
        final botBlockHeight = totalH - topBlockHeight;

        return SingleChildScrollView(
          physics: totalH > constraints.maxHeight
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: totalH,
            child: Column(
              children: [
                // ── Top block ───────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: topBlockHeight,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                      bottomLeft:  Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                      child: Column(
                        children: [
                          // Rifle / cartridge selector row
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonal(
                                  onPressed: () => context.push(Routes.rifleSelect),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '$rifleName · $cartridgeName',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.more_horiz_rounded),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                onPressed: () => context.push(Routes.projectileSelect),
                                icon: const Icon(Icons.rocket_launch_outlined),
                              ),
                            ],
                          ),

                          // Wind indicator + side controls
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: SideControlBlock(
                                      topIcon:    Icons.info_outline,
                                      bottomIcon: Icons.note_add_outlined,
                                      infoRows: [
                                        (Icons.device_thermostat_outlined, tempStr),
                                        (Icons.terrain_outlined,           altStr),
                                      ],
                                      onTopPressed:    () => context.push(Routes.shotDetails),
                                      onBottomPressed: () {},
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: WindIndicator(
                                      initialAngle: windInitialAngle,
                                      onAngleChanged: (degrees, _) {
                                        final existing = ref.read(shotProfileProvider).value?.winds ?? [];
                                        ref.read(shotProfileProvider.notifier).updateWinds([
                                          solver.Wind(
                                            velocity:      existing.isNotEmpty ? existing.first.velocity : solver.Velocity(0, solver.Unit.mps),
                                            directionFrom: solver.Angular(degrees, solver.Unit.degree),
                                          ),
                                        ]);
                                      },
                                      onDirectionTap: (deg) => showUnitEditDialog(
                                        context,
                                        label: 'Wind direction',
                                        rawValue: deg,
                                        constraints: FC.windDirection,
                                        displayUnit: Unit.degree,
                                        onChanged: (newDeg) {
                                          final normalized = ((newDeg % 360) + 360) % 360;
                                          final existing = ref.read(shotProfileProvider).value?.winds ?? [];
                                          ref.read(shotProfileProvider.notifier).updateWinds([
                                            solver.Wind(
                                              velocity:      existing.isNotEmpty ? existing.first.velocity : solver.Velocity(0, solver.Unit.mps),
                                              directionFrom: solver.Angular(normalized, solver.Unit.degree),
                                            ),
                                          ]);
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: SideControlBlock(
                                      topIcon:    Icons.question_mark_outlined,
                                      bottomIcon: Icons.more_horiz_outlined,
                                      infoRows: [
                                        (Icons.water_drop_outlined, humidStr),
                                        (Icons.speed_outlined,      pressStr),
                                      ],
                                      onTopPressed:    () {},
                                      onBottomPressed: () {},
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 80, child: const QuickActionsPanel()),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom block — 3 pages ───────────────────────────────────
                SizedBox(
                  height: botBlockHeight,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (i) => setState(() => _currentPage = i),
                              children: const [
                                HomeReticlePage(),
                                HomeTablePage(),
                                HomeChartPage(),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: _PageDots(current: _currentPage, count: 3),
                          ),
                        ],
                      ),
                      if (ref.watch(homeCalculationProvider).isLoading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Page dots indicator ──────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  const _PageDots({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width:  active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.onSurface.withAlpha(60),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
