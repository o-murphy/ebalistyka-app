import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:ebalistyka/features/home/shot_details_vm.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';

class ShotInfoScreen extends ConsumerWidget {
  const ShotInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shotInfoVmProvider);
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: l10n.shotInfoScreenTitle,
      isSubscreen: true,
      body: state.when(
        data: (uiState) => _buildContent(context, uiState),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ShotInfoUiState state) {
    if (state is! ShotInfoReady) {
      if (state is ShotInfoError) {
        return EmptyStatePlaceholder(type: state.type, message: state.message);
      }
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;

    return ListView(
      children: [
        ListSectionTile(l10n.labelVelocity),
        InfoListTile(
          icon: IconDef.velocity,
          label: l10n.currentMv,
          value: state.currentMv,
        ),
        InfoListTile(
          icon: IconDef.velocity,
          label: l10n.zeroMv,
          value: state.zeroMv,
        ),
        InfoListTile(
          icon: IconDef.speedOfSound,
          label: l10n.speedOfSound,
          value: state.speedOfSound,
        ),
        InfoListTile(
          icon: IconDef.velocity,
          label: l10n.velocityAtTarget,
          value: state.velocityAtTarget,
        ),
        const TileDivider(),
        ListSectionTile(l10n.sectionEnergy),
        InfoListTile(
          icon: IconDef.energy,
          label: l10n.energyAtMuzzle,
          value: state.energyAtMuzzle,
        ),
        InfoListTile(
          icon: IconDef.energy,
          label: l10n.energyAtTarget,
          value: state.energyAtTarget,
        ),
        const TileDivider(),
        ListSectionTile(l10n.sectionGyrostabilitySg),
        InfoListTile(
          icon: IconDef.gyrostability,
          label: l10n.gyrostabilitySg,
          value: state.gyroscopicStability,
        ),
        const TileDivider(),
        ListSectionTile(l10n.sectionTrajectory),
        InfoListTile(
          icon: IconDef.range,
          label: l10n.targetRange,
          value: state.shotDistance,
        ),
        InfoListTile(
          icon: IconDef.height,
          label: l10n.apexHeight,
          value: state.apexHeight,
        ),
        InfoListTile(
          icon: IconDef.apex,
          label: l10n.apexDistance,
          value: state.maxHeightDistance,
        ),
        InfoListTile(
          icon: IconDef.windage,
          label: l10n.windage,
          value: state.windage,
        ),
        InfoListTile(
          icon: IconDef.time,
          label: l10n.timeToTarget,
          value: state.timeToTarget,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
