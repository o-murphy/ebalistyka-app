import 'package:ebalistyka/core/services/ebcp_service.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:url_launcher/url_launcher.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? GeneralSettings();

    final notifier = ref.read(settingsProvider.notifier);
    final tt = Theme.of(context).textTheme;

    final distanceUnit = ref.watch(unitSettingsProvider).distanceUnit;

    return BaseScreen(
      title: 'Settings',
      body: ListView(
        children: [
          // ── Language ───────────────────────────────────────────────────
          ListSectionTile('Language'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(_languageName(settings.languageCode)),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => _showLanguageDialog(
              context,
              settings.languageCode,
              notifier.setLanguage,
            ),
          ),

          // ── Appearance ─────────────────────────────────────────────────
          ListSectionTile('Appearance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _ThemeSelector(
              current: settings.flutterThemeMode,
              onChanged: notifier.setThemeMode,
            ),
          ),

          const Divider(height: 1),

          // ── Display settings ─────────────────────────────────────────────────
          ListSectionTile('Display settings'),
          ListTile(
            leading: const Icon(Icons.straighten_outlined),
            title: const Text('Units of Measurement'),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => context.push(Routes.settingsUnits),
          ),

          const Divider(height: 1),

          // ── Home screen props ─────────────────────────────────────────────────
          ListSectionTile('Home screen'),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('Adjustment Display'),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => context.push(Routes.settingsAdjustment),
          ),
          SwitchListTile(
            secondary: const Icon(IconDef.velocity),
            title: const Text('Show subsonic transition'),
            subtitle: const Text('Displays on trajectory chart'),
            value: settings.homeShowSubsonicTransition,
            onChanged: (v) =>
                notifier.setAdjustmentToggle('subsonicTransition', v),
            dense: true,
          ),

          UnitValueFieldTile(
            icon: Icons.table_rows_outlined,
            title: 'Table distance step',
            rawValue: settings.homeTableDistanceStep,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => notifier.setHomeTableStep(v),
          ),
          UnitValueFieldTile(
            icon: Icons.show_chart_outlined,
            title: 'Chart distance step',
            rawValue: settings.homeChartDistanceStep,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => notifier.setChartDistanceStep(v),
          ),

          const Divider(height: 1),

          // ── Profiles ───────────────────────────────────────────────────
          ListSectionTile('Backup'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(IconDef.export),
                    label: const Text('Export backup'),
                    onPressed: () async {
                      final file = EbcpService.buildFullExport(ref);
                      await EbcpService.shareFile(file, 'ebalistyka_backup');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(IconDef.import),
                    label: const Text('Import backup'),
                    onPressed: () async {
                      final file = await EbcpService.pickAndParse();
                      if (file == null) return;
                      await EbcpService.restoreFromExport(file, ref);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Links ──────────────────────────────────────────────────────
          ListSectionTile('Links'),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () =>
                _launchUrl("https://github.com/o-murphy/ebalistyka-app"),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Terms of Use'),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () {},
          ),

          const Divider(height: 1),

          // ── About ──────────────────────────────────────────────────────
          ListSectionTile('About'),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('Version'),
            trailing: Text(
              ref
                  .watch(_packageInfoProvider)
                  .when(
                    data: (i) => i.buildNumber.isNotEmpty
                        ? '${i.version}+${i.buildNumber}'
                        : i.version,
                    loading: () => '…',
                    error: (_, _) => '?',
                  ),
              style: tt.bodySmall,
            ),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: const Text('Changelog'),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () => _launchUrl(
              "https://github.com/o-murphy/ebalistyka-app/blob/main/CHANGELOG.md",
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Language helpers ─────────────────────────────────────────────────────────

String _languageName(String code) => switch (code) {
  'uk' => 'Українська',
  _ => 'English',
};

void _showLanguageDialog(
  BuildContext context,
  String current,
  Future<void> Function(String) onSelect,
) {
  const langs = [('en', 'English'), ('uk', 'Українська')];
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Language'),
      content: RadioGroup<String>(
        groupValue: current,
        onChanged: (v) {
          if (v != null) {
            onSelect(v);
            Navigator.pop(ctx);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: langs
              .map((l) => RadioListTile<String>(value: l.$1, title: Text(l.$2)))
              .toList(),
        ),
      ),
    ),
  );
}

// ─── Theme selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChanged});
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text('System'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text('Dark'),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(
    uri,
    mode: LaunchMode.externalApplication, // Opens in an external browser
  )) {
    throw Exception('Could not launch $url');
  }
}
