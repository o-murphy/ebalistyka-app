import 'dart:async';
import 'dart:math' as math;
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:bclibc_ffi/unit.dart' show Angular, Unit;
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/reticle_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_context_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/widgets/adjustment_panel.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/consts.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/click_label.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/offsets_edit.dart';
import 'package:ebalistyka/shared/widgets/reticle_view.dart';
import 'package:ebalistyka/shared/widgets/adjustment_input_with_clicks.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ReticleViewScreen extends ConsumerStatefulWidget {
  const ReticleViewScreen({super.key});

  @override
  ConsumerState<ReticleViewScreen> createState() => _ReticleViewScreenState();
}

class _ReticleViewScreenState extends ConsumerState<ReticleViewScreen> {
  final _zoomKey = GlobalKey<_ZoomableViewState>();

  // Barrel drums (ReticleSettings) — raw in FC.adjustment.rawUnit (mil)
  // null unit = clicks mode
  late double _vAdjRaw;
  Unit? _vAdjUnit;
  late double _hAdjRaw;
  Unit? _hAdjUnit;

  // ReticleSettings
  String? _targetImage;

  // Sight
  String? _reticleImage;
  late double _vClickRaw;
  late Unit _vClickUnit;
  late double _hClickRaw;
  late Unit _hClickUnit;

  @override
  void initState() {
    super.initState();
    final reticle = ref.read(reticleSettingsProvider);
    final vUnit = reticle.verticalAdjustmentUnitValue;
    _vAdjUnit = reticle.verticalAdjInClicks ? null : vUnit;
    _vAdjRaw = reticle.verticalAdjInClicks
        ? reticle.verticalAdjustment
        : Angular(reticle.verticalAdjustment, vUnit).in_(FC.adjustment.rawUnit);
    final hUnit = reticle.horizontalAdjustmentUnitValue;
    _hAdjUnit = reticle.horizontalAdjInClicks ? null : hUnit;
    _hAdjRaw = reticle.horizontalAdjInClicks
        ? reticle.horizontalAdjustment
        : Angular(
            reticle.horizontalAdjustment,
            hUnit,
          ).in_(FC.adjustment.rawUnit);
    _targetImage = reticle.targetImage;

    final ctx = ref.read(shotContextProvider).value;
    final s = ctx?.profile.sight.target;
    _reticleImage = s?.reticleImage;
    _vClickUnit = s?.verticalClickUnitValue ?? Unit.mil;
    _vClickRaw = s != null
        ? Angular(s.verticalClick, _vClickUnit).in_(FC.adjustment.rawUnit)
        : Angular.mil(0.1).in_(FC.adjustment.rawUnit);
    _hClickUnit = s?.horizontalClickUnitValue ?? Unit.mil;
    _hClickRaw = s != null
        ? Angular(s.horizontalClick, _hClickUnit).in_(FC.adjustment.rawUnit)
        : Angular.mil(0.1).in_(FC.adjustment.rawUnit);
  }

  Future<void> _saveAdj() async {
    await ref
        .read(homeVmProvider.notifier)
        .updateReticleAdjustments(
          vRaw: _vAdjRaw,
          vUnit: _vAdjUnit,
          hRaw: _hAdjRaw,
          hUnit: _hAdjUnit,
        );
  }

  Future<void> _saveSight() async {
    await ref
        .read(homeVmProvider.notifier)
        .updateSightClicks(
          vRaw: _vClickRaw,
          vUnit: _vClickUnit,
          hRaw: _hClickRaw,
          hUnit: _hClickUnit,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;
    final fmt = ref.watch(unitFormatterProvider);

    if (vmState is HomeUiNoData) {
      return EmptyStatePlaceholder(
        type: vmState.type,
        message: vmState.message,
      );
    }
    if (vmState is HomeUiError) {
      return Center(child: Text('Error: ${vmState.message}'));
    }
    if (vmAsync.isLoading || vmState is! HomeUiReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final targetSvgAsync = ref.watch(targetSvgProvider(_targetImage));
    final targetSizeMil = targetSvgAsync.whenData(_parseMilWidth).value ?? 0.0;
    final targetSizeMilAtDistance =
        targetSizeMil * 100 / vmState.conditionsState.targetDistanceM;
    final targetSizeDisplay = targetSizeMil >= 0.0
        ? fmt.targetSize(Angular.mil(targetSizeMil))
        : nullStr;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double maxTopHeightRatio = 0.50;
        final double fullHeight = constraints.maxHeight;
        final double maxAllowedHeight = fullHeight * maxTopHeightRatio;

        final double topBlockSize = math.min(
          constraints.maxWidth,
          maxAllowedHeight,
        );

        return BaseScreen(
          title: 'Reticle View',
          isSubscreen: true,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopBlock(
                context,
                topBlockSize,
                vmState,
                targetSizeMilAtDistance,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  child: ListView(
                    children: [
                      ListSectionTile('Adjustments'),
                      Center(
                        child: AdjustmentsDisplayPanel(
                          adjustment: vmState.reticleState.adjustment,
                          fmt: vmState.reticleState.adjustmentFormat,
                          isEmpty:
                              vmState.reticleState.adjustment.elevation.isEmpty,
                          displayVertical: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const TileDivider(),
                      const ListSectionTile('Barrel drums'),
                      listInputLabel(context, 'Vertical adjustment'),
                      AdjustmentInputWithClicks(
                        rawValue: _vAdjRaw,
                        constraints: FC.adjustment,
                        displayUnit: _vAdjUnit,
                        clickSizeRaw: _vClickRaw,
                        options: offsetUnits,
                        unitLabel: 'Adjustment unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _vAdjRaw = v);
                            unawaited(_saveAdj());
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _vAdjUnit = u);
                          unawaited(_saveAdj());
                        },
                      ),
                      listInputLabel(context, 'Horizontal adjustment'),
                      AdjustmentInputWithClicks(
                        rawValue: _hAdjRaw,
                        constraints: FC.adjustment,
                        displayUnit: _hAdjUnit,
                        clickSizeRaw: _hClickRaw,
                        options: offsetUnits,
                        unitLabel: 'Adjustment unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _hAdjRaw = v);
                            unawaited(_saveAdj());
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _hAdjUnit = u);
                          unawaited(_saveAdj());
                        },
                      ),
                      const TileDivider(),
                      const ListSectionTile('Target'),
                      ListTile(
                        leading: const Icon(IconDef.sight),
                        title: const Text('Target pattern'),
                        subtitle: Text(_targetImage ?? 'default'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await context.push<String?>(
                            Routes.reticleViewTargetPicker,
                            extra: _targetImage,
                          );
                          if (result != null && mounted) {
                            setState(() => _targetImage = result);
                            await ref
                                .read(homeVmProvider.notifier)
                                .updateTargetImage(result);
                          }
                        },
                        dense: true,
                      ),
                      InfoListTile(
                        label: 'Target size',
                        value: targetSizeDisplay,
                        icon: Icons.crop_free,
                      ),
                      const TileDivider(),
                      const ListSectionTile('Reticle'),
                      ListTile(
                        leading: const Icon(IconDef.sight),
                        title: const Text('Reticle pattern'),
                        subtitle: Text(_reticleImage ?? 'default'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final result = await context.push<String?>(
                            Routes.reticleViewReticlePicker,
                            extra: _reticleImage,
                          );
                          if (result != null && mounted) {
                            setState(() => _reticleImage = result);
                            await ref
                                .read(homeVmProvider.notifier)
                                .updateSightReticleImage(result);
                          }
                        },
                        dense: true,
                      ),
                      const TileDivider(),
                      const ListSectionTile('Clicks'),
                      listInputLabel(context, 'Vertical click'),
                      UnitInputWithPicker(
                        value: _vClickRaw,
                        constraints: FC.adjustment,
                        displayUnit: _vClickUnit,
                        options: offsetUnits,
                        unitLabel: 'Click unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _vClickRaw = v);
                            unawaited(_saveSight());
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _vClickUnit = u);
                          unawaited(_saveSight());
                        },
                      ),
                      listInputLabel(context, 'Horizontal click'),
                      UnitInputWithPicker(
                        value: _hClickRaw,
                        constraints: FC.adjustment,
                        displayUnit: _hClickUnit,
                        options: offsetUnits,
                        unitLabel: 'Click unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _hClickRaw = v);
                            unawaited(_saveSight());
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _hClickUnit = u);
                          unawaited(_saveSight());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBlock(
    BuildContext context,
    double size,
    HomeUiReady vmState,
    double targetSizeMil,
  ) {
    return SizedBox(
      width: double.infinity,
      height: size,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ZoomableView(
                    key: _zoomKey,
                    minScale: 1.0,
                    maxScale: 10.0,
                    child: ReticleView(
                      reticleImageId: _reticleImage,
                      targetImageId: _targetImage,
                      targetSizeMil: targetSizeMil,
                      offsetXMil: vmState.reticleState.adjustmentWindMil,
                      offsetYMil: vmState.reticleState.adjustmentElevMil,
                      clipRadius: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingActionButton(
                  onPressed: () => _zoomKey.currentState?.resetZoom(),
                  mini: true,
                  heroTag: null,
                  child: const Icon(IconDef.magnificationMin),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _parseMilWidth(String svg) {
    final m = RegExp(
      r'viewBox="[^"]*?\s+[^"]*?\s+([^"]*?)\s+[^"]*?"',
    ).firstMatch(svg);
    return m != null ? double.tryParse(m.group(1)!) ?? 0.5 : 0.0;
  }
}

// ── ZoomableView ──────────────────────────────────────────────────────────────

class ZoomableView extends StatefulWidget {
  const ZoomableView({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 10.0,
    this.initialScale = 1.0,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final double initialScale;

  @override
  State<ZoomableView> createState() => _ZoomableViewState();
}

class _ZoomableViewState extends State<ZoomableView>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (_animation != null) {
            _transformationController.value = _animation!.value;
          }
        });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void resetZoom() {
    _animateTransformation(Matrix4.identity());
  }

  void _animateTransformation(Matrix4 target) {
    _animation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: target,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    unawaited(_animationController.forward(from: 0));
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.1) {
      resetZoom();
    } else {
      if (_doubleTapDetails == null) return;

      final tapPos = _doubleTapDetails!.localPosition;
      const targetScale = 3.0; // Scale factor

      // For correct work of 2D transformations in Matrix4:
      // translateByDouble(x, y, z, w): w usually 1.0 for position in identical matrix
      // scaleByDouble(x, y, z, w): z=1.0 (to not flatten 2D), w=1.0 (diagonal)
      final targetMatrix = Matrix4.identity()
        ..translateByDouble(tapPos.dx, tapPos.dy, 0.0, 1.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0)
        ..translateByDouble(-tapPos.dx, -tapPos.dy, 0.0, 1.0);

      _animateTransformation(targetMatrix);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        scaleEnabled: true,
        panEnabled: true,
        constrained: true,
        boundaryMargin: EdgeInsets.zero,
        onInteractionStart: (_) => _animationController.stop(),
        child: widget.child,
      ),
    );
  }
}
