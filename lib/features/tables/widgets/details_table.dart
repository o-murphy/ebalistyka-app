import 'package:ebalistyka/features/tables/details_table_mv.dart';
import 'package:ebalistyka/shared/consts.dart';
import 'package:ebalistyka/shared/widgets/empty_state.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

class DetailsTable extends ConsumerWidget {
  const DetailsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(detailsTableMvProvider);

    if (details == null) {
      return const EmptyStatePlaceholder();
    }

    return DetailsTableContent(details: details);
  }
}

class DetailsTableContent extends StatelessWidget {
  const DetailsTableContent({required this.details, super.key});

  final DetailsTableData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget row(String label, String value) => ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          color: cs.onSurface,
        ),
      ),
    );

    Widget section(String title) => ListSectionTile(title);

    String v(String? s) => s?.isNotEmpty == true ? s! : nullStr;

    final items = <Widget>[
      // Rifle
      section('Weapon'),
      row('Name', v(details.weaponName.isNotEmpty ? details.weaponName : null)),
      row('Caliber', v(details.caliber)),
      row('Twist', v(details.twist)),
      row('Zero distance', v(details.zeroDist)),
      const TileDivider(),

      // Cartridge
      section('Cartridge'),
      row('Zero MV', v(details.zeroMv)),
      row('Current MV', v(details.currentMv)),
      const TileDivider(),

      // Projectile
      section('Projectile'),
      row('Drag model', v(details.dragModel)),
      row('BC', v(details.bc)),
      row('Length', v(details.bulletLen)),
      row('Diameter', v(details.bulletDiam)),
      row('Weight', v(details.bulletWeight)),
      row('Form factor', v(details.formFactor)),
      row('Sectional density', v(details.sectionalDensity)),
      row('Gyrostability (Sg)', v(details.gyroStability)),
      const TileDivider(),

      // Conditions
      section('Conditions'),
      row('Temperature', v(details.temperature)),
      row('Humidity', v(details.humidity)),
      row('Pressure', v(details.pressure)),
      row('Wind speed', v(details.windSpeed)),
      row('Wind direction', v(details.windDir)),
    ];

    return ListView(children: items);
  }
}
