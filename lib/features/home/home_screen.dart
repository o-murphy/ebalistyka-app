import 'dart:async';
import 'dart:math' as math;

import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/help_dialog.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:ebalistyka/shared/widgets/pages_dots_indicator.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ebalistyka/router.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/widgets/home_chart_page.dart';
import 'package:ebalistyka/features/home/widgets/home_reticle_page.dart';
import 'package:ebalistyka/features/home/widgets/home_table_page.dart';
import 'package:ebalistyka/features/home/widgets/quick_actions_panel.dart';
import 'package:ebalistyka/features/home/widgets/side_control_block.dart';
import 'package:ebalistyka/features/home/widgets/wind_indicator.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/update/update_checker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

  late final _calcDoneCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  // Fade in → hold briefly → fade out
  late final _calcDoneAnim = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
  ]).animate(_calcDoneCtrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIsFirstRun());
  }

  Future<void> _checkIsFirstRun() async {
    final isNewVersion = await checkIsNewVersion();
    if (!mounted) return;
    if (isNewVersion) {
      await _onNewVersion();
    } else {}
  }

  Future<void> _onNewVersion() async {
    debugPrint('changelog dialog yet not implemented');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _calcDoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trigger overlay animation when VM transitions from Loading → Ready.
    ref.listen<AsyncValue<HomeUiState>>(homeVmProvider, (prev, next) {
      final wasLoading = prev?.isLoading == true;
      final isReady = next.value is HomeUiReady;
      if (wasLoading && isReady) unawaited(_calcDoneCtrl.forward(from: 0));
    });

    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    final profileName = vmState is HomeUiReady ? vmState.profileName : nullStr;
    final cs = vmState is HomeUiReady ? vmState.conditionsState : null;
    final tempStr = cs?.tempDisplay ?? nullStr;
    final altStr = cs?.altDisplay ?? nullStr;
    final pressStr = cs?.pressDisplay ?? nullStr;
    final humidStr = cs?.humidDisplay ?? nullStr;
    final windAngleDeg = cs?.windAngleDeg ?? 0.0;
    final windInitialAngle = (windAngleDeg - 90) * math.pi / 180;

    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        const bottomHeight = 60.0; // Fixed height of paging indicator
        const minTopH = 350.0;
        const maxTopH = 400.0;
        const minCentralH = 300.0;

        // Height for scrollable content (Top + Central)
        final scrollableHeight = math.max(
          constraints.maxHeight - bottomHeight,
          minTopH + minCentralH,
        );

        // Calculating the height of the top block
        final topBlockHeight = math.min(
          maxTopH,
          math.max(scrollableHeight * 0.55, minTopH),
        );

        // Height of the center block (what's left)
        final centralBlockHeight = scrollableHeight - topBlockHeight;

        // Is scrolling needed?
        final needsScroll =
            scrollableHeight > constraints.maxHeight - bottomHeight;

        final cs = Theme.of(context).colorScheme;

        UnitPickerContext getWindDirCtx(deg) => UnitPickerContext(
          context,
          label: l10n.windDirection,
          rawValue: deg,
          constraints: FC.windDirection,
          displayUnit: Unit.degree,
          onChanged: (v) {
            final normalized = (((v! % 360) + 360) % 360);
            unawaited(
              ref.read(homeVmProvider.notifier).updateWindDirection(normalized),
            );
          },
        );

        String pageName = switch (_currentPage) {
          0 => l10n.pageHoldovers,
          1 => l10n.pageTrajectoryInfo,
          2 => l10n.pageTrajectoryChart,
          _ => '',
        };

        return Stack(
          children: [
            // Scrollable content (Top + Central)
            SingleChildScrollView(
              physics: needsScroll
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Top block ───────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    height: topBlockHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
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
                                    onPressed: () =>
                                        context.push(Routes.profiles),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            profileName,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(IconDef.moreHoriz),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (vmState is HomeUiReady)
                                  IconButton.filledTonal(
                                    onPressed: () async {
                                      final appState = ref
                                          .read(appStateProvider)
                                          .value;
                                      final profile = appState?.activeProfile;
                                      final ammo = appState?.ammo
                                          .where(
                                            (a) =>
                                                a.id == profile?.ammo.targetId,
                                          )
                                          .firstOrNull;
                                      final weapon = appState?.weapons
                                          .where(
                                            (w) =>
                                                w.id ==
                                                profile?.weapon.targetId,
                                          )
                                          .firstOrNull;
                                      if (ammo == null) return;
                                      final result = await context.push<Ammo?>(
                                        Routes.profileEditAmmo,
                                        extra: (
                                          ammo,
                                          weapon?.caliberInch,
                                          weapon?.id,
                                        ),
                                      );
                                      if (result != null && context.mounted) {
                                        await ref
                                            .read(appStateProvider.notifier)
                                            .saveAmmo(result);
                                      }
                                    },
                                    icon: const Icon(IconDef.ammo),
                                  ),
                              ],
                            ),

                            // Wind indicator + side controls
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  12,
                                  0,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: SideControlBlock(
                                        topIcon: Icons.info_outline,
                                        bottomIcon: Icons.note_add_outlined,
                                        infoRows: [
                                          (
                                            IconDef.temperature,
                                            // Colors.green,
                                            cs.onSurface.withValues(
                                              alpha: 0.65,
                                            ),
                                            l10n.temperature,
                                            tempStr,
                                          ),
                                          (
                                            IconDef.altitude,
                                            // Colors.green,
                                            cs.onSurface.withValues(
                                              alpha: 0.65,
                                            ),
                                            l10n.altitude,
                                            altStr,
                                          ),
                                        ],
                                        onTopPressed: () =>
                                            context.push(Routes.shotInfo),
                                        onBottomPressed: () =>
                                            showNotAvailableSnackBar(
                                              context,
                                              l10n.notesScreenTitle,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: WindIndicator(
                                        initialAngle: windInitialAngle,
                                        onAngleChanged: (degrees, _) {
                                          unawaited(
                                            ref
                                                .read(homeVmProvider.notifier)
                                                .updateWindDirection(degrees),
                                          );
                                        },
                                        onDirectionTap: (deg) =>
                                            showUnitEditDialog(
                                              getWindDirCtx(deg),
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: SideControlBlock(
                                        topIcon: IconDef.help,
                                        bottomIcon: IconDef.moreHoriz,
                                        infoRows: [
                                          (
                                            IconDef.humidity,
                                            // Colors.blue,
                                            cs.onSurface.withValues(
                                              alpha: 0.65,
                                            ),
                                            l10n.humidity,
                                            humidStr,
                                          ),
                                          (
                                            IconDef.velocity,
                                            // Colors.red,
                                            cs.onSurface.withValues(
                                              alpha: 0.65,
                                            ),
                                            l10n.pressure,
                                            pressStr,
                                          ),
                                        ],
                                        onTopPressed: () => showHelpDialog(
                                          context,
                                          title: l10n.helpTitle,
                                          helpId: HelpData.homeScreen,
                                        ),
                                        onBottomPressed: () =>
                                            showNotAvailableSnackBar(
                                              context,
                                              l10n.toolsScreenTitle,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(
                              height: 80,
                              child: const QuickActionsPanel(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Central block — 3 pages ───────────────────────────────────
                  SizedBox(
                    height: centralBlockHeight,
                    child: vmState is HomeUiNoData
                        ? EmptyStatePlaceholder(
                            type: vmState.type,
                            message: vmState.message,
                          )
                        : Stack(
                            children: [
                              Column(
                                children: [
                                  Expanded(
                                    child: PageView(
                                      controller: _pageController,
                                      onPageChanged: (i) =>
                                          setState(() => _currentPage = i),
                                      children: const [
                                        HomeReticlePage(),
                                        HomeTablePage(),
                                        HomeChartPage(),
                                      ],
                                    ),
                                  ),
                                  // Padding for spacing - bottom indicator will overlay
                                  const SizedBox(height: 8),
                                ],
                              ),
                              // Brief spinner overlay — fades in then out after each recalc.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: FadeTransition(
                                    opacity: _calcDoneAnim,
                                    child: Container(
                                      color: Colors.black.withAlpha(90),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Add bottom padding to prevent content from hiding under Bottom Block
                  if (vmState is! HomeUiNoData) SizedBox(height: bottomHeight),
                ],
              ),
            ),

            // ── Bottom Block — Fixed page indicator (sticky at bottom) ────────────
            if (vmState is! HomeUiNoData)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: bottomHeight,
                  alignment: Alignment.center,
                  color: cs.surface,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(pageName),
                      PageDotsIndicator(
                        current: _currentPage,
                        count: 3,
                        onPageChanged: (page) {
                          unawaited(
                            _pageController.animateToPage(
                              page,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                          );
                          setState(() => _currentPage = page);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
