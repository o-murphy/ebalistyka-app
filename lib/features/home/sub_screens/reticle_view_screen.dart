import 'dart:math' as math;

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
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/reticle_view.dart';
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
  late double _vAdjRaw;
  late Unit _vAdjUnit;
  late double _hAdjRaw;
  late Unit _hAdjUnit;

  // ReticleSettings
  String? _targetImage;

  // Sight
  String? _reticleImage;
  late double _vClickRaw;
  late Unit _vClickUnit;
  late double _hClickRaw;
  late Unit _hClickUnit;

  static const _adjUnits = [
    Unit.mil,
    Unit.moa,
    Unit.mRad,
    Unit.cmPer100m,
    Unit.inPer100Yd,
  ];

  @override
  void initState() {
    super.initState();
    final reticle = ref.read(reticleSettingsProvider);
    _vAdjUnit = reticle.verticalAdjustmentUnitValue;
    _vAdjRaw = Angular(
      reticle.verticalAdjustment,
      _vAdjUnit,
    ).in_(FC.adjustment.rawUnit);
    _hAdjUnit = reticle.horizontalAdjustmentUnitValue;
    _hAdjRaw = Angular(
      reticle.horizontalAdjustment,
      _hAdjUnit,
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
    final targetSizeDisplay = targetSizeMil >= 0.0
        ? fmt.targetSize(Angular.mil(targetSizeMil))
        : nullStr;

    return LayoutBuilder(
      builder: (context, constraints) {
        const minTopH = 350.0;
        const maxTopH = 400.0;
        final fullHeight = math.max(constraints.maxHeight, minTopH);
        final topBlockHeight = math.min(
          maxTopH,
          math.max(fullHeight * 0.45, minTopH),
        );

        return BaseScreen(
          title: 'Reticle View',
          isSubscreen: true,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopBlock(context, topBlockHeight, vmState, targetSizeMil),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  child: ListView(
                    children: [
                      ListSectionTile('Adjustments'),
                      Center(
                        child: AdjPanel(
                          adjustment: vmState.adjustment,
                          fmt: vmState.adjustmentFormat,
                          isEmpty: vmState.adjustment.elevation.isEmpty,
                          displayVertical: false,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const ListSectionTile('Barrel drums'),
                      _clickLabel(context, 'Vertical adjustment'),
                      UnitInputWithPicker(
                        value: _vAdjRaw,
                        constraints: FC.adjustment,
                        displayUnit: _vAdjUnit,
                        options: _adjUnits,
                        unitLabel: 'Adjustment unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _vAdjRaw = v);
                            _saveAdj();
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _vAdjUnit = u);
                          _saveAdj();
                        },
                      ),
                      _clickLabel(context, 'Horizontal adjustment'),
                      UnitInputWithPicker(
                        value: _hAdjRaw,
                        constraints: FC.adjustment,
                        displayUnit: _hAdjUnit,
                        options: _adjUnits,
                        unitLabel: 'Adjustment unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _hAdjRaw = v);
                            _saveAdj();
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _hAdjUnit = u);
                          _saveAdj();
                        },
                      ),
                      const Divider(height: 1),
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
                      const Divider(height: 1),
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
                      const Divider(height: 1),
                      const ListSectionTile('Clicks'),
                      _clickLabel(context, 'Vertical click'),
                      UnitInputWithPicker(
                        value: _vClickRaw,
                        constraints: FC.adjustment,
                        displayUnit: _vClickUnit,
                        options: _adjUnits,
                        unitLabel: 'Click unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _vClickRaw = v);
                            _saveSight();
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _vClickUnit = u);
                          _saveSight();
                        },
                      ),
                      _clickLabel(context, 'Horizontal click'),
                      UnitInputWithPicker(
                        value: _hClickRaw,
                        constraints: FC.adjustment,
                        displayUnit: _hClickUnit,
                        options: _adjUnits,
                        unitLabel: 'Click unit',
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _hClickRaw = v);
                            _saveSight();
                          }
                        },
                        onUnitChanged: (u) {
                          setState(() => _hClickUnit = u);
                          _saveSight();
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
    double height,
    HomeUiReady vmState,
    double targetSizeMil,
  ) {
    return Container(
      width: double.infinity,
      height: height,
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
                    offsetXMil: vmState.adjustmentWindMil,
                    offsetYMil: vmState.adjustmentElevMil,
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
    );
  }

  static double _parseMilWidth(String svg) {
    final m = RegExp(
      r'viewBox="[^"]*?\s+[^"]*?\s+([^"]*?)\s+[^"]*?"',
    ).firstMatch(svg);
    return m != null ? double.tryParse(m.group(1)!) ?? 0.5 : 0.0;
  }

  static double _parseMilHeight(String svg) {
    final m = RegExp(
      r'viewBox="[^"]*?\s+[^"]*?\s+[^"]*?\s+([^"]*?)"',
    ).firstMatch(svg);
    return m != null ? double.tryParse(m.group(1)!) ?? 0.5 : 0.0;
  }

  Widget _clickLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 0),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
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
    _animationController.forward(from: 0);
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    if (currentScale > 1.1) {
      resetZoom();
    } else {
      if (_doubleTapDetails == null) return;

      final tapPos = _doubleTapDetails!.localPosition;
      const targetScale = 3.0; // Рівень масштабу

      final targetMatrix = Matrix4.identity()
        ..translate(tapPos.dx, tapPos.dy)
        ..scale(targetScale)
        ..translate(-tapPos.dx, -tapPos.dy);

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
