import 'dart:async';
import 'package:ebalistyka/features/home/sub_screens/ammo_wizard_notifier.dart';
import 'package:ebalistyka/shared/widgets/dividers.dart';

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
  const AmmoWizardScreen({this.initial, this.caliberInch, super.key});

  /// Pre-fill the form with an existing ammo (edit mode).
  /// null = new empty ammo.
  final Ammo? initial;

  /// Caliber set by the profile's weapon (create mode only).
  /// In edit mode the caliber is taken from [initial].
  /// Displayed readonly — never entered manually.
  final double? caliberInch;

  @override
  ConsumerState<AmmoWizardScreen> createState() => _AmmoWizardScreenState();
}

class _AmmoWizardScreenState extends ConsumerState<AmmoWizardScreen>
    with WizardFormMixin<AmmoWizardScreen> {
  late final TextEditingController _projectileNameCtrl;

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
    ref.read(_provider.notifier).updateName(nameCtrl.text);
    super.onNameChanged();
  }

  @override
  void initState() {
    super.initState();
    _projectileNameCtrl = TextEditingController(
      text: widget.initial?.projectileName ?? '',
    );
    _scheduleCaliberMismatchToast();
  }

  @override
  void dispose() {
    _projectileNameCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCaliberMismatchToast() {
    final weaponCaliber = widget.caliberInch;
    final ammoCaliber = widget.initial?.caliber.in_(Unit.inch);
    if (weaponCaliber == null || ammoCaliber == null) return;
    if ((weaponCaliber - ammoCaliber).abs() < 0.0001) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ammo caliber differs from weapon caliber'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Update',
            onPressed: () => ref
                .read(_provider.notifier)
                .updateCaliberRaw(
                  Distance.inch(
                    weaponCaliber,
                  ).in_(FC.projectileDiameter.rawUnit),
                ),
          ),
        ),
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
    notifier.updateVendor(vendorCtrl.text);
    notifier.updateProjectileName(_projectileNameCtrl.text);
    commitSave(ref.read(_provider).buildAmmo);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _navigateToDragTableEditor() async {
    final result = await context.push<List<({double mach, double cd})>>(
      Routes.ammoEditDragTable,
      extra: ref.read(_provider).customDragTable,
    );
    if (!mounted || result == null) return;
    ref
        .read(_provider.notifier)
        .updateCustomDragTable(result.isEmpty ? null : result);
  }

  Future<void> _navigateToPowderSensTable() async {
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

  // ── Build ─────────────────────────────────────────────────────────────────

  List<Widget> _buildBcSection({
    required DragType dt,
    required bool useMulti,
    required List<({double vMps, double bc})>? multiTable,
    required double? bcRaw,
    required ValueChanged<bool> onMultiChanged,
    required ValueChanged<double?> onBcChanged,
  }) {
    final dtName = dt.name.toUpperCase();
    return [
      SwitchListTile(
        title: Text('Enable $dtName Multi-BC'),
        subtitle: Text(
          useMulti ? '$dtName Multi-BC mode' : '$dtName Single BC mode',
        ),
        value: useMulti,
        onChanged: onMultiChanged,
        dense: true,
      ),
      if (!useMulti)
        NullableUnitValueFieldTile(
          title: 'Ballistic coefficient $dtName',
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
            final theme = Theme.of(context);
            final isEmpty = multiTable == null || multiTable.isEmpty;
            final count = multiTable?.length ?? 0;
            return ListTile(
              tileColor: isEmpty ? theme.colorScheme.tertiaryContainer : null,
              leading: Icon(
                IconDef.dragModel,
                color: isEmpty ? theme.colorScheme.tertiary : null,
              ),
              title: Text('Edit $dtName Multi-BC table'),
              subtitle: Text(
                isEmpty
                    ? 'Required'
                    : '$count breakpoint${count == 1 ? '' : 's'}',
                style: isEmpty
                    ? TextStyle(color: theme.colorScheme.error)
                    : null,
              ),
              trailing: const Icon(IconDef.chevronRight),
              dense: true,
              onTap: () => _navigateToMultiBcEditor(dt),
            );
          },
        ),
    ];
  }

  Widget _buildDragModel(AmmoWizardState st) {
    final notifier = ref.read(_provider.notifier);
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
              onSelectionChanged: (s) => notifier.updateDragType(s.first),
            ),
          ),
        ),
        if (st.dragType == DragType.g1)
          ..._buildBcSection(
            dt: DragType.g1,
            useMulti: st.useMultiBcG1,
            multiTable: st.multiBcG1Table,
            bcRaw: st.bcG1,
            onMultiChanged: notifier.updateUseMultiBcG1,
            onBcChanged: notifier.updateBcG1,
          ),
        if (st.dragType == DragType.g7)
          ..._buildBcSection(
            dt: DragType.g7,
            useMulti: st.useMultiBcG7,
            multiTable: st.multiBcG7Table,
            bcRaw: st.bcG7,
            onMultiChanged: notifier.updateUseMultiBcG7,
            onBcChanged: notifier.updateBcG7,
          ),
        if (st.dragType == DragType.custom)
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isEmpty =
                  st.customDragTable == null || st.customDragTable!.isEmpty;
              final count = st.customDragTable?.length ?? 0;
              return ListTile(
                tileColor: isEmpty ? theme.colorScheme.tertiaryContainer : null,
                leading: Icon(
                  IconDef.dragModel,
                  color: isEmpty ? theme.colorScheme.tertiary : null,
                ),
                title: const Text('Edit Custom Drag Table'),
                subtitle: Text(
                  isEmpty ? 'Required' : '$count point${count == 1 ? '' : 's'}',
                  style: isEmpty
                      ? TextStyle(color: theme.colorScheme.error)
                      : null,
                ),
                trailing: const Icon(IconDef.chevronRight),
                dense: true,
                onTap: _navigateToDragTableEditor,
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(_provider);
    final units = ref.watch(unitSettingsProvider);
    final formatter = ref.watch(unitFormatterProvider);
    final notifier = ref.read(_provider.notifier);

    return BaseScreen(
      title: wizardTitle('New Ammo'),
      isSubscreen: true,
      showBack: false,
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
            controller: nameCtrl,
            label: 'Ammo name',
            onChanged: onNameChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: vendorCtrl,
              decoration: const InputDecoration(labelText: 'Vendor'),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          // ── Projectile ──────────────────────────────────────────────
          const TileDivider(),
          const ListSectionTile('Projectile'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _projectileNameCtrl,
              decoration: const InputDecoration(labelText: 'Projectile name'),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          InfoListTile(
            label: 'Caliber',
            value: formatter.diameter(
              Distance(st.caliberRaw, FC.projectileDiameter.rawUnit),
            ),
            icon: IconDef.caliber,
          ),
          NullableUnitValueFieldTile(
            title: 'Weight',
            rawValue: st.weightRaw,
            constraints: FC.projectileWeight,
            displayUnit: units.weightUnit,
            icon: IconDef.weigth,
            isRequired: true,
            onChanged: notifier.updateWeightRaw,
          ),
          NullableUnitValueFieldTile(
            title: 'Length',
            rawValue: st.lengthRaw,
            constraints: FC.projectileLength,
            displayUnit: units.lengthUnit,
            icon: IconDef.length,
            isRequired: true,
            onChanged: notifier.updateLengthRaw,
          ),
          _buildDragModel(st),

          // ── Cartridge ──────────────────────────────────────────────
          const TileDivider(),
          const ListSectionTile('Cartridge'),
          NullableUnitValueFieldTile(
            title: 'Muzzle velocity',
            subtitle: "Measured / Vendor provided",
            rawValue: st.mvRaw,
            constraints: FC.muzzleVelocity,
            displayUnit: units.velocityUnit,
            icon: IconDef.velocity,
            isRequired: true,
            onChanged: notifier.updateMvRaw,
          ),
          UnitValueFieldTile(
            title: 'Muzzle velocity temperature',
            subtitle: 'Powder temperature at the time of measurement',
            rawValue: st.mvTempRaw,
            constraints: FC.temperature,
            displayUnit: units.temperatureUnit,
            icon: IconDef.temperature,
            onChanged: notifier.updateMvTempRaw,
          ),
          SwitchListTile(
            title: const Text('Powder temperature sensitivity'),
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
          const ListSectionTile('Zeroing'),
          UnitValueFieldTile(
            title: 'Distance',
            subtitle: 'Zeroing distance',
            rawValue: st.zeroDistRaw,
            constraints: FC.zeroDistance,
            displayUnit: units.distanceUnit,
            icon: IconDef.range,
            onChanged: notifier.updateZeroDistRaw,
          ),
          UnitValueFieldTile(
            title: 'Look angle',
            subtitle: 'Zeroing look angle',
            rawValue: st.zeroLookAngleRaw,
            constraints: FC.lookAngle,
            displayUnit: units.angularUnit,
            icon: IconDef.angle,
            onChanged: notifier.updateZeroLookAngleRaw,
          ),
          UnitValueFieldTile(
            title: 'Temperature',
            subtitle: 'Zeroing atmospheric temperature',
            rawValue: st.zeroTempRaw,
            constraints: FC.temperature,
            displayUnit: units.temperatureUnit,
            icon: IconDef.temperature,
            onChanged: notifier.updateZeroTempRaw,
          ),
          UnitValueFieldTile(
            title: 'Pressure',
            subtitle: 'Zeroing atmospheric pressure',
            rawValue: st.zeroPressureRaw,
            constraints: FC.pressure,
            displayUnit: units.pressureUnit,
            icon: IconDef.pressure,
            onChanged: notifier.updateZeroPressureRaw,
          ),
          UnitValueFieldTile(
            title: 'Humidity',
            subtitle: 'Zeroing atmospheric humidity',
            rawValue: st.zeroHumidityRaw,
            constraints: FC.humidity,
            displayUnit: Unit.percent,
            icon: IconDef.humidity,
            onChanged: notifier.updateZeroHumidityRaw,
          ),
          UnitValueFieldTile(
            title: 'Altitude',
            subtitle: 'Zeroing altitude',
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
              title: const Text('Calculate from measurements'),
              subtitle: Text(
                st.powderSensTable != null
                    ? '${st.powderSensTable!.length} measurement${st.powderSensTable!.length == 1 ? '' : 's'}'
                    : 'Tap to add T→V measurements',
              ),
              trailing: const Icon(IconDef.chevronRight),
              dense: true,
              onTap: _navigateToPowderSensTable,
            ),
          ],

          // ── Zeroing offset ────────────────────────────────────────
          offsetsTile(
            context: context,
            yLabel: 'Vertical offset',
            xLabel: 'Horizontal offset',
            unitLabel: 'Click unit',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 160,
        child: Card(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconDef.ammo,
                  size: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ammo image',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
