import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/features/convertors/length_convertor_vm.dart';
import 'package:ebalistyka/features/convertors/sub_screens/simple_convertor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LengthConvertorScreen extends ConsumerWidget {
  const LengthConvertorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lengthConvertorVmProvider);
    final notifier = ref.read(lengthConvertorVmProvider.notifier);
    return SimpleConvertorScreen(
      title: 'Length Converter',
      hintText: 'Enter length',
      unitOptions: const [
        Unit.centimeter,
        Unit.meter,
        Unit.inch,
        Unit.foot,
        Unit.yard,
      ],
      state: state,
      constraints: notifier.getConstraintsForUnit(state.inputUnit),
      onValueChanged: notifier.updateRawValue,
      onUnitChanged: notifier.changeInputUnit,
    );
  }
}
