import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/features/convertors/simple_convertor_vm.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_with_unit_picker_tile.dart';
import 'package:flutter/material.dart';

class SimpleConvertorScreen extends StatelessWidget {
  const SimpleConvertorScreen({
    super.key,
    required this.title,
    required this.hintText,
    required this.unitOptions,
    required this.state,
    required this.constraints,
    required this.onValueChanged,
    required this.onUnitChanged,
  });

  final String title;
  final String hintText;
  final List<Unit> unitOptions;
  final SimpleConvertorUiState state;
  final FieldConstraints constraints;
  final void Function(double?) onValueChanged;
  final void Function(Unit) onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: title,
      isSubscreen: true,
      body: ListView(
        children: [
          UnitInputWithPicker(
            value: state.rawValue,
            constraints: constraints,
            displayUnit: state.inputUnit,
            onChanged: onValueChanged,
            onUnitChanged: onUnitChanged,
            options: unitOptions,
            hintText: hintText,
          ),
          const Divider(height: 24),
          for (final section in state.sections) ...[
            ListSectionTile(section.titleBuilder(l10n)),
            for (final field in section.fields)
              InfoListTile(
                label: field.labelBuilder(l10n),
                value: field.formattedValue,
              ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
