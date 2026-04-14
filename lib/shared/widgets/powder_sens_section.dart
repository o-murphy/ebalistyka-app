import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart';

/// Reusable powder sensitivity section for ListView-based screens.
///
/// [powderSensRaw] non-null → renders an editable input for the sensitivity
/// value (ammo wizard). null → omits the input and shows only the info tile
/// (conditions screen, where sensitivity is an ammo property).
class PowderSensSection extends StatelessWidget {
  const PowderSensSection({
    required this.usePowderSensitivity,
    required this.useDiffPowderTemp,
    required this.temperatureUnit,
    this.showToggle = true,
    this.powderTempRaw,
    this.powderSensRaw,
    this.mvValue,
    this.sensitivityValue,
    this.onSensitivityToggled,
    required this.onDiffTempToggled,
    this.onPowderTempChanged,
    this.onPowderSensChanged,
    super.key,
  });

  final bool usePowderSensitivity;
  final bool useDiffPowderTemp;
  final Unit temperatureUnit;

  /// When false the toggle switch is omitted and all content is always shown.
  /// Use this when the toggle lives in a different section (e.g. Cartridge)
  /// and the parent already guards visibility with [usePowderSensitivity].
  final bool showToggle;

  /// Raw temperature value shown when [useDiffPowderTemp] is true.
  final double? powderTempRaw;

  /// Raw sensitivity fraction. Non-null → editable input is shown.
  final double? powderSensRaw;

  /// Pre-formatted MV string. null → tile is hidden.
  final String? mvValue;

  /// Pre-formatted sensitivity string. null → tile is hidden.
  final String? sensitivityValue;

  /// Required when [showToggle] is true.
  final ValueChanged<bool>? onSensitivityToggled;
  final ValueChanged<bool> onDiffTempToggled;
  final ValueChanged<double>? onPowderTempChanged;

  /// Called when the sensitivity input changes. Required when [powderSensRaw]
  /// is non-null.
  final ValueChanged<double>? onPowderSensChanged;

  @override
  Widget build(BuildContext context) {
    final showContent = !showToggle || usePowderSensitivity;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showToggle)
          SwitchListTile(
            title: const Text('Powder temperature sensitivity'),
            secondary: const Icon(IconDef.powderTemperature),
            value: usePowderSensitivity,
            onChanged: onSensitivityToggled,
            dense: true,
          ),
        if (showContent) ...[
          if (powderSensRaw != null)
            UnitValueFieldTile(
              title: 'Powder sensitivity',
              subtitle: 'Velocity change per 15°C temperature delta',
              rawValue: powderSensRaw!,
              constraints: FC.powderSensitivity,
              displayUnit: Unit.percent,
              icon: IconDef.powderSensitivity,
              onChanged: onPowderSensChanged ?? (_) {},
            )
          else if (sensitivityValue != null)
            InfoListTile(
              label: 'Powder sensitivity',
              value: sensitivityValue!,
              icon: IconDef.powderSensitivity,
            ),
          SwitchListTile(
            title: const Text('Use different powder temperature'),
            subtitle: Text(
              useDiffPowderTemp
                  ? 'Uses powder temperature'
                  : 'Uses atmospheric temperature',
            ),
            secondary: const Icon(IconDef.temperature),
            value: useDiffPowderTemp,
            onChanged: onDiffTempToggled,
            dense: true,
          ),
          if (useDiffPowderTemp && powderTempRaw != null)
            UnitValueFieldTile(
              title: 'Powder temperature',
              rawValue: powderTempRaw!,
              constraints: FC.temperature,
              displayUnit: temperatureUnit,
              icon: IconDef.powderTemperature,
              onChanged: onPowderTempChanged ?? (_) {},
            ),
          if (mvValue != null)
            InfoListTile(
              label: useDiffPowderTemp
                  ? 'Muzzle velocity at powder temperature'
                  : 'Muzzle velocity at atmospheric temperature',
              value: mvValue!,
              icon: IconDef.velocity,
            ),
        ],
      ],
    );
  }
}
