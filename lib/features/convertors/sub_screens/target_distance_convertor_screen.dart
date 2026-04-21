import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/target_distance_convertor_vm.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/reticle_view.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TargetDistanceConvertorScreen extends ConsumerWidget {
  const TargetDistanceConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(targetAtDistanceConvertorVmProvider);
    final notifier = ref.read(targetAtDistanceConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Target Distance',
      isSubscreen: true,
      body: ListView(
        children: [
          ValueInputWithUnitPicker(
            value: state.rawSizeValue,
            constraints: notifier.getSizeConstraintsForUnit(state.sizeUnit),
            displayUnit: state.sizeUnit,
            onChanged: notifier.updateSizeValue,
            onUnitChanged: notifier.changeSizeUnit,
            options: const [
              Unit.millimeter,
              Unit.centimeter,
              Unit.meter,
              Unit.inch,
              Unit.foot,
            ],
            label: 'Target Size',
            icon: IconDef.sight,
          ),
          const SizedBox(height: 8),
          ValueInputWithUnitPicker(
            value: state.rawAngularValue,
            constraints: notifier.getAngularConstraintsForUnit(
              state.angularUnit,
            ),
            displayUnit: state.angularUnit,
            onChanged: notifier.updateAngularValue,
            onUnitChanged: notifier.changeAngularUnit,
            options: const [Unit.mil, Unit.moa, Unit.mRad],
            label: 'Angular Size',
            icon: IconDef.angleConvertor,
          ),
          const Divider(height: 1),
          const ListSectionTile('Distance metric'),
          InfoListTile(
            label: state.meters.label,
            value: state.meters.formattedValue,
            icon: IconDef.distanceConvertor,
          ),
          const Divider(height: 1),
          const ListSectionTile('Distance metric'),
          InfoListTile(
            label: state.yards.label,
            value: state.yards.formattedValue,
            icon: IconDef.distanceConvertor,
          ),
          InfoListTile(
            label: state.feet.label,
            value: state.feet.formattedValue,
            icon: IconDef.distanceConvertor,
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AspectRatio(
              aspectRatio: 1,
              child: ReticleView(
                reticleImageId: state.reticleImageId,
                targetImageId: state.targetImageId,
                targetSizeMil: state.targetSizeMil,
                offsetXMil: 0,
                offsetYMil: 0,
                clipRadius: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
