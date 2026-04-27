import 'dart:async';
import 'dart:typed_data';
import 'package:ebalistyka/shared/widgets/dividers.dart';

import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/router.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
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

  late double _caliberRaw;
  double? _weightRaw;
  double? _lengthRaw;
  late DragType _dragType;
  late bool _useMultiBcG1;
  late bool _useMultiBcG7;
  double? _bcG1;
  double? _bcG7;
  List<({double vMps, double bc})>? _multiBcG1Table;
  List<({double vMps, double bc})>? _multiBcG7Table;
  List<({double mach, double cd})>? _customDragTable;
  List<({double tempC, double vMps})>? _powderSensTable;
  double? _mvRaw;
  late double _mvTempRaw;
  late double _zeroDistRaw;
  late double _zeroLookAngleRaw;
  late double _zeroTempRaw;
  late double _zeroAltRaw;
  late double _zeroPressureRaw;
  late double _zeroHumidityRaw;
  late bool _usePowderSensitivity;
  late double _powderSensRaw;
  late bool _zeroUseDiffPowderTemp;
  late double _zeroPowderTempRaw;
  late bool _zeroUseCoriolis;
  late double _zeroLatitudeRaw;
  late double _zeroAzimuthRaw;

  final _scrollController = ScrollController();
  final _powderSensKey = GlobalKey();
  final _coriolisKey = GlobalKey();

  late double _offsetXRaw;
  late Unit _offsetXUnit;
  late double _offsetYRaw;
  late Unit _offsetYUnit;

  @override
  String get initialName => widget.initial?.name ?? '';

  @override
  String get initialVendor => widget.initial?.vendor ?? '';

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _scheduleCaliberMismatchToast();
    _projectileNameCtrl = TextEditingController(text: a?.projectileName ?? '');
    final caliberRaw = a != null && a.caliberInch > 0
        ? a.caliber.in_(FC.projectileDiameter.rawUnit)
        : null;
    _caliberRaw =
        caliberRaw ??
        Distance.inch(
          widget.caliberInch ?? FC.projectileDiameter.minRaw,
        ).in_(FC.projectileDiameter.rawUnit);
    _weightRaw = (a != null && a.weightGrain > 0)
        ? a.weight.in_(FC.projectileWeight.rawUnit)
        : null;
    _lengthRaw = (a != null && a.lengthInch > 0)
        ? a.length.in_(FC.projectileLength.rawUnit)
        : null;
    _dragType = a?.dragType ?? DragType.g1;
    _useMultiBcG1 = a?.useMultiBcG1 ?? false;
    _useMultiBcG7 = a?.useMultiBcG7 ?? false;
    _bcG1 = (a != null && a.bcG1 > 0) ? a.bcG1 : null;
    _bcG7 = (a != null && a.bcG7 > 0) ? a.bcG7 : null;
    _multiBcG1Table = _decodeTable(a?.multiBcTableG1VMps, a?.multiBcTableG1Bc);
    _multiBcG7Table = _decodeTable(a?.multiBcTableG7VMps, a?.multiBcTableG7Bc);
    _customDragTable = _decodeCustomTable(
      a?.customDragTableMach,
      a?.customDragTableCd,
    );
    _powderSensTable = _decodePowderSensTable(
      a?.powderSensitivityTC,
      a?.powderSensitivityVMps,
    );
    _mvRaw = a?.mv?.in_(FC.muzzleVelocity.rawUnit);
    _mvTempRaw = a?.mvTemperature.in_(FC.temperature.rawUnit) ?? 15.0;
    _zeroDistRaw = a?.zeroDistance.in_(FC.zeroDistance.rawUnit) ?? 100.0;
    _zeroLookAngleRaw = a?.zeroLookAngle.in_(FC.lookAngle.rawUnit) ?? 0.0;
    _zeroTempRaw = a?.zeroTemperature.in_(FC.temperature.rawUnit) ?? 15.0;
    _zeroAltRaw = a?.zeroAltitude.in_(FC.altitude.rawUnit) ?? 0.0;
    _zeroPressureRaw = a?.zeroPressure.in_(FC.pressure.rawUnit) ?? 1013;
    _zeroHumidityRaw = a?.zeroHumidityFrac ?? 0.0;
    _usePowderSensitivity = a?.usePowderSensitivity ?? false;
    _powderSensRaw = a?.powderSensitivityFrac ?? 0.0;
    _zeroUseDiffPowderTemp = a?.zeroUseDiffPowderTemperature ?? false;
    _zeroPowderTempRaw = a?.zeroPowderTemp.in_(FC.temperature.rawUnit) ?? 15.0;
    _zeroUseCoriolis = a?.zeroUseCoriolis ?? false;
    _zeroLatitudeRaw = a?.zeroLatitudeDeg ?? 0.0;
    _zeroAzimuthRaw = a?.zeroAzimuthDeg ?? 0.0;

    _offsetYUnit = a?.zeroOffsetYUnitValue ?? Unit.mil;
    _offsetYRaw = a == null
        ? Angular.mil(0.1).in_(FC.adjustment.rawUnit)
        : Angular(a.zeroOffsetY, _offsetYUnit).in_(FC.adjustment.rawUnit);

    _offsetXUnit = a?.zeroOffsetXUnitValue ?? Unit.mil;
    _offsetXRaw = a == null
        ? Angular.mil(0.1).in_(FC.adjustment.rawUnit)
        : Angular(a.zeroOffsetX, _offsetXUnit).in_(FC.adjustment.rawUnit);
  }

  @override
  void dispose() {
    _projectileNameCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static List<({double vMps, double bc})>? _decodeTable(
    Float64List? vMps,
    Float64List? bcs,
  ) {
    if (vMps == null || bcs == null || vMps.isEmpty) return null;
    return List.generate(vMps.length, (i) => (vMps: vMps[i], bc: bcs[i]));
  }

  static List<({double mach, double cd})>? _decodeCustomTable(
    Float64List? mach,
    Float64List? cd,
  ) {
    if (mach == null || cd == null || mach.isEmpty) return null;
    return List.generate(mach.length, (i) => (mach: mach[i], cd: cd[i]));
  }

  static List<({double tempC, double vMps})>? _decodePowderSensTable(
    Float64List? tempC,
    Float64List? vMps,
  ) {
    if (tempC == null || vMps == null || tempC.isEmpty) return null;
    return List.generate(tempC.length, (i) => (tempC: tempC[i], vMps: vMps[i]));
  }

  void _scheduleCaliberMismatchToast() {
    final weaponCaliber = widget.caliberInch;
    final ammoCaliber = widget.initial?.caliberInch;
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
            onPressed: () => setState(
              () => _caliberRaw = Distance.inch(
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

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid {
    if (!isNameValid) return false;
    if (_caliberRaw <= 0) return false;
    if ((_weightRaw ?? 0) <= 0) return false;
    if ((_lengthRaw ?? 0) <= 0) return false;
    if ((_mvRaw ?? 0) <= 0) return false;
    if (_dragType == DragType.g1) {
      if (_useMultiBcG1) {
        if (_multiBcG1Table == null || _multiBcG1Table!.isEmpty) return false;
      } else if ((_bcG1 ?? 0) <= 0) {
        return false;
      }
    }
    if (_dragType == DragType.g7) {
      if (_useMultiBcG7) {
        if (_multiBcG7Table == null || _multiBcG7Table!.isEmpty) return false;
      } else if ((_bcG7 ?? 0) <= 0) {
        return false;
      }
    }
    if (_dragType == DragType.custom) {
      if (_customDragTable == null || _customDragTable!.isEmpty) return false;
    }
    return true;
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Ammo _buildAmmo() {
    final ammo = widget.initial ?? Ammo();
    ammo.name = nameCtrl.text.trim();
    ammo.vendor = vendorCtrl.text.trim().isEmpty
        ? null
        : vendorCtrl.text.trim();
    ammo.projectileName = _projectileNameCtrl.text.trim().isEmpty
        ? null
        : _projectileNameCtrl.text.trim();
    ammo.caliber = Distance(_caliberRaw, FC.projectileDiameter.rawUnit);
    ammo.weightGrain = _weightRaw != null
        ? Weight(_weightRaw!, FC.projectileWeight.rawUnit).in_(Unit.grain)
        : -1.0;
    ammo.lengthInch = _lengthRaw != null
        ? Distance(_lengthRaw!, FC.projectileLength.rawUnit).in_(Unit.inch)
        : -1.0;
    ammo.dragType = _dragType;
    ammo.useMultiBcG1 = _useMultiBcG1;
    ammo.useMultiBcG7 = _useMultiBcG7;
    ammo.bcG1 = _bcG1 ?? -1.0;
    ammo.bcG7 = _bcG7 ?? -1.0;
    final g1 = _multiBcG1Table;
    if (g1 != null && g1.isNotEmpty) {
      ammo.multiBcTableG1VMps = Float64List.fromList(
        g1.map((r) => r.vMps).toList(),
      );
      ammo.multiBcTableG1Bc = Float64List.fromList(
        g1.map((r) => r.bc).toList(),
      );
    } else {
      ammo.multiBcTableG1VMps = null;
      ammo.multiBcTableG1Bc = null;
    }
    final g7 = _multiBcG7Table;
    if (g7 != null && g7.isNotEmpty) {
      ammo.multiBcTableG7VMps = Float64List.fromList(
        g7.map((r) => r.vMps).toList(),
      );
      ammo.multiBcTableG7Bc = Float64List.fromList(
        g7.map((r) => r.bc).toList(),
      );
    } else {
      ammo.multiBcTableG7VMps = null;
      ammo.multiBcTableG7Bc = null;
    }
    final custom = _customDragTable;
    if (custom != null && custom.isNotEmpty) {
      ammo.customDragTableMach = Float64List.fromList(
        custom.map((r) => r.mach).toList(),
      );
      ammo.customDragTableCd = Float64List.fromList(
        custom.map((r) => r.cd).toList(),
      );
    } else {
      ammo.customDragTableMach = null;
      ammo.customDragTableCd = null;
    }
    ammo.muzzleVelocityMps = _mvRaw != null
        ? Velocity(_mvRaw!, FC.muzzleVelocity.rawUnit).in_(Unit.mps)
        : -1.0;
    ammo.mvTemperature = Temperature(_mvTempRaw, FC.temperature.rawUnit);

    ammo.zeroDistance = Distance(_zeroDistRaw, FC.zeroDistance.rawUnit);
    ammo.zeroLookAngle = Angular(_zeroLookAngleRaw, FC.lookAngle.rawUnit);
    ammo.zeroTemperature = Temperature(_zeroTempRaw, FC.temperature.rawUnit);
    ammo.zeroPressure = Pressure(_zeroPressureRaw, FC.pressure.rawUnit);
    ammo.zeroHumidityFrac = _zeroHumidityRaw;
    ammo.zeroAltitude = Distance(_zeroAltRaw, FC.altitude.rawUnit);
    ammo.usePowderSensitivity = _usePowderSensitivity;
    ammo.powderSensitivity = Ratio.fraction(_powderSensRaw);
    final psTable = _powderSensTable;
    if (psTable != null && psTable.isNotEmpty) {
      ammo.powderSensitivityTC = Float64List.fromList(
        psTable.map((r) => r.tempC).toList(),
      );
      ammo.powderSensitivityVMps = Float64List.fromList(
        psTable.map((r) => r.vMps).toList(),
      );
    } else {
      ammo.powderSensitivityTC = null;
      ammo.powderSensitivityVMps = null;
    }
    ammo.zeroUseDiffPowderTemperature = _zeroUseDiffPowderTemp;
    ammo.zeroPowderTemp = Temperature(
      _zeroPowderTempRaw,
      FC.temperature.rawUnit,
    );
    ammo.zeroUseCoriolis = _zeroUseCoriolis;
    ammo.zeroLatitudeDeg = _zeroLatitudeRaw;
    ammo.zeroAzimuthDeg = _zeroAzimuthRaw;

    ammo.zeroOffsetYUnitValue = _offsetYUnit;
    ammo.zeroOffsetY = Angular(
      _offsetYRaw,
      FC.adjustment.rawUnit,
    ).in_(_offsetYUnit);
    ammo.zeroOffsetXUnitValue = _offsetXUnit;
    ammo.zeroOffsetX = Angular(
      _offsetXRaw,
      FC.adjustment.rawUnit,
    ).in_(_offsetXUnit);
    return ammo;
  }

  void _onSave() {
    if (!_isValid) return;
    commitSave(_buildAmmo);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _navigateToDragTableEditor() async {
    final result = await context.push<List<({double mach, double cd})>>(
      Routes.ammoEditDragTable,
      extra: _customDragTable,
    );
    if (!mounted || result == null) return;
    setState(() => _customDragTable = result.isEmpty ? null : result);
  }

  Future<void> _navigateToPowderSensTable() async {
    final mvMps = _mvRaw == null
        ? null
        : Velocity(_mvRaw!, FC.muzzleVelocity.rawUnit).in_(Unit.mps);
    final tempC = Temperature(
      _mvTempRaw,
      FC.temperature.rawUnit,
    ).in_(Unit.celsius);
    final result = await context.push<PowderSensTableResult>(
      Routes.ammoEditPowderSensTable,
      extra: (table: _powderSensTable, mvMps: mvMps, tempC: tempC),
    );
    if (!mounted || result == null) return;
    setState(() {
      _powderSensTable = result.table.isEmpty ? null : result.table;
      final sens = result.sensitivity;
      // Only update coefficient when table has valid pairs — empty table
      // preserves the manually-entered coefficient.
      if (sens != null && result.table.isNotEmpty) {
        _powderSensRaw = sens.clamp(0.0, double.infinity);
      }
    });
  }

  Future<void> _navigateToMultiBcEditor(DragType dt) async {
    final table = dt == DragType.g1 ? _multiBcG1Table : _multiBcG7Table;
    final bc = dt == DragType.g1 ? _bcG1 : _bcG7;
    final route = dt == DragType.g1
        ? Routes.ammoEditMultiBcG1
        : Routes.ammoEditMultiBcG7;

    final mvMps = _mvRaw == null
        ? null
        : Velocity(_mvRaw!, FC.muzzleVelocity.rawUnit).in_(Unit.mps);

    final result = await context.push<List<({double vMps, double bc})>>(
      route,
      extra: (table: table, mvMps: mvMps, bc: bc),
    );

    if (!mounted || result == null) return;
    setState(() {
      if (dt == DragType.g1) {
        _multiBcG1Table = result.isEmpty ? null : result;
      } else {
        _multiBcG7Table = result.isEmpty ? null : result;
      }
    });
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
        onChanged: (v) => setState(() => onMultiChanged(v)),
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
          onChanged: (v) => setState(() => onBcChanged(v)),
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

  Widget _buildDragModel() {
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
              selected: {_dragType},
              onSelectionChanged: (s) => setState(() => _dragType = s.first),
            ),
          ),
        ),
        if (_dragType == DragType.g1)
          ..._buildBcSection(
            dt: DragType.g1,
            useMulti: _useMultiBcG1,
            multiTable: _multiBcG1Table,
            bcRaw: _bcG1,
            onMultiChanged: (v) => _useMultiBcG1 = v,
            onBcChanged: (v) => _bcG1 = v,
          ),
        if (_dragType == DragType.g7)
          ..._buildBcSection(
            dt: DragType.g7,
            useMulti: _useMultiBcG7,
            multiTable: _multiBcG7Table,
            bcRaw: _bcG7,
            onMultiChanged: (v) => _useMultiBcG7 = v,
            onBcChanged: (v) => _bcG7 = v,
          ),
        if (_dragType == DragType.custom)
          Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final isEmpty =
                  _customDragTable == null || _customDragTable!.isEmpty;
              final count = _customDragTable?.length ?? 0;
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
    final units = ref.watch(unitSettingsProvider);
    final formatter = ref.watch(unitFormatterProvider);

    return BaseScreen(
      title: wizardTitle('New Ammo'),
      isSubscreen: true,
      showBack: false,
      bottomBar: WizardActionBar(
        onDiscard: onDiscard,
        onSave: _isValid ? _onSave : null,
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
              Distance(_caliberRaw, FC.projectileDiameter.rawUnit),
            ),
            icon: IconDef.caliber,
          ),
          NullableUnitValueFieldTile(
            title: 'Weight',
            rawValue: _weightRaw,
            constraints: FC.projectileWeight,
            displayUnit: units.weightUnit,
            icon: IconDef.weigth,
            isRequired: true,
            onChanged: (v) => setState(() => _weightRaw = v),
          ),
          NullableUnitValueFieldTile(
            title: 'Length',
            rawValue: _lengthRaw,
            constraints: FC.projectileLength,
            displayUnit: units.lengthUnit,
            icon: IconDef.length,
            isRequired: true,
            onChanged: (v) => setState(() => _lengthRaw = v),
          ),
          _buildDragModel(),

          // ── Cartridge ──────────────────────────────────────────────
          const TileDivider(),
          const ListSectionTile('Cartridge'),
          NullableUnitValueFieldTile(
            title: 'Muzzle velocity',
            subtitle: "Measured / Vendor provided",
            rawValue: _mvRaw,
            constraints: FC.muzzleVelocity,
            displayUnit: units.velocityUnit,
            icon: IconDef.velocity,
            isRequired: true,
            onChanged: (v) => setState(() => _mvRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Muzzle velocity temperature',
            subtitle: 'Powder temperature at the time of measurement',
            rawValue: _mvTempRaw,
            constraints: FC.temperature,
            displayUnit: units.temperatureUnit,
            icon: IconDef.temperature,
            onChanged: (v) => setState(() => _mvTempRaw = v),
          ),
          SwitchListTile(
            title: const Text('Powder temperature sensitivity'),
            secondary: const Icon(IconDef.powderTemperature),
            value: _usePowderSensitivity,
            onChanged: (v) {
              setState(() => _usePowderSensitivity = v);
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
            rawValue: _zeroDistRaw,
            constraints: FC.zeroDistance,
            displayUnit: units.distanceUnit,
            icon: IconDef.range,
            onChanged: (v) => setState(() => _zeroDistRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Look angle',
            subtitle: 'Zeroing look angle',
            rawValue: _zeroLookAngleRaw,
            constraints: FC.lookAngle,
            displayUnit: units.angularUnit,
            icon: IconDef.angle,
            onChanged: (v) => setState(() => _zeroLookAngleRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Temperature',
            subtitle: 'Zeroing atmospheric temperature',
            rawValue: _zeroTempRaw,
            constraints: FC.temperature,
            displayUnit: units.temperatureUnit,
            icon: IconDef.temperature,
            onChanged: (v) => setState(() => _zeroTempRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Pressure',
            subtitle: 'Zeroing atmospheric pressure',
            rawValue: _zeroPressureRaw,
            constraints: FC.pressure,
            displayUnit: units.pressureUnit,
            icon: IconDef.pressure,
            onChanged: (v) => setState(() => _zeroPressureRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Humidity',
            subtitle: 'Zeroing atmospheric humidity',
            rawValue: _zeroHumidityRaw,
            constraints: FC.humidity,
            displayUnit: Unit.percent,
            icon: IconDef.humidity,
            onChanged: (v) => setState(() => _zeroHumidityRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Altitude',
            subtitle: 'Zeroing altitude',
            rawValue: _zeroAltRaw,
            constraints: FC.altitude,
            displayUnit: units.distanceUnit,
            icon: IconDef.altitude,
            onChanged: (v) => setState(() => _zeroAltRaw = v),
          ),

          // ── Powder sensitivity ──────────────────────────────────────────────
          if (_usePowderSensitivity) ...[
            const TileDivider(),
            PowderSensSection(
              key: _powderSensKey,
              showToggle: false,
              usePowderSensitivity: _usePowderSensitivity,
              useDiffPowderTemp: _zeroUseDiffPowderTemp,
              temperatureUnit: units.temperatureUnit,
              powderTempRaw: _zeroPowderTempRaw,
              powderSensRaw: _powderSensRaw,
              mvValue: () {
                final ammo = _buildAmmo();
                if (!ammo.isReadyForCalculation) return null;
                return formatter.velocity(
                  ammo.toZeroAmmo().getVelocityForTemp(
                    ammo.toZeroAtmo().powderTemp,
                  ),
                );
              }(),
              sensitivityValue: formatter.powderSensitivity(
                Ratio.fraction(_powderSensRaw),
              ),
              onDiffTempToggled: (v) =>
                  setState(() => _zeroUseDiffPowderTemp = v),
              onPowderTempChanged: (v) =>
                  setState(() => _zeroPowderTempRaw = v),
              onPowderSensChanged: (v) => setState(() => _powderSensRaw = v),
            ),
            ListTile(
              leading: const Icon(IconDef.powderTemperature),
              title: const Text('Calculate from measurements'),
              subtitle: Text(
                _powderSensTable != null
                    ? '${_powderSensTable!.length} measurement${_powderSensTable!.length == 1 ? '' : 's'}'
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
            yRaw: _offsetYRaw,
            xRaw: _offsetXRaw,
            yUnits: _offsetYUnit,
            xUnits: _offsetXUnit,
            onYChanged: (v) => setState(() => _offsetYRaw = v),
            onXChanged: (v) => setState(() => _offsetXRaw = v),
            onYUnitChanged: (u) => setState(() => _offsetYUnit = u),
            onXUnitChanged: (u) => setState(() => _offsetXUnit = u),
          ),

          // ── Zeroing coriolis ────────────────────────────────────────
          const TileDivider(),
          CoriolisSection(
            key: _coriolisKey,
            useCoriolis: _zeroUseCoriolis,
            latitudeRaw: _zeroLatitudeRaw,
            azimuthRaw: _zeroAzimuthRaw,
            angularUnit: Unit.degree,
            onCoriolisToggled: (v) {
              setState(() => _zeroUseCoriolis = v);
              if (v) _scrollTo(_coriolisKey);
            },
            onLatitudeChanged: (v) => setState(() => _zeroLatitudeRaw = v),
            onAzimuthChanged: (v) => setState(() => _zeroAzimuthRaw = v),
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
