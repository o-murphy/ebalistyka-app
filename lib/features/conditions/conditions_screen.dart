import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/icon_value_button.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/conditions/conditions_vm.dart';
import 'package:ebalistyka/features/conditions/widgets/temperature_control.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';

class ConditionsScreen extends ConsumerWidget {
  const ConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmAsync = ref.watch(conditionsVmProvider);
    final state = vmAsync.value;

    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifier = ref.read(conditionsVmProvider.notifier);

    return BaseScreen(
      title: 'Conditions',
      body: ListView(
        children: [
          // ── Temperature — big centred control ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: TempControl(
              rawValue: state.temperature.rawValue,
              displayUnit: state.temperature.displayUnit,
              onChanged: (v) => notifier.updateTemperature(v),
            ),
          ),
          const Divider(height: 1),

          // ── Altitude / Humidity / Pressure ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: IconValueButtonRow(
              items: [
                IconValueButton(
                  icon: Icons.terrain_outlined,
                  label: 'Altitude',
                  heroTag: 'cond-alt',
                  value:
                      '${state.altitude.displayValue.toFixedSafe(state.altitude.decimals)} ${state.altitude.symbol}',
                  onTap: () => showUnitEditDialog(
                    context,
                    label: 'Altitude',
                    rawValue: state.altitude.rawValue,
                    constraints: FC.altitude,
                    displayUnit: state.altitude.displayUnit,
                    onChanged: notifier.updateAltitude,
                  ),
                ),
                IconValueButton(
                  icon: Icons.water_drop_outlined,
                  label: 'Humidity',
                  heroTag: 'cond-hum',
                  value:
                      '${state.humidity.displayValue.toFixedSafe(state.humidity.decimals)} ${state.humidity.symbol}',
                  onTap: () => showUnitEditDialog(
                    context,
                    label: 'Humidity',
                    rawValue: state.humidity.rawValue,
                    constraints: FC.humidity,
                    displayUnit: state.humidity.displayUnit,
                    symbol: '%',
                    onChanged: notifier.updateHumidity,
                  ),
                ),
                IconValueButton(
                  icon: Icons.speed_outlined,
                  label: 'Pressure',
                  heroTag: 'cond-press',
                  value:
                      '${state.pressure.displayValue.toFixedSafe(state.pressure.decimals)} ${state.pressure.symbol}',
                  onTap: () => showUnitEditDialog(
                    context,
                    label: 'Pressure',
                    rawValue: state.pressure.rawValue,
                    constraints: FC.pressure,
                    displayUnit: state.pressure.displayUnit,
                    onChanged: notifier.updatePressure,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Switches ──────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Powder temperature sensitivity'),
            secondary: const Icon(Icons.local_fire_department_outlined),
            value: state.powderSensOn,
            onChanged: (v) => notifier.setPowderSensitivity(v),
            dense: true,
          ),
          if (state.powderSensOn) ...[
            SwitchListTile(
              title: const Text('Use different powder temperature'),
              subtitle: Text(
                state.useDiffPowderTemp
                    ? "Uses powder temperature"
                    : "Uses atmospheric temperature",
              ),
              secondary: const Icon(Icons.thermostat_outlined),
              value: state.useDiffPowderTemp,
              onChanged: (v) => notifier.setDiffPowderTemp(v),
              dense: true,
            ),
            if (state.powderTemperature != null)
              UnitValueFieldTile(
                label: 'Powder temperature',
                icon: Icons.local_fire_department_outlined,
                rawValue: state.powderTemperature!.rawValue,
                constraints: FC.temperature,
                displayUnit: state.powderTemperature!.displayUnit,
                onChanged: (v) => notifier.updatePowderTemp(v),
              ),
            if (state.mvAtPowderTemp != null)
              InfoListTile(
                label: state.useDiffPowderTemp
                    ? 'Muzzle velocity at powder temperature'
                    : 'Muzzle velocity at atmospheric temperature',
                value: state.mvAtPowderTemp!,
                icon: Icons.speed_outlined,
              ),
            if (state.powderSensitivity != null)
              InfoListTile(
                label: 'Powder sensitivity',
                value: state.powderSensitivity!,
                icon: Icons.show_chart_outlined,
              ),
          ],
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Coriolis effect'),
            secondary: const Icon(Icons.rotate_right_outlined),
            value: state.coriolisOn,
            onChanged: (v) => notifier.setCoriolis(v),
            dense: true,
          ),
          if (state.coriolisOn) ...[
            UnitValueFieldTile(
              label: 'Latitude',
              icon: Icons.public_outlined,
              rawValue: state.latitude.rawValue,
              constraints: FC.latitude,
              displayUnit: state.latitude.displayUnit,
              symbol: '°',
              onChanged: (v) => notifier.updateLatitude(v),
            ),
            UnitValueFieldTile(
              label: 'Azimuth',
              icon: Icons.explore_outlined,
              rawValue: state.azimuth.rawValue,
              constraints: FC.azimuth,
              displayUnit: state.azimuth.displayUnit,
              symbol: '°',
              onChanged: (v) => notifier.updateAzimuth(v),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
