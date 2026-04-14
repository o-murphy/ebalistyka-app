import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/angular_convertor_vm.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_picker_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnglesConvertorScreen extends ConsumerWidget {
  const AnglesConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(anglesConvertorVmProvider);
    final notifier = ref.read(anglesConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Angles Converter',
      isSubscreen: true,
      body: ListView(
        children: [
          ValueInputWithUnitPicker(
            value: state.rawDistanceValue,
            constraints: notifier.getDistanceConstraintsForUnit(
              state.distanceInputUnit,
            ),
            displayUnit: state.distanceInputUnit,
            onChanged: notifier.updateDistanceValue,
            onUnitChanged: notifier.changeDistanceUnit,
            options: const [Unit.meter, Unit.yard],
            label: 'Distance Input',
            icon: IconDef.distanceConvertor,
          ),
          const SizedBox(height: 8),
          ValueInputWithUnitPicker(
            value: state.rawAngularValue,
            constraints: notifier.getAngularConstraintsForUnit(
              state.angularInputUnit,
            ),
            displayUnit: state.angularInputUnit,
            onChanged: notifier.updateAngularValue,
            onUnitChanged: notifier.changeAngularUnit,
            options: const [
              Unit.mil,
              Unit.moa,
              Unit.mRad,
              Unit.cmPer100m,
              Unit.inPer100Yd,
              Unit.degree,
            ],
            label: 'Angle Input',
            icon: IconDef.angleConvertor,
          ),
          const SizedBox(height: 8),
          // Тільки вибір одиниці, без поля вводу
          UnitPickerListTile(
            current: state.distanceOutputUnit,
            onChanged: notifier.changeOutputUnit,
            options: const [
              Unit.millimeter,
              Unit.centimeter,
              Unit.inch,
              Unit.foot,
            ],
            title: 'Output Unit',
            icon: IconDef.heightConvertor,
          ),
          const Divider(height: 24),

          ListSectionTile('Angles'),
          _buildInfoTile(state.mil),
          _buildInfoTile(state.moa),
          _buildInfoTile(state.mrad),
          _buildInfoTile(state.cmPer100m),
          _buildInfoTile(state.inchPer100Yd),
          _buildInfoTile(state.degrees),

          const Divider(height: 24),

          ListSectionTile('Adjustment Value at Distance'),
          InfoListTile(label: '1 MIL', value: state.oneMilAtDistance),
          InfoListTile(
            label: '${state.mil.value.toStringAsFixed(1)} MIL',
            value: state.angleInMilAtDistance,
          ),
          InfoListTile(label: '1 MOA', value: state.oneMoaAtDistance),
          InfoListTile(
            label: '${state.moa.value.toStringAsFixed(1)} MOA',
            value: state.angleInMoaAtDistance,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(AnglesConvertorField field) {
    return InfoListTile(label: field.label, value: field.formattedValue);
  }
}
