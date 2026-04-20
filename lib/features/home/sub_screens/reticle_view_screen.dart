import 'dart:math' as math;

import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/features/home/home_vm.dart';
import 'package:ebalistyka/features/home/widgets/adjustment_panel.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/reticle_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/shared/widgets/base_screen.dart';

class ReticleViewScreen extends ConsumerWidget {
  const ReticleViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    final zoomableViewKey = GlobalKey<_ZoomableViewState>();

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
              Container(
                width: double.infinity,
                height: topBlockHeight,
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
                            key: zoomableViewKey,
                            minScale: 1.0,
                            maxScale: 10.0, // Тепер підтримується зум до 10x
                            initialScale: 1.0,
                            child: ReticleView(
                              reticleImageId: ref
                                  .watch(activeProfileProvider)
                                  ?.sight
                                  .target
                                  ?.reticleImage,
                              targetImageId: null,
                              targetSizeMil: 0.5,
                              offsetXMil: vmState.adjustmentWindMil,
                              offsetYMil: vmState.adjustmentElevMil,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        right: 24,
                        child: FloatingActionButton(
                          onPressed: () {
                            zoomableViewKey.currentState?.resetZoom();
                          },
                          mini: true,
                          heroTag: null,
                          child: const Icon(IconDef.magnificationMin),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                  child: ListView(
                    children: [
                      ListSectionTile("Adjustments"),
                      Center(
                        // ← Додати Center
                        child: AdjPanel(
                          adjustment: vmState.adjustment,
                          fmt: vmState.adjustmentFormat,
                          isEmpty: vmState.adjustment.elevation.isEmpty,
                          displayVertical: false,
                        ),
                      ),
                      SizedBox(height: 8),
                      Divider(height: 1),
                      InfoListTile(
                        label: "Vertical adjustment",
                        value: "<none>",
                      ),
                      InfoListTile(
                        label: "Horizontal adjustment",
                        value: "<none>",
                      ),
                      InfoListTile(label: "Target", value: "<none>"),
                      InfoListTile(label: "Reticle pattern", value: "<none>"),
                      InfoListTile(label: "Vertical click", value: "<none>"),
                      InfoListTile(label: "Horizontal click", value: "<none>"),
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
}

/// Widget that adds pinch-to-zoom and pan functionality to any child widget
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

class _ZoomableViewState extends State<ZoomableView> {
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _resetZoom();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    // Використовуємо identity матрицю без deprecated методів
    _transformationController.value = Matrix4.identity();
  }

  void resetZoom() {
    _resetZoom();
  }

  void _handleDoubleTap() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) {
      _resetZoom();
    } else {
      // Використовуємо scaleByDouble замість deprecated scale()
      final matrix = Matrix4.identity();
      final scaledMatrix = matrix.scaled(2.0);
      _transformationController.value = scaledMatrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        scaleEnabled: true,
        panEnabled: true,
        constrained: true,
        boundaryMargin: EdgeInsets.zero,
        child: widget.child,
      ),
    );
  }
}
