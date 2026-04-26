import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/sub_screens/simple_convertor_screen.dart';
import 'package:ebalistyka/features/convertors/torque_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TorqueConvertorScreen extends ConsumerWidget {
  const TorqueConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(torqueConvertorVmProvider);
    final notifier = ref.read(torqueConvertorVmProvider.notifier);
    return SimpleConvertorScreen(
      title: l10n.torqueConvertorTitle,
      hintText: l10n.enterTorque,
      unitOptions: const [
        Unit.newtonMeter,
        Unit.footPoundTorque,
        Unit.inchPound,
      ],
      state: state,
      constraints: notifier.getConstraintsForUnit(state.inputUnit),
      onValueChanged: notifier.updateRawValue,
      onUnitChanged: notifier.changeInputUnit,
    );
  }
}
