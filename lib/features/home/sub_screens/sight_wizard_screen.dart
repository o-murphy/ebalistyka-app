import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:bclibc_ffi/unit.dart' show Unit;
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/sight_wizard_notifier.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/mixins/wizard_form_mixin.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/offsets_edit.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:ebalistyka/shared/widgets/wizard_action_bar.dart';
import 'package:ebalistyka/shared/widgets/wizard_name_field.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/widgets/help_dialog.dart';

class SightWizardScreen extends ConsumerStatefulWidget {
  const SightWizardScreen({this.initial, super.key});

  /// Pre-fill the form with an existing sight (edit mode).
  /// null = new empty sight.
  final Sight? initial;

  @override
  ConsumerState<SightWizardScreen> createState() => _SightWizardScreenState();
}

class _SightWizardScreenState extends ConsumerState<SightWizardScreen>
    with WizardFormMixin<SightWizardScreen> {
  @override
  String get initialName => widget.initial?.name ?? '';

  @override
  String get initialVendor => widget.initial?.vendor ?? '';

  NotifierProvider<SightWizardNotifier, SightWizardState> get _provider =>
      sightWizardProvider((initial: widget.initial));

  @override
  void onNameChanged() {
    ref.read(_provider.notifier).updateName(nameController.text);
    super.onNameChanged();
  }

  void _onSave() {
    ref.read(_provider.notifier).updateVendor(vendorController.text);
    commitSave(ref.read(_provider).buildSight);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final units = ref.watch(unitSettingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: wizardTitle(l10n.newSight),
      isSubscreen: true,
      showBack: false,
      actions: [HelpAction(HelpData.sightWizard)],
      bottomBar: WizardActionBar(
        onDiscard: onDiscard,
        onSave: st.isValid ? _onSave : null,
      ),
      body: ListView(
        children: [
          _SightPlaceholder(),
          // ── Name ──────────────────────────────────────────────────
          WizardNameField(
            controller: nameController,
            label: l10n.sightName,
            onChanged: onNameChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: vendorController,
              decoration: InputDecoration(labelText: l10n.vendor),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          // ── Mounting ──────────────────────────────────────────────
          const TileDivider(),
          ListSectionTile(l10n.sectionMounting),
          UnitValueFieldTile(
            title: l10n.sightHeight,
            rawValue: st.sightHeightRaw,
            constraints: FC.sightHeight,
            displayUnit: units.sightHeightUnit,
            icon: IconDef.height,
            onChanged: notifier.updateSightHeightRaw,
          ),
          UnitValueFieldTile(
            title: l10n.horizontalOffset,
            rawValue: st.horizontalOffsetRaw,
            constraints: FC.sightHeight,
            displayUnit: units.sightHeightUnit,
            icon: IconDef.horizontalOffset,
            onChanged: notifier.updateHorizontalOffsetRaw,
          ),
          // ── Reticle ────────────────────────────────────────────────
          const TileDivider(),
          ListSectionTile(l10n.sectionReticle),
          ListTile(
            leading: const Icon(IconDef.sight),
            title: Text(l10n.reticlePattern),
            subtitle: Text(st.reticleImage ?? l10n.defaultLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final route = widget.initial != null
                  ? Routes.sightEditReticlePicker
                  : Routes.sightReticlePicker;
              final result = await context.push<String?>(
                route,
                extra: st.reticleImage,
              );
              if (result != null && mounted) {
                notifier.updateReticleImage(result);
              }
            },
            dense: true,
          ),
          const TileDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<FocalPlane>(
              segments: [
                ButtonSegment(
                  value: FocalPlane.ffp,
                  label: Text(l10n.focalPlaneFFP),
                  icon: Icon(IconDef.ffp),
                ),
                ButtonSegment(
                  value: FocalPlane.sfp,
                  label: Text(l10n.focalPlaneSFP),
                  icon: Icon(IconDef.sfp),
                ),
                ButtonSegment(
                  value: FocalPlane.lwir,
                  label: Text(l10n.focalPlaneLWIR),
                  icon: Icon(IconDef.lwir),
                ),
              ],
              selected: {st.focalPlane},
              onSelectionChanged: (s) => notifier.updateFocalPlane(s.first),
            ),
          ),
          UnitValueFieldTile(
            title: l10n.minMagnification,
            rawValue: st.minMagRaw,
            constraints: FC.magnification,
            displayUnit: Unit.scalar,
            symbol: 'x',
            icon: IconDef.magnificationMin,
            onChanged: notifier.updateMinMagRaw,
          ),
          UnitValueFieldTile(
            title: l10n.maxMagnification,
            rawValue: st.maxMagRaw,
            constraints: FC.magnification,
            displayUnit: Unit.scalar,
            symbol: 'x',
            icon: IconDef.magnificationMax,
            onChanged: notifier.updateMaxMagRaw,
          ),
          // ── Clicks ────────────────────────────────────────────────
          const TileDivider(),
          ListSectionTile(l10n.sectionClicks),
          OffsetsTiles(
            yLabel: l10n.verticalClick,
            xLabel: l10n.horizontalClick,
            unitLabel: l10n.clickUnit,
            yRaw: st.vClickRaw,
            xRaw: st.hClickRaw,
            yUnits: st.vClickUnit,
            xUnits: st.hClickUnit,
            onYChanged: notifier.updateVClickRaw,
            onXChanged: notifier.updateHClickRaw,
            onYUnitChanged: notifier.updateVClickUnit,
            onXUnitChanged: notifier.updateHClickUnit,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SightPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 160,
        child: Card(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconDef.sight, size: 40, color: cs.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  l10n.sightImage,
                  style: TextStyle(color: cs.outlineVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
