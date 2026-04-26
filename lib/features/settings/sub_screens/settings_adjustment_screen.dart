import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';

// ─── Adjustment Display Screen ────────────────────────────────────────────────

class AdjustmentDisplayScreen extends ConsumerWidget {
  const AdjustmentDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? GeneralSettings();
    final notifier = ref.read(settingsProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: l10n.adjustmentDisplayScreenTitle,
      isSubscreen: true,
      body: ListView(
        children: [
          ListSectionTile(l10n.adjustmentDisplayFormat),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<AdjustmentDisplayFormat>(
              segments: const [
                ButtonSegment(
                  value: AdjustmentDisplayFormat.arrows,
                  label: Text('↑/↓'),
                ),
                ButtonSegment(
                  value: AdjustmentDisplayFormat.signs,
                  label: Text('+/−'),
                ),
                ButtonSegment(
                  value: AdjustmentDisplayFormat.letters,
                  label: Text('U/D'),
                ),
              ],
              selected: {settings.adjustmentDisplayFormat},
              onSelectionChanged: (s) => notifier.setAdjustmentFormat(s.first),
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const Divider(height: 1),
          ListSectionTile(l10n.sectionShowAdjustmentsIn),
          SwitchListTile(
            title: Text(l10n.unitMrad),
            value: settings.homeShowMrad,
            onChanged: (v) => notifier.setAdjustmentToggle('showMrad', v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitMoa),
            value: settings.homeShowMoa,
            onChanged: (v) => notifier.setAdjustmentToggle('showMoa', v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitMoa),
            value: settings.homeShowMil,
            onChanged: (v) => notifier.setAdjustmentToggle('showMil', v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitCmPer100m),
            value: settings.homeShowCmPer100m,
            onChanged: (v) => notifier.setAdjustmentToggle('showCmPer100m', v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitInPer100Yd),
            value: settings.homeShowInPer100yd,
            onChanged: (v) => notifier.setAdjustmentToggle('showInPer100yd', v),
            dense: true,
          ),
          SwitchListTile(
            title: Text(l10n.unitClicks),
            value: settings.homeShowInClicks,
            onChanged: (v) => notifier.setAdjustmentToggle('showInClicks', v),
            dense: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
