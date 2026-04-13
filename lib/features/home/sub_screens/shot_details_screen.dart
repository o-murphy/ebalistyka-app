import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/features/home/shot_details_vm.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';

class ShotDetailsScreen extends ConsumerWidget {
  const ShotDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shotDetailsVmProvider);

    return BaseScreen(
      title: 'Shot Info',
      isSubscreen: true,
      body: state.when(
        data: (uiState) => _buildContent(context, uiState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ShotDetailsUiState state) {
    if (state is! ShotDetailsReady) {
      if (state is ShotDetailsError) {
        return EmptyStatePlaceholder(type: state.type, message: state.message);
      }
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      children: [
        const ListSectionTile('Velocity'),
        InfoListTile(
          icon: IconDef.velocity,
          label: 'Current muzzle velocity',
          value: state.currentMv,
        ),
        InfoListTile(
          icon: IconDef.velocity,
          label: 'Zero muzzle velocity',
          value: state.zeroMv,
        ),
        InfoListTile(
          icon: IconDef.machSpeed,
          label: 'Speed of sound',
          value: state.speedOfSound,
        ),
        InfoListTile(
          icon: IconDef.velocity,
          label: 'Velocity at target',
          value: state.velocityAtTarget,
        ),
        const Divider(height: 1),
        const ListSectionTile('Energy'),
        InfoListTile(
          icon: IconDef.energy,
          label: 'Energy at muzzle velocity',
          value: state.energyAtMuzzle,
        ),
        InfoListTile(
          icon: IconDef.energy,
          label: 'Energy at target',
          value: state.energyAtTarget,
        ),
        const Divider(height: 1),
        const ListSectionTile('Stability'),
        InfoListTile(
          icon: IconDef.gyrostability,
          label: 'Gyroscopic stability factor',
          value: state.gyroscopicStability,
        ),
        const Divider(height: 1),
        const ListSectionTile('Trajectory'),
        InfoListTile(
          icon: IconDef.range,
          label: 'Shot distance',
          value: state.shotDistance,
        ),
        InfoListTile(
          icon: IconDef.height,
          label: 'Height at target',
          value: state.heightAtTarget,
        ),
        InfoListTile(
          icon: Icons.architecture_outlined,
          label: 'Max height distance',
          value: state.maxHeightDistance,
        ),
        InfoListTile(
          icon: IconDef.windage,
          label: 'Windage',
          value: state.windage,
        ),
        InfoListTile(
          icon: IconDef.time,
          label: 'Time to target',
          value: state.timeToTarget,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
