import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/features/home/home_vm.dart';
import 'trajectory_chart.dart';

// ─── Page 3 — Chart ───────────────────────────────────────────────────────────

class HomeChartPage extends ConsumerWidget {
  const HomeChartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(homeVmProvider);
    final vmState = vmAsync.value;

    if (vmState is HomeUiNoData) {
      return EmptyStatePlaceholder(
        type: vmState.type,
        message: vmState.message,
      );
    }
    if (vmState is HomeUiError) {
      return ErrorDisplay(error: vmState.message);
    }
    if (vmAsync.isLoading || vmState is! HomeUiReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final cs = vmState.chartState;
    final chart = cs.chartData;
    if (chart.points.isEmpty) {
      return const EmptyStatePlaceholder();
    }

    return Column(
      children: [
        _ChartInfoGrid(info: cs.selectedPointInfo),
        Expanded(
          child: TrajectoryChart(
            points: chart.points,
            selectedIndex: cs.selectedChartIndex,
            snapDistM: chart.snapDistM,
            showSubsonicLine: true,
            onIndexSelected: (i) =>
                ref.read(homeVmProvider.notifier).selectChartPoint(i),
          ),
        ),
      ],
    );
  }
}

// ─── Info grid above chart ────────────────────────────────────────────────────

class _ChartInfoGrid extends StatelessWidget {
  const _ChartInfoGrid({required this.info});

  final HomeChartPointInfo? info;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (info == null) {
      return const SizedBox(height: 80);
    }

    final leftItems = [
      (IconDef.range, info!.distance),
      (IconDef.velocity, info!.velocity),
      (IconDef.energy, info!.energy),
      (IconDef.time, info!.time),
    ];
    final rightItems = [
      (IconDef.height, info!.height),
      (Icons.arrow_downward_outlined, info!.drop),
      (IconDef.windage, info!.windage),
      (Icons.air_outlined, info!.mach),
    ];

    final valueStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    Widget infoRow(IconData icon, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withAlpha(140)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: leftItems.map((e) => infoRow(e.$1, e.$2)).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rightItems.map((e) => infoRow(e.$1, e.$2)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
