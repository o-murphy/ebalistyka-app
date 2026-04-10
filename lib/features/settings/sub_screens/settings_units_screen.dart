import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:bclibc_ffi/unit.dart';

// ─── Units Screen ─────────────────────────────────────────────────────────────

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSettingsProvider);
    final notifier = ref.read(unitSettingsNotifierProvider.notifier);

    void set(String key, Unit unit) => notifier.setUnit(key, unit);

    return BaseScreen(
      title: 'Units of Measurement',
      isSubscreen: true,
      body: ListView(
        children: [
          UnitPickerListTile(
            icon: IconDef.velocity,
            label: 'Velocity',
            current: units.velocityUnit,
            options: const [Unit.mps, Unit.fps, Unit.kmh, Unit.mph],
            onChanged: (u) => set('velocity', u),
          ),
          UnitPickerListTile(
            icon: IconDef.range,
            label: 'Distance',
            current: units.distanceUnit,
            options: const [Unit.meter, Unit.yard, Unit.foot],
            onChanged: (u) => set('distance', u),
          ),
          UnitPickerListTile(
            icon: IconDef.height,
            label: 'Sight Height',
            current: units.sightHeightUnit,
            options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
            onChanged: (u) => set('sightHeight', u),
          ),
          UnitPickerListTile(
            icon: IconDef.pressure,
            label: 'Pressure',
            current: units.pressureUnit,
            options: const [Unit.hPa, Unit.mmHg, Unit.inHg, Unit.psi],
            onChanged: (u) => set('pressure', u),
          ),
          UnitPickerListTile(
            icon: IconDef.temperature,
            label: 'Temperature',
            current: units.temperatureUnit,
            options: const [Unit.celsius, Unit.fahrenheit],
            onChanged: (u) => set('temperature', u),
          ),
          UnitPickerListTile(
            icon: IconDef.height,
            label: 'Drop / Windage',
            current: units.dropUnit,
            options: const [
              Unit.meter,
              Unit.centimeter,
              Unit.millimeter,
              Unit.inch,
              Unit.foot,
            ],
            onChanged: (u) => set('drop', u),
          ),
          UnitPickerListTile(
            icon: IconDef.dropWindageAngle,
            label: 'Drop / Windage angle',
            current: units.adjustmentUnit,
            options: const [
              Unit.mil,
              Unit.moa,
              Unit.mRad,
              Unit.cmPer100m,
              Unit.inPer100Yd,
            ],
            onChanged: (u) => set('adjustment', u),
          ),
          UnitPickerListTile(
            icon: IconDef.energy,
            label: 'Energy',
            current: units.energyUnit,
            options: const [Unit.joule, Unit.footPound],
            onChanged: (u) => set('energy', u),
          ),
          UnitPickerListTile(
            icon: IconDef.weigth,
            label: 'Projectile weight',
            current: units.weightUnit,
            options: const [Unit.grain, Unit.gram],
            onChanged: (u) => set('weight', u),
          ),
          UnitPickerListTile(
            icon: IconDef.length,
            label: 'Projectile length',
            current: units.lengthUnit,
            options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
            onChanged: (u) => set('length', u),
          ),
          UnitPickerListTile(
            icon: IconDef.caliber,
            label: 'Projectile diameter',
            current: units.diameterUnit,
            options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
            onChanged: (u) => set('diameter', u),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
