import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/sub_screens/simple_convertor_screen.dart';
import 'package:ebalistyka/features/convertors/temperature_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TemperatureConvertorScreen extends ConsumerWidget {
  const TemperatureConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(temperatureConvertorVmProvider);
    final notifier = ref.read(temperatureConvertorVmProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return SimpleConvertorScreen(
      title: l10n.temperatureConvertorTitle,
      hintText: l10n.enterTemperature,
      unitOptions: const [Unit.celsius, Unit.fahrenheit],
      state: state,
      constraints: notifier.getConstraintsForUnit(state.inputUnit),
      onValueChanged: notifier.updateRawValue,
      onUnitChanged: notifier.changeInputUnit,
    );
  }
}
