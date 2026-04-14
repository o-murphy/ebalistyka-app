import 'package:ebalistyka/core/extensions/conditions_extensions.dart';
import 'package:ebalistyka/core/extensions/num_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/core/providers/shot_conditions_provider.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/icon_value_button.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_dialog.dart';
import 'package:bclibc_ffi/unit.dart';
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
    final fmt = ref.watch(unitFormatterProvider);
    final notifier = ref.read(shotConditionsProvider.notifier);

    final windMps = conditions.windSpeedMps;
    final windDisplay = fmt.windSpeed(conditions.windSpeed);

    final lookDeg = conditions.lookAngle.in_(Unit.degree);
    final lookDisplay = '${lookDeg.toFixedSafe(FC.lookAngle.accuracy)}°';

    final distDisplay = fmt.distance(conditions.distance);
    final distM = conditions.distanceMeter;

    return IconValueButtonRow(
      height: 104,
      items: [
        IconValueButton(
          icon: IconDef.windSpeed,
          value: windDisplay,
          label: 'Wind speed',
          heroTag: 'qa-wind',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Wind speed',
            rawValue: windMps,
            constraints: FC.windSpeed,
            displayUnit: units.velocityUnit,
            onChanged: notifier.updateWindSpeed,
          ),
        ),
        IconValueButton(
          icon: IconDef.angle,
          value: lookDisplay,
          label: 'Look angle',
          heroTag: 'qa-angle',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Look angle',
            rawValue: lookDeg,
            constraints: FC.lookAngle,
            displayUnit: Unit.degree,
            onChanged: notifier.updateLookAngle,
          ),
        ),
        IconValueButton(
          icon: IconDef.range,
          value: distDisplay,
          label: 'Target range',
          heroTag: 'qa-range',
          onTap: () => showUnitEditDialog(
            context,
            label: 'Target range',
            rawValue: distM,
            constraints: FC.targetDistance,
            displayUnit: units.distanceUnit,
            onChanged: notifier.updateDistance,
          ),
        ),
      ],
    );
  }
}
