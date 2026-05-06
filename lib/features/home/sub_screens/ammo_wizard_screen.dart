import 'dart:async';
import 'package:ebalistyka/core/providers/app_state_provider.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_notifier.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/action_sheet.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';
import 'package:ebalistyka/shared/widgets/help_dialog.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/mixins/wizard_form_mixin.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/coriolis_section.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/offsets_edit.dart';
import 'package:ebalistyka/shared/widgets/powder_sens_section.dart';
import 'package:ebalistyka/features/home/sub_screens/powder_sens_table_editor_screen.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:ebalistyka/shared/widgets/wizard_action_bar.dart';
import 'package:ebalistyka/shared/widgets/wizard_name_field.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart' hide Velocity;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reusable ammo form: null = create new, non-null = edit existing.
/// Returns Ammo? via context.pop(ammo).
class AmmoWizardScreen extends ConsumerStatefulWidget {
  const AmmoWizardScreen({
    this.initial,
    this.caliberInch,
    this.weaponId,
    super.key,
  });

  /// Pre-fill the form with an existing ammo (edit mode).
  /// null = new empty ammo.
  final Ammo? initial;

  /// Caliber set by the profile's weapon (create mode only).
  /// In edit mode the caliber is taken from [initial].
  /// Displayed readonly — never entered manually.
  final double? caliberInch;

  /// ID of the weapon associated with this ammo session.
  /// When set and a caliber mismatch exists, the action sheet offers an
  /// option to update the weapon caliber instead of the ammo.
  final int? weaponId;

  @override
  ConsumerState<AmmoWizardScreen> createState() => _AmmoWizardScreenState();
}

class _AmmoWizardScreenState extends ConsumerState<AmmoWizardScreen>
    with WizardFormMixin<AmmoWizardScreen> {
  late final TextEditingController _projectileNameController;

  final _scrollController = ScrollController();
  final _powderSensKey = GlobalKey();
  final _coriolisKey = GlobalKey();

  NotifierProvider<AmmoWizardNotifier, AmmoWizardState> get _provider =>
      ammoWizardProvider((
        initial: widget.initial,
        caliberInch: widget.caliberInch,
      ));

  @override
  String get initialName => widget.initial?.name ?? '';

  @override
  String get initialVendor => widget.initial?.vendor ?? '';

  @override
  void onNameChanged() {
    ref.read(_provider.notifier).updateName(nameController.text);
    super.onNameChanged();
  }

  @override
  void initState() {
    super.initState();
    _projectileNameController = TextEditingController(
      text: widget.initial?.projectileName ?? '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _scheduleCaliberMismatchSheet(l10n: l10n);
      }
    });
  }

  @override
  void dispose() {
    _projectileNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCaliberMismatchSheet({required AppLocalizations l10n}) {
    final weaponCaliber = widget.caliberInch;
    final ammoCaliber = widget.initial?.caliber.in_(Unit.inch);
    if (weaponCaliber == null || ammoCaliber == null) return;
    if ((weaponCaliber - ammoCaliber).abs() < 0.0001) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final formatter = ref.read(unitFormatterProvider);
      final ammoStr = formatter.diameter(Distance.inch(ammoCaliber));
      final weaponStr = formatter.diameter(Distance.inch(weaponCaliber));

      await showActionSheet(
        context,
        title: l10n.caliberMismatchTitle,
        subtitle: l10n.caliberMismatchWarning(ammoStr, weaponStr),
        entries: [
          ActionSheetItem(
            icon: IconDef.ammo,
            title: l10n.updateAmmoCaliberAction,
            subtitle: '$ammoStr → $weaponStr',
            onTap: () async => ref
                .read(_provider.notifier)
                .updateCaliberRaw(
                  Distance.inch(
                    weaponCaliber,
                  ).in_(FC.projectileDiameter.rawUnit),
                ),
          ),
          if (widget.weaponId != null)
            ActionSheetItem(
              icon: IconDef.weapon,
              title: l10n.updateWeaponCaliberAction,
              subtitle: '$weaponStr → $ammoStr',
              onTap: () async {
                final weapon = ref
                    .read(appStateProvider)
                    .value
                    ?.weapons
                    .where((w) => w.id == widget.weaponId)
                    .firstOrNull;
                if (weapon == null) return;
                weapon.caliber = Distance.inch(ammoCaliber);
                await ref.read(appStateProvider.notifier).saveWeapon(weapon);
              },
            ),
        ],
      );
    });
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
        );
      }
    });
  }

  void _onSave() {
    final notifier = ref.read(_provider.notifier);
    notifier.updateVendor(vendorController.text);
    notifier.updateProjectileName(_projectileNameController.text);
    commitSave(ref.read(_provider).buildAmmo);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _onDragTableTap() async {
    final result = await context.push<List<({double mach, double cd})>>(
      Routes.ammoEditDragTable,
      extra: ref.read(_provider).customDragTable,
    );
    if (!mounted || result == null) return;
    ref
        .read(_provider.notifier)
        .updateCustomDragTable(result.isEmpty ? null : result);
  }

  Future<void> _onPowderSensTableTap() async {
    final st = ref.read(_provider);
    final mvMps = st.mvRaw == null
        ? null
        : Velocity(st.mvRaw!, FC.muzzleVelocity.rawUnit).in_(Unit.mps);
    final tempC = Temperature(
      st.mvTempRaw,
      FC.temperature.rawUnit,
    ).in_(Unit.celsius);
    final result = await context.push<PowderSensTableResult>(
      Routes.ammoEditPowderSensTable,
      extra: (table: st.powderSensTable, mvMps: mvMps, tempC: tempC),
    );
    if (!mounted || result == null) return;
    final sens = result.sensitivity;
    ref
        .read(_provider.notifier)
        .updatePowderSensTable(
          result.table.isEmpty ? null : result.table,
          sensitivityFrac: sens != null && result.table.isNotEmpty
              ? sens.clamp(0.0, double.infinity)
              : null,
        );
  }

  Future<void> _navigateToMultiBcEditor(DragType dt) async {
    final st = ref.read(_provider);
    final table = dt == DragType.g1 ? st.multiBcG1Table : st.multiBcG7Table;
    final bc = dt == DragType.g1 ? st.bcG1 : st.bcG7;
    final route = dt == DragType.g1
        ? Routes.ammoEditMultiBcG1
        : Routes.ammoEditMultiBcG7;
    final mvMps = st.mvRaw == null
        ? null
        : Velocity(st.mvRaw!, FC.muzzleVelocity.rawUnit).in_(Unit.mps);

    final result = await context.push<List<({double vMps, double bc})>>(
      route,
      extra: (table: table, mvMps: mvMps, bc: bc),
    );

    if (!mounted || result == null) return;
    if (dt == DragType.g1) {
      ref
          .read(_provider.notifier)
          .updateMultiBcG1Table(result.isEmpty ? null : result);
    } else {
      ref
          .read(_provider.notifier)
          .updateMultiBcG7Table(result.isEmpty ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(_provider);
    final units = ref.watch(unitSettingsProvider);
    final formatter = ref.watch(unitFormatterProvider);
    final notifier = ref.read(_provider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return BaseScreen(
      title: wizardTitle(l10n.newAmmo),
      isSubscreen: true,
      showBack: false,
      actions: [HelpAction(HelpData.ammoWizard)],
      bottomBar: WizardActionBar(
        onDiscard: onDiscard,
        onSave: st.isValid ? _onSave : null,
      ),
      body: ListView(
        controller: _scrollController,
        children: [
          _AmmoPlaceholder(),
          // ── Name ──────────────────────────────────────────────────
          WizardNameField(
            controller: nameController,
            label: l10n.ammoName,
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
          // ── Projectile ──────────────────────────────────────────────
          const TileDivider(),
          ListSectionTile(l10n.projectile),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _projectileNameController,
              decoration: InputDecoration(labelText: l10n.projectileName),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          InfoListTile(
            label: l10n.caliber,
            value: formatter.diameter(
              Distance(st.caliberRaw, FC.projectileDiameter.rawUnit),
            ),
            icon: IconDef.caliber,
          ),
          NullableUnitValueFieldTile(
            title: l10n.weight,
            rawValue: st.weightRaw,
            constraints: FC.projectileWeight,
            displayUnit: units.weightUnit,
            icon: IconDef.weigth,
            isRequired: true,
            onChanged: notifier.updateWeightRaw,
          ),
          NullableUnitValueFieldTile(
            title: l10n.length,
            rawValue: st.lengthRaw,
            constraints: FC.projectileLength,
            displayUnit: units.lengthUnit,
            icon: IconDef.length,
            isRequired: true,
            onChanged: notifier.updateLengthRaw,
          ),
          _DragModelSection(
            st: st,
            onDragTypeChanged: notifier.updateDragType,
            onMultiBcG1Changed: notifier.updateUseMultiBcG1,
            onBcG1Changed: notifier.updateBcG1,
            onMultiBcG7Changed: notifier.updateUseMultiBcG7,
            onBcG7Changed: notifier.updateBcG7,
            onNavigateToMultiBcG1: () =>
                unawaited(_navigateToMultiBcEditor(DragType.g1)),
            onNavigateToMultiBcG7: () =>
                unawaited(_navigateToMultiBcEditor(DragType.g7)),
            onNavigateToDragTable: _onDragTableTap,
          ),

          // ── Cartridge ──────────────────────────────────────────────
          const TileDivider(),
          ListSectionTile(l10n.cartridge),
          NullableUnitValueFieldTile(
            title: l10n.muzzleVelocity,
            subtitle: l10n.measuredOrVendorSubtitle,
            rawValue: st.mvRaw,
            constraints: FC.muzzleVelocity,
            displayUnit: units.velocityUnit,
            icon: IconDef.velocity,
            isRequired: true,
            onChanged: notifier.updateMvRaw,
          ),
          UnitValueFieldTile(
            title: l10n.mvTemperatureLabel,
            subtitle: l10n.mvTemperatureSubtitle,
            rawValue: st.mvTempRaw,
            constraints: FC.temperature,
            displayUnit: units.temperatureUnit,
            icon: IconDef.temperature,
            onChanged: notifier.updateMvTempRaw,
          ),
          SwitchListTile(
            title: Text(l10n.powderSensitivity),
            secondary: const Icon(IconDef.powderTemperature),
            value: st.usePowderSensitivity,
            onChanged: (v) {
              notifier.updateUsePowderSensitivity(v);
              if (v) _scrollTo(_powderSensKey);
            },
            dense: true,
          ),

          // ── Zeroing ──────────────────────────────────────────────
          const TileDivider(),
          ListSectionTile(l10n.sectionZeroing),
          UnitValueFieldTile(
            title: l10n.zeroDistance,
            subtitle: l10n.zeroingDistanceSubtitle,
            rawValue: st.zeroDistRaw,
            constraints: FC.zeroDistance,
            displayUnit: units.distanceUnit,
            icon: IconDef.range,
            onChanged: notifier.updateZeroDistRaw,
          ),
          UnitValueFieldTile(
            title: l10n.lookAngle,
            subtitle: l10n.zeroingLookAngleSubtitle,
            rawValue: st.zeroLookAngleRaw,
            constraints: FC.lookAngle,
            displayUnit: units.angularUnit,
            icon: IconDef.angle,
            onChanged: notifier.updateZeroLookAngleRaw,
          ),
          UnitValueFieldTile(
            title: l10n.temperature,
            subtitle: l10n.zeroingTemperatureSubtitle,
            rawValue: st.zeroTempRaw,
            constraints: FC.temperature,
            displayUnit: units.temperatureUnit,
            icon: IconDef.temperature,
            onChanged: notifier.updateZeroTempRaw,
          ),
          UnitValueFieldTile(
            title: l10n.pressure,
            subtitle: l10n.zeroingPressureSubtitle,
            rawValue: st.zeroPressureRaw,
            constraints: FC.pressure,
            displayUnit: units.pressureUnit,
            icon: IconDef.pressure,
            onChanged: notifier.updateZeroPressureRaw,
          ),
          UnitValueFieldTile(
            title: l10n.humidity,
            subtitle: l10n.zeroingHumiditySubtitle,
            rawValue: st.zeroHumidityRaw,
            constraints: FC.humidity,
            displayUnit: Unit.percent,
            icon: IconDef.humidity,
            onChanged: notifier.updateZeroHumidityRaw,
          ),
          UnitValueFieldTile(
            title: l10n.altitude,
            subtitle: l10n.zeroingAltitudeSubtitle,
            rawValue: st.zeroAltRaw,
            constraints: FC.altitude,
            displayUnit: units.distanceUnit,
            icon: IconDef.altitude,
            onChanged: notifier.updateZeroAltRaw,
          ),

          // ── Powder sensitivity ──────────────────────────────────────────────
          if (st.usePowderSensitivity) ...[
            const TileDivider(),
            PowderSensSection(
              key: _powderSensKey,
              showToggle: false,
              usePowderSensitivity: st.usePowderSensitivity,
              useDiffPowderTemp: st.zeroUseDiffPowderTemp,
              temperatureUnit: units.temperatureUnit,
              powderTempRaw: st.zeroPowderTempRaw,
              powderSensRaw: st.powderSensRaw,
              mvValue: () {
                final ammo = st.buildAmmo();
                if (!ammo.isReadyForCalculation) return null;
                return formatter.velocity(
                  ammo.toZeroAmmo().getVelocityForTemp(
                    ammo.toZeroAtmo().powderTemp,
                  ),
                );
              }(),
              sensitivityValue: formatter.powderSensitivity(
                Ratio.fraction(st.powderSensRaw),
              ),
              onDiffTempToggled: notifier.updateZeroUseDiffPowderTemp,
              onPowderTempChanged: notifier.updateZeroPowderTempRaw,
              onPowderSensChanged: notifier.updatePowderSensRaw,
            ),
            ListTile(
              leading: const Icon(IconDef.powderTemperature),
              title: Text(l10n.calculateFromMeasurementsAction),
              subtitle: Text(
                st.powderSensTable != null
                    ? '${st.powderSensTable!.length} measurement${st.powderSensTable!.length == 1 ? '' : 's'}'
                    : 'Tap to add T→V measurements',
              ),
              trailing: const Icon(IconDef.chevronRight),
              dense: true,
              onTap: _onPowderSensTableTap,
            ),
          ],

          // ── Zeroing offset ────────────────────────────────────────
          OffsetsTiles(
            yLabel: l10n.verticalOffset,
            xLabel: l10n.horizontalOffset,
            unitLabel: l10n.clickUnit,
            yRaw: st.offsetYRaw,
            xRaw: st.offsetXRaw,
            yUnits: st.offsetYUnit,
            xUnits: st.offsetXUnit,
            onYChanged: notifier.updateOffsetYRaw,
            onXChanged: notifier.updateOffsetXRaw,
            onYUnitChanged: notifier.updateOffsetYUnit,
            onXUnitChanged: notifier.updateOffsetXUnit,
          ),

          // ── Zeroing coriolis ────────────────────────────────────────
          const TileDivider(),
          CoriolisSection(
            key: _coriolisKey,
            useCoriolis: st.zeroUseCoriolis,
            latitudeRaw: st.zeroLatitudeRaw,
            azimuthRaw: st.zeroAzimuthRaw,
            angularUnit: Unit.degree,
            onCoriolisToggled: (v) {
              notifier.updateZeroUseCoriolis(v);
              if (v) _scrollTo(_coriolisKey);
            },
            onLatitudeChanged: notifier.updateZeroLatitudeRaw,
            onAzimuthChanged: notifier.updateZeroAzimuthRaw,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _AmmoPlaceholder extends StatelessWidget {
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
                Icon(IconDef.ammo, size: 40, color: cs.outlineVariant),
                const SizedBox(height: 8),
                Text(
                  l10n.ammoImage,
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

class _BcSection extends StatelessWidget {
  const _BcSection({
    required this.dt,
    required this.useMulti,
    required this.multiTable,
    required this.bcRaw,
    required this.onMultiChanged,
    required this.onBcChanged,
    required this.onNavigate,
  });

  final DragType dt;
  final bool useMulti;
  final List<({double vMps, double bc})>? multiTable;
  final double? bcRaw;
  final ValueChanged<bool> onMultiChanged;
  final ValueChanged<double?> onBcChanged;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dtName = dt.name.toUpperCase();
    return Column(
      children: [
        SwitchListTile(
          title: Text(l10n.enableMultiBcTitle(dtName)),
          subtitle: Text(
            useMulti ? '$dtName Multi-BC mode' : '$dtName Single BC mode',
          ),
          value: useMulti,
          onChanged: onMultiChanged,
          dense: true,
        ),
        if (!useMulti)
          NullableUnitValueFieldTile(
            title: l10n.ballisticCoefficientLabel(dtName),
            rawValue: bcRaw,
            constraints: FC.ballisticCoefficient,
            displayUnit: Unit.fraction,
            icon: IconDef.dragModel,
            isRequired: true,
            onChanged: onBcChanged,
          ),
        if (useMulti)
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              final isEmpty = multiTable == null || multiTable!.isEmpty;
              final count = multiTable?.length ?? 0;
              return ListTile(
                tileColor: isEmpty ? cs.tertiaryContainer : null,
                leading: Icon(
                  IconDef.dragModel,
                  color: isEmpty ? cs.tertiary : null,
                ),
                title: Text(l10n.editMultiBcTableTitle(dtName)),
                subtitle: Text(
                  isEmpty
                      ? l10n.requiredFieldError
                      : '$count breakpoint${count == 1 ? '' : 's'}',
                  style: isEmpty ? TextStyle(color: cs.error) : null,
                ),
                trailing: const Icon(IconDef.chevronRight),
                dense: true,
                onTap: onNavigate,
              );
            },
          ),
      ],
    );
  }
}

class _DragModelSection extends StatelessWidget {
  const _DragModelSection({
    required this.st,
    required this.onDragTypeChanged,
    required this.onMultiBcG1Changed,
    required this.onBcG1Changed,
    required this.onMultiBcG7Changed,
    required this.onBcG7Changed,
    required this.onNavigateToMultiBcG1,
    required this.onNavigateToMultiBcG7,
    required this.onNavigateToDragTable,
  });

  final AmmoWizardState st;
  final ValueChanged<DragType> onDragTypeChanged;
  final ValueChanged<bool> onMultiBcG1Changed;
  final ValueChanged<double?> onBcG1Changed;
  final ValueChanged<bool> onMultiBcG7Changed;
  final ValueChanged<double?> onBcG7Changed;
  final VoidCallback onNavigateToMultiBcG1;
  final VoidCallback onNavigateToMultiBcG7;
  final VoidCallback onNavigateToDragTable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<DragType>(
              segments: const [
                ButtonSegment(value: DragType.g1, label: Text('G1')),
                ButtonSegment(value: DragType.g7, label: Text('G7')),
                ButtonSegment(value: DragType.custom, label: Text('CUSTOM')),
              ],
              selected: {st.dragType},
              onSelectionChanged: (s) => onDragTypeChanged(s.first),
            ),
          ),
        ),
        if (st.dragType == DragType.g1)
          _BcSection(
            dt: DragType.g1,
            useMulti: st.useMultiBcG1,
            multiTable: st.multiBcG1Table,
            bcRaw: st.bcG1,
            onMultiChanged: onMultiBcG1Changed,
            onBcChanged: onBcG1Changed,
            onNavigate: onNavigateToMultiBcG1,
          ),
        if (st.dragType == DragType.g7)
          _BcSection(
            dt: DragType.g7,
            useMulti: st.useMultiBcG7,
            multiTable: st.multiBcG7Table,
            bcRaw: st.bcG7,
            onMultiChanged: onMultiBcG7Changed,
            onBcChanged: onBcG7Changed,
            onNavigate: onNavigateToMultiBcG7,
          ),
        if (st.dragType == DragType.custom)
          Builder(
            builder: (context) {
              final cs = Theme.of(context).colorScheme;
              final isEmpty =
                  st.customDragTable == null || st.customDragTable!.isEmpty;
              final count = st.customDragTable?.length ?? 0;
              return ListTile(
                tileColor: isEmpty ? cs.tertiaryContainer : null,
                leading: Icon(
                  IconDef.dragModel,
                  color: isEmpty ? cs.tertiary : null,
                ),
                title: Text(l10n.editCustomDragTableTitle),
                subtitle: Text(
                  isEmpty
                      ? l10n.requiredFieldError
                      : '$count point${count == 1 ? '' : 's'}',
                  style: isEmpty ? TextStyle(color: cs.error) : null,
                ),
                trailing: const Icon(IconDef.chevronRight),
                dense: true,
                onTap: onNavigateToDragTable,
              );
            },
          ),
      ],
    );
  }
}
