import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/sub_screens/simple_convertor_screen.dart';
import 'package:ebalistyka/features/convertors/weight_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeightConvertorScreen extends ConsumerWidget {
  const WeightConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(weightConvertorVmProvider);
    final notifier = ref.read(weightConvertorVmProvider.notifier);
    return SimpleConvertorScreen(
      title: l10n.weightConvertorTitle,
      hintText: l10n.enterWeight,
      unitOptions: const [
        Unit.gram,
        Unit.kilogram,
        Unit.grain,
        Unit.pound,
        Unit.ounce,
      ],
      state: state,
      constraints: notifier.getConstraintsForUnit(state.inputUnit),
      onValueChanged: notifier.updateRawValue,
      onUnitChanged: notifier.changeInputUnit,
    );
  }
}
