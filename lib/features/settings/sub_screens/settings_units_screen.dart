import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:bclibc_ffi/bclibc_ffi.dart';

// ─── Units Screen ─────────────────────────────────────────────────────────────

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(unitSettingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    void set(String key, Unit unit) => notifier.setUnit(key, unit);

    return BaseScreen(
      title: 'Units of Measurement',
      isSubscreen: true,
      body: ListView(
        children: [
          UnitPickerListTile(
            icon: Icons.speed_outlined,
            label: 'Velocity',
            current: units.velocity,
            options: const [Unit.mps, Unit.fps, Unit.kmh, Unit.mph],
            onChanged: (u) => set('velocity', u),
          ),
          UnitPickerListTile(
            icon: Icons.straighten_outlined,
            label: 'Distance',
            current: units.distance,
            options: const [Unit.meter, Unit.yard, Unit.foot],
            onChanged: (u) => set('distance', u),
          ),
          UnitPickerListTile(
            icon: Icons.vertical_align_center_outlined,
            label: 'Sight Height',
            current: units.sightHeight,
            options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
            onChanged: (u) => set('sightHeight', u),
          ),
          UnitPickerListTile(
            icon: Icons.compress_outlined,
            label: 'Pressure',
            current: units.pressure,
            options: const [Unit.hPa, Unit.mmHg, Unit.inHg, Unit.psi],
            onChanged: (u) => set('pressure', u),
          ),
          UnitPickerListTile(
            icon: Icons.device_thermostat_outlined,
            label: 'Temperature',
            current: units.temperature,
            options: const [Unit.celsius, Unit.fahrenheit],
            onChanged: (u) => set('temperature', u),
          ),
          UnitPickerListTile(
            icon: Icons.height_outlined,
            label: 'Drop / Windage',
            current: units.drop,
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
            icon: Icons.rotate_90_degrees_cw_outlined,
            label: 'Drop / Windage angle',
            current: units.adjustment,
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
            icon: Icons.bolt_outlined,
            label: 'Energy',
            current: units.energy,
            options: const [Unit.joule, Unit.footPound],
            onChanged: (u) => set('energy', u),
          ),
          UnitPickerListTile(
            icon: Icons.balance_outlined,
            label: 'Bullet weight',
            current: units.weight,
            options: const [Unit.grain, Unit.gram],
            onChanged: (u) => set('weight', u),
          ),
          UnitPickerListTile(
            icon: Icons.linear_scale_outlined,
            label: 'Bullet length',
            current: units.length,
            options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
            onChanged: (u) => set('length', u),
          ),
          UnitPickerListTile(
            icon: Icons.circle_outlined,
            label: 'Bullet diameter',
            current: units.diameter,
            options: const [Unit.millimeter, Unit.centimeter, Unit.inch],
            onChanged: (u) => set('diameter', u),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
