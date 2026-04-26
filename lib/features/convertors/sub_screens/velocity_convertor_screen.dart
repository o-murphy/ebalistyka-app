import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/features/convertors/generic_convertor_vm_field.dart';
import 'package:ebalistyka/features/convertors/velocity_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: l10n.velocityConvertorTitle,
      isSubscreen: true,
      body: ListView(
        children: [
          UnitInputWithPicker(
            value: state.rawValue,
            constraints: notifier.getConstraintsForUnit(state.inputUnit),
            displayUnit: state.inputUnit,
            onChanged: notifier.updateRawValue,
            onUnitChanged: notifier.changeInputUnit,
            options: const [Unit.mps, Unit.kmh, Unit.fps, Unit.mph, Unit.mach],
            hintText: l10n.enterVelocity,
          ),
          const Divider(height: 24),

          ListSectionTile(l10n.sectionMetric),
          _buildInfoTile(state.mps, l10n),
          _buildInfoTile(state.kmh, l10n),

          ListSectionTile(l10n.sectionImperial),
          _buildInfoTile(state.fps, l10n),
          _buildInfoTile(state.mph, l10n),

          SwitchListTile(
            title: Text(l10n.customAtmosphere),
            subtitle: Text(
              state.useCustomAtmo
                  ? l10n.usingCustomConditions
                  : l10n.usingIcaoAtmosphere,
            ),
            value: state.useCustomAtmo,
            onChanged: notifier.toggleCustomAtmo,
          ),

          ListSectionTile(l10n.sectionOther),
          _buildInfoTile(state.mach, l10n),

          if (state.useCustomAtmo) ...[
            Divider(height: 1),
            ListSectionTile(l10n.sectionAtmosphere),
            UnitValueFieldTile(
              title: l10n.atmoTemperature,
              rawValue: state.atmoTemperatureC,
              constraints: FC.temperature,
              displayUnit: units.temperatureUnit,
              icon: IconDef.temperature,
              onChanged: notifier.updateAtmoTemperature,
            ),
            UnitValueFieldTile(
              title: l10n.atmoPressure,
              rawValue: state.atmoPressureHPa,
              constraints: FC.pressure,
              displayUnit: units.pressureUnit,
              icon: IconDef.pressure,
              onChanged: notifier.updateAtmoPressure,
            ),
            UnitValueFieldTile(
              title: l10n.atmoHumidity,
              rawValue: state.atmoHumidityFrac,
              constraints: FC.humidity,
              displayUnit: Unit.percent,
              icon: IconDef.humidity,
              onChanged: notifier.updateAtmoHumidity,
            ),
            UnitValueFieldTile(
              title: l10n.atmoAltitude,
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

  Widget _buildInfoTile(GenericConvertorField field, AppLocalizations l10n) {
    return InfoListTile(
      label: field.labelBuilder(l10n),
      value: field.formattedValue,
    );
  }
}
