import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:ebalistyka/features/convertors/velocity_convertor_vm.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';

class VelocityConvertorScreen extends ConsumerWidget {
  const VelocityConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(velocityConvertorVmProvider);
    final notifier = ref.read(velocityConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Velocity Converter',
      isSubscreen: true,
      body: ListView(
        children: [
          UnitInputWithPicker(
            value: state.rawValue,
            constraints: notifier.getConstraintsForUnit(state.inputUnit),
            displayUnit: state.inputUnit,
            onChanged: notifier.updateRawValue,
            onUnitChanged: notifier.changeInputUnit,
            options: const [Unit.mps, Unit.kmh, Unit.fps, Unit.mph],
            hintText: 'Enter velocity',
          ),
          const Divider(height: 24),

          ListSectionTile('Metric'),
          _buildInfoTile(state.mps),
          _buildInfoTile(state.kmh),

          ListSectionTile('Imperial'),
          _buildInfoTile(state.fps),
          _buildInfoTile(state.mph),

          ListSectionTile('Other'),
          _buildInfoTile(state.mach),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(GenericConvertorField field) {
    return InfoListTile(label: field.label, value: field.formattedValue);
  }
}
