import 'dart:async';
import 'package:ebalistyka/shared/constants/app_info.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:ebalistyka/core/services/ebcp_service.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:ebalistyka/update/update_checker.dart';
import 'package:ebalistyka/update/update_sheet.dart';
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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _checkingUpdate = false;
  bool _checkingCollection = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checkingUpdate = true);
    try {
      final release = await checkForUpdate();
      if (!mounted) return;
      if (release != null) {
        showUpdateBottomSheet(context, release);
      } else {
        showFeedback(context, AppLocalizations.of(context)!.upToDateMessage);
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _checkForCollectionUpdate() async {
    setState(() => _checkingCollection = true);
    try {
      final updated = await checkForCollectionUpdate(ref);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showFeedback(
        context,
        updated
            ? l10n.collectionUpdatedMessage
            : l10n.collectionUpToDateMessage,
      );
    } catch (e) {
      if (!mounted) return;
      showFeedback(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _checkingCollection = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? GeneralSettings();

    final notifier = ref.read(settingsProvider.notifier);
    final tt = Theme.of(context).textTheme;

    final distanceUnit = ref.watch(unitSettingsProvider).distanceUnit;
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: l10n.settingsScreenTitle,
      body: ListView(
        children: [
          // ── Language ───────────────────────────────────────────────────
          ListSectionTile(l10n.sectionLanguage),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(_languageName(settings.languageCode)),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => _showLanguageDialog(
              context,
              l10n.sectionLanguage,
              settings.languageCode,
              notifier.setLanguage,
            ),
          ),

          // ── Appearance ─────────────────────────────────────────────────
          ListSectionTile(l10n.sectionAppearance),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _ThemeSelector(
              current: settings.flutterThemeMode,
              onChanged: notifier.setThemeMode,
            ),
          ),

          const TileDivider(),

          // ── Display settings ─────────────────────────────────────────────────
          ListSectionTile(l10n.sectionUnitsSettings),
          ListTile(
            leading: const Icon(Icons.straighten_outlined),
            title: Text(l10n.unitsSettingsLabel),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => context.push(Routes.settingsUnits),
          ),

          const TileDivider(),

          // ── Home screen props ─────────────────────────────────────────────────
          ListSectionTile(l10n.sectionHomeSettings),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: Text(l10n.adjustmentDisplayScreenTitle),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => context.push(Routes.settingsAdjustment),
          ),
          SwitchListTile(
            secondary: const Icon(IconDef.velocity),
            title: Text(l10n.switchShowSubsonicTransition),
            subtitle: Text(l10n.switchShowSubsonicTransitionSubtitle),
            value: settings.homeShowSubsonicTransition,
            onChanged: (v) =>
                notifier.setAdjustmentToggle('subsonicTransition', v),
            dense: true,
          ),

          UnitValueFieldTile(
            icon: Icons.table_rows_outlined,
            title: l10n.labelTrajectoryTableStep,
            rawValue: settings.homeTableDistanceStep,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => notifier.setHomeTableStep(v),
          ),
          UnitValueFieldTile(
            icon: Icons.show_chart_outlined,
            title: l10n.labelTrajectoryChartStep,
            rawValue: settings.homeChartDistanceStep,
            constraints: FC.distanceStep,
            displayUnit: distanceUnit,
            onChanged: (v) => notifier.setChartDistanceStep(v),
          ),

          const TileDivider(),

          // ── Profiles ───────────────────────────────────────────────────
          ListSectionTile(l10n.sectionBackup),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(IconDef.export),
                    label: Text(l10n.actionExportBackup),
                    onPressed: () async {
                      final file = EbcpService.buildFullExport(ref);
                      final messenger = ScaffoldMessenger.of(context);
                      final errorColor =
                          Theme.of(context).colorScheme.error;
                      try {
                        await EbcpService.shareFile(file, 'ebalistyka_backup');
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: errorColor,
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(IconDef.import),
                    label: Text(l10n.actionImportBackup),
                    onPressed: () async {
                      try {
                        final file = await EbcpService.pickAndParse();
                        if (file == null || !context.mounted) return;
                        await EbcpService.restoreFromExport(file, ref);
                      } catch (e) {
                        if (!context.mounted) return;
                        showFeedback(
                          context,
                          '${l10n.errorImportBackupFailed}: $e',
                          isError: true,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const TileDivider(),

          // ── Collection ─────────────────────────────────────────────────
          ListSectionTile(l10n.sectionCollection),
          ListTile(
            leading: const Icon(Icons.dataset_outlined),
            title: Text(l10n.collectionVersionLabel),
            trailing: Text(
              ref
                  .watch(collectionShaProvider)
                  .when(
                    data: (sha) => sha != null
                        ? sha.substring(0, sha.length.clamp(0, 7))
                        : '—',
                    loading: () => '…',
                    error: (_, _) => '?',
                  ),
              style: tt.bodySmall,
            ),
            dense: true,
          ),
          ListTile(
            leading: _checkingCollection
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_download_outlined),
            title: Text(l10n.checkForCollectionUpdatesLabel),
            dense: true,
            onTap: _checkingCollection ? null : _checkForCollectionUpdate,
          ),

          const TileDivider(),

          // ── Links ──────────────────────────────────────────────────────
          ListSectionTile(l10n.sectionLinks),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('GitHub'),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () => _launchUrl(repoUrl),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.labelPrivacyPolicy),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () => _launchUrl(privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l10n.labelTermsOfUse),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () => _launchUrl(tosUrl),
          ),

          const TileDivider(),

          // ── About ──────────────────────────────────────────────────────
          ListSectionTile(l10n.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: Text(l10n.labelVersion),
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
            leading: _checkingUpdate
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.system_update_outlined),
            title: Text(l10n.checkForUpdatesLabel),
            dense: true,
            onTap: _checkingUpdate ? null : _checkForUpdates,
          ),
          ListTile(
            leading: const Icon(Icons.history_outlined),
            title: Text(l10n.labelChangelog),
            trailing: const Icon(IconDef.link, size: 16),
            dense: true,
            onTap: () => _launchUrl(changelogUrl),
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
  String title,
  String current,
  Future<void> Function(String) onSelect,
) {
  const langs = [('en', 'English'), ('uk', 'Українська')];
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const TileDivider(),

            RadioGroup<String>(
              groupValue: current,
              onChanged: (v) {
                if (v != null) {
                  unawaited(onSelect(v));
                  Navigator.pop(ctx);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: langs
                    .map(
                      (l) =>
                          RadioListTile<String>(value: l.$1, title: Text(l.$2)),
                    )
                    .toList(),
              ),
            ),
          ],
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
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_outlined),
          label: Text(l10n.themeSystem, overflow: TextOverflow.ellipsis),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_outlined),
          label: Text(l10n.themeLight, overflow: TextOverflow.ellipsis),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_outlined),
          label: Text(l10n.themeDark, overflow: TextOverflow.ellipsis),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  await launchUrl(uri, mode: LaunchMode.platformDefault);
}
