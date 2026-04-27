import 'package:ebalistyka/features/tables/details_table_mv.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
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
    final l10n = AppLocalizations.of(context)!;

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
      section(l10n.weapon),
      row(
        l10n.name,
        v(details.weaponName.isNotEmpty ? details.weaponName : null),
      ),
      row(l10n.caliber, v(details.caliber)),
      row(l10n.twist, v(details.twist)),
      row(l10n.zeroDistance, v(details.zeroDist)),
      const TileDivider(),

      // Cartridge
      section(l10n.cartridge),
      row(l10n.zeroMv, v(details.zeroMv)),
      row(l10n.currentMv, v(details.currentMv)),
      const TileDivider(),

      // Projectile
      section(l10n.projectile),
      row(l10n.dragModel, v(details.dragModel)),
      row(l10n.bc, v(details.bc)),
      row(l10n.length, v(details.bulletLen)),
      row(l10n.diameter, v(details.bulletDiam)),
      row(l10n.weight, v(details.bulletWeight)),
      row(l10n.formFactor, v(details.formFactor)),
      row(l10n.sectionalDensity, v(details.sectionalDensity)),
      row(l10n.gyrostabilitySg, v(details.gyroStability)),
      const TileDivider(),

      // Conditions
      section(l10n.conditions),
      row(l10n.temperature, v(details.temperature)),
      row(l10n.humidity, v(details.humidity)),
      row(l10n.pressure, v(details.pressure)),
      row(l10n.windSpeed, v(details.windSpeed)),
      row(l10n.windDirection, v(details.windDir)),
    ];

    return ListView(children: items);
  }
}
