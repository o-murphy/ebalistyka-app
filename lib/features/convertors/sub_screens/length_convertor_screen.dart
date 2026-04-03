import 'package:eballistica/features/convertors/length_convertor_vm.dart';
import 'package:eballistica/shared/widgets/unit_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eballistica/core/solver/unit.dart';
import 'package:eballistica/shared/widgets/base_screen.dart';
import 'package:eballistica/shared/widgets/info_tile.dart';
import 'package:eballistica/shared/widgets/list_section_tile.dart';

// ── Screen ───────────────────────────────────────────────────────────────────

class LengthConvertorScreen extends ConsumerWidget {
  const LengthConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lengthConvertorVmProvider);
    final notifier = ref.read(lengthConvertorVmProvider.notifier);

    return BaseScreen(
      title: 'Length Converter',
      isSubscreen: true,
      body: ListView(
        children: [
          UnitInputWithPicker(
            value: state.rawValue,
            constraints: notifier.getConstraintsForUnit(state.inputUnit),
            displayUnit: state.inputUnit,
            onChanged: notifier.updateRawValue,
            onUnitChanged: notifier.changeInputUnit,
            options: const [
              Unit.centimeter,
              Unit.meter,
              Unit.inch,
              Unit.foot,
              Unit.yard,
            ],
            hintText: 'Enter length',
          ),

          const Divider(height: 24),

          ListSectionTile('Metric'),
          InfoListTile(
            label: '${state.centimeters.label} (${state.centimeters.symbol})',
            value: _formatValue(
              state.centimeters.value,
              state.centimeters.decimals,
              state.centimeters.symbol,
            ),
            icon: null,
          ),
          InfoListTile(
            label: '${state.meters.label} (${state.meters.symbol})',
            value: _formatValue(
              state.meters.value,
              state.meters.decimals,
              state.meters.symbol,
            ),
            icon: null,
          ),

          ListSectionTile('Imperial'),
          InfoListTile(
            label: '${state.inches.label} (${state.inches.symbol})',
            value: _formatValue(
              state.inches.value,
              state.inches.decimals,
              state.inches.symbol,
            ),
            icon: null,
          ),
          InfoListTile(
            label: '${state.feet.label} (${state.feet.symbol})',
            value: _formatValue(
              state.feet.value,
              state.feet.decimals,
              state.feet.symbol,
            ),
            icon: null,
          ),
          InfoListTile(
            label: '${state.yards.label} (${state.yards.symbol})',
            value: _formatValue(
              state.yards.value,
              state.yards.decimals,
              state.yards.symbol,
            ),
            icon: null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatValue(double value, int decimals, String symbol) {
    if (value.isNaN || value.isInfinite) return '— $symbol';
    return '${value.toStringAsFixed(decimals)} $symbol';
  }
}
