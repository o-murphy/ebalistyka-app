import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/pressure_convertor_vm.dart';
import 'package:ebalistyka/features/convertors/sub_screens/simple_convertor_screen.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PressureConvertorScreen extends ConsumerWidget {
  const PressureConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pressureConvertorVmProvider);
    final notifier = ref.read(pressureConvertorVmProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    return SimpleConvertorScreen(
      title: l10n.pressureConvertorTitle,
      hintText: l10n.enterPressure,
      unitOptions: const [
        Unit.mmHg,
        Unit.inHg,
        Unit.bar,
        Unit.hPa,
        Unit.psi,
        Unit.atm,
      ],
      state: state,
      constraints: notifier.getConstraintsForUnit(state.inputUnit),
      onValueChanged: notifier.updateRawValue,
      onUnitChanged: notifier.changeInputUnit,
    );
  }
}
