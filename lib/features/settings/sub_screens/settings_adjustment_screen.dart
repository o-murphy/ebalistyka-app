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

    return BaseScreen(
      title: 'Adjustment Display',
      isSubscreen: true,
      body: ListView(
        children: [
          const ListSectionTile('Format'),
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
          const ListSectionTile('Show units'),
          SwitchListTile(
            title: const Text('MRAD'),
            value: settings.homeShowMrad,
            onChanged: (v) => notifier.setAdjustmentToggle('showMrad', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MOA'),
            value: settings.homeShowMoa,
            onChanged: (v) => notifier.setAdjustmentToggle('showMoa', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('MIL'),
            value: settings.homeShowMil,
            onChanged: (v) => notifier.setAdjustmentToggle('showMil', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('cm / 100m'),
            value: settings.homeShowCmPer100m,
            onChanged: (v) => notifier.setAdjustmentToggle('showCmPer100m', v),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('in / 100yd'),
            value: settings.homeShowInPer100yd,
            onChanged: (v) => notifier.setAdjustmentToggle('showInPer100yd', v),
            dense: true,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
