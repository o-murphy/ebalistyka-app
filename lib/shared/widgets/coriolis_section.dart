import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart';

/// Reusable Coriolis section for ListView-based screens.
class CoriolisSection extends StatelessWidget {
  const CoriolisSection({
    required this.useCoriolis,
    required this.latitudeRaw,
    required this.azimuthRaw,
    required this.angularUnit,
    required this.onCoriolisToggled,
    required this.onLatitudeChanged,
    required this.onAzimuthChanged,
    super.key,
  });

  final bool useCoriolis;
  final double latitudeRaw;
  final double azimuthRaw;
  final Unit angularUnit;

  final ValueChanged<bool> onCoriolisToggled;
  final ValueChanged<double> onLatitudeChanged;
  final ValueChanged<double> onAzimuthChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SwitchListTile(
          title: const Text('Coriolis effect'),
          secondary: const Icon(IconDef.coriolis),
          value: useCoriolis,
          onChanged: onCoriolisToggled,
          dense: true,
        ),
        if (useCoriolis) ...[
          UnitValueFieldTile(
            title: 'Latitude',
            rawValue: latitudeRaw,
            constraints: FC.latitude,
            displayUnit: angularUnit,
            symbol: '°',
            icon: IconDef.latitude,
            onChanged: onLatitudeChanged,
          ),
          UnitValueFieldTile(
            title: 'Azimuth',
            rawValue: azimuthRaw,
            constraints: FC.azimuth,
            displayUnit: angularUnit,
            symbol: '°',
            icon: IconDef.azimuth,
            onChanged: onAzimuthChanged,
          ),
        ],
      ],
    );
  }
}
