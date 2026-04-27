import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/models/unit_picker_context.dart';
import 'package:ebalistyka/shared/widgets/icon_value_button.dart';
import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/shared/widgets/unit_hybrid_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditionsAsync = ref.watch(shotConditionsProvider);
    final conditions = conditionsAsync.value;
    if (conditions == null) return const SizedBox.shrink();

    final units = ref.watch(unitSettingsProvider);
    final formatter = ref.watch(unitFormatterProvider);
    final notifier = ref.read(shotConditionsProvider.notifier);

    final windMps = conditions.windSpeedMps;
    final windDisplay = formatter.windSpeed(conditions.windSpeed);

    final lookDeg = conditions.lookAngle.in_(Unit.degree);
    final lookDisplay = '${lookDeg.toFixedSafe(FC.lookAngle.accuracy)}°';

    final distDisplay = formatter.distance(conditions.distance);
    final distM = conditions.distanceMeter;

    final UnitPickerContext windSpeedCtx = UnitPickerContext(
      context,
      label: 'Wind speed',
      rawValue: windMps,
      constraints: RC.windSpeed,
      displayUnit: units.velocityUnit,
      onChanged: (v) => notifier.updateWindSpeed(v!),
    );

    final UnitPickerContext lookAngleCtx = UnitPickerContext(
      context,
      label: 'Look angle',
      rawValue: lookDeg,
      constraints: RC.lookAngle,
      displayUnit: Unit.degree,
      onChanged: (v) => notifier.updateLookAngle(v!),
    );

    final UnitPickerContext targetRangeCtx = UnitPickerContext(
      context,
      label: 'Target range',
      rawValue: distM,
      constraints: RC.targetDistance,
      displayUnit: units.distanceUnit,
      onChanged: (v) => notifier.updateDistance(v!),
    );

    return IconValueButtonRow(
      height: 104,
      items: [
        IconValueButton(
          icon: IconDef.windSpeed,
          value: windDisplay,
          label: 'Wind speed',
          heroTag: 'qa-wind',
          onTap: () => showUnitHybridPickerDialog(windSpeedCtx),
        ),
        IconValueButton(
          icon: IconDef.angle,
          value: lookDisplay,
          label: 'Look angle',
          heroTag: 'qa-angle',
          onTap: () => showUnitHybridPickerDialog(lookAngleCtx),
        ),
        IconValueButton(
          icon: IconDef.range,
          value: distDisplay,
          label: 'Target range',
          heroTag: 'qa-range',
          onTap: () => showUnitHybridPickerDialog(targetRangeCtx),
        ),
      ],
    );
  }
}
