import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/coriolis_section.dart';
import 'package:ebalistyka/shared/widgets/help_dialog.dart';
import 'package:ebalistyka/shared/widgets/icon_value_button.dart';
import 'package:ebalistyka/shared/widgets/powder_sens_section.dart';
import 'package:ebalistyka/shared/widgets/unit_hybrid_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/conditions/conditions_vm.dart';
import 'package:ebalistyka/features/conditions/widgets/temperature_control.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

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

    final l10n = AppLocalizations.of(context)!;

    final UnitPickerContext altCtx = UnitPickerContext(
      context,
      label: l10n.altitude,
      rawValue: state.altitude.rawValue,
      constraints: RC.altitude,
      displayUnit: state.altitude.displayUnit,
      onChanged: (v) => notifier.updateAltitude(v!),
    );

    final UnitPickerContext humCtx = UnitPickerContext(
      context,
      label: l10n.humidity,
      rawValue: state.humidity.rawValue,
      constraints: RC.humidity,
      displayUnit: state.humidity.displayUnit,
      symbol: '%',
      onChanged: (v) => notifier.updateHumidity(v!),
    );

    final UnitPickerContext pressCtx = UnitPickerContext(
      context,
      label: l10n.pressure,
      rawValue: state.pressure.rawValue,
      constraints: RC.pressure,
      displayUnit: state.pressure.displayUnit,
      onChanged: (v) => notifier.updatePressure(v!),
    );

    return BaseScreen(
      title: l10n.conditionsScreenTitle,
      actions: [
        helpAction(
          context,
          title: l10n.helpTitle,
          helpId: HelpData.conditionsScreen,
        ),
      ],
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
          const TileDivider(),

          // ── Altitude / Humidity / Pressure ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: IconValueButtonRow(
              items: [
                IconValueButton(
                  icon: IconDef.altitude,
                  label: l10n.altitude,
                  heroTag: 'cond-alt',
                  value:
                      '${state.altitude.displayValue.toFixedSafe(state.altitude.decimals)} ${state.altitude.symbol}',
                  onTap: () => showUnitHybridPickerDialog(altCtx),
                ),
                IconValueButton(
                  icon: IconDef.humidity,
                  label: l10n.humidity,
                  heroTag: 'cond-hum',
                  value:
                      '${state.humidity.displayValue.toFixedSafe(state.humidity.decimals)} ${state.humidity.symbol}',
                  onTap: () => showUnitHybridPickerDialog(humCtx),
                ),

                IconValueButton(
                  icon: IconDef.velocity,
                  label: l10n.pressure,
                  heroTag: 'cond-press',
                  value:
                      '${state.pressure.displayValue.toFixedSafe(state.pressure.decimals)} ${state.pressure.symbol}',
                  onTap: () => showUnitHybridPickerDialog(pressCtx),
                ),
              ],
            ),
          ),
          const TileDivider(),

          // ── Powder sensitivity ─────────────────────────────────────────
          PowderSensSection(
            usePowderSensitivity: state.powderSensOn,
            useDiffPowderTemp: state.useDiffPowderTemp,
            temperatureUnit: state.temperature.displayUnit,
            powderTempRaw: state.powderTemperature?.rawValue,
            mvValue: state.mvAtPowderTemp,
            sensitivityValue: state.powderSensitivity,
            onSensitivityToggled: notifier.setPowderSensitivity,
            onDiffTempToggled: notifier.setDiffPowderTemp,
            onPowderTempChanged: notifier.updatePowderTemp,
          ),
          const TileDivider(),
          // ── Coriolis ───────────────────────────────────────────────────
          CoriolisSection(
            useCoriolis: state.coriolisOn,
            latitudeRaw: state.latitude.rawValue,
            azimuthRaw: state.azimuth.rawValue,
            angularUnit: state.latitude.displayUnit,
            onCoriolisToggled: notifier.setCoriolis,
            onLatitudeChanged: notifier.updateLatitude,
            onAzimuthChanged: notifier.updateAzimuth,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
