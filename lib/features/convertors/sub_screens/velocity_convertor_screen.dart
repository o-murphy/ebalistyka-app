import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:ebalistyka/features/convertors/velocity_convertor_vm.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart' hide Velocity;
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
    final units = ref.watch(unitSettingsProvider);

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
          SwitchListTile(
            title: const Text('Custom atmosphere'),
            subtitle: Text(
              state.useCustomAtmo
                  ? 'Using custom conditions'
                  : 'Using ICAO standard atmosphere',
            ),
            value: state.useCustomAtmo,
            onChanged: notifier.toggleCustomAtmo,
          ),

          if (state.useCustomAtmo) ...[
            UnitValueFieldTile(
              title: 'Temperature',
              rawValue: state.atmoTemperatureC,
              constraints: FC.temperature,
              displayUnit: units.temperatureUnit,
              icon: IconDef.temperature,
              onChanged: notifier.updateAtmoTemperature,
            ),
            UnitValueFieldTile(
              title: 'Pressure',
              rawValue: state.atmoPressureHPa,
              constraints: FC.pressure,
              displayUnit: units.pressureUnit,
              icon: IconDef.pressure,
              onChanged: notifier.updateAtmoPressure,
            ),
            UnitValueFieldTile(
              title: 'Humidity',
              rawValue: state.atmoHumidityFrac,
              constraints: FC.humidity,
              displayUnit: Unit.percent,
              icon: IconDef.humidity,
              onChanged: notifier.updateAtmoHumidity,
            ),
            UnitValueFieldTile(
              title: 'Altitude',
              rawValue: state.atmoAltitudeMeter,
              constraints: FC.altitude,
              displayUnit: units.distanceUnit,
              icon: IconDef.altitude,
              onChanged: notifier.updateAtmoAltitude,
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoTile(GenericConvertorField field) {
    return InfoListTile(label: field.label, value: field.formattedValue);
  }
}
