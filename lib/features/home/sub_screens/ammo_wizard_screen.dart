import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/coriolis_section.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/powder_sens_section.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
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

class _AmmoWizardScreenState extends ConsumerState<AmmoWizardScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _projectileNameCtrl;

  String? _nameError;
  bool _nameTouched = false;

  late double _caliberRaw;
  double? _weightRaw;
  double? _lengthRaw;
  late DragType _dragType;
  late bool _useMultiBcG1;
  late bool _useMultiBcG7;
  double? _bcG1;
  double? _bcG7;
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

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _scheduleCaliberMismatchToast();
    _nameCtrl = TextEditingController(text: a?.name ?? '');
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
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _projectileNameCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
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
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_caliberRaw <= 0) return false;
    if ((_weightRaw ?? 0) <= 0) return false;
    if ((_lengthRaw ?? 0) <= 0) return false;
    if ((_mvRaw ?? 0) <= 0) return false;
    // BC: relevant for the current drag type must be positive
    // (multi-BC mode bypasses single-BC field — allow save when table is set)
    if (_dragType == DragType.g1 && !_useMultiBcG1 && (_bcG1 ?? 0) <= 0)
      return false;
    if (_dragType == DragType.g7 && !_useMultiBcG7 && (_bcG7 ?? 0) <= 0)
      return false;
    return true;
  }

  void _validateName() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Name is required' : null;
    });
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Ammo _buildAmmo() {
    final ammo = widget.initial ?? Ammo();
    ammo.name = _nameCtrl.text.trim();
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
    ammo.zeroUseDiffPowderTemperature = _zeroUseDiffPowderTemp;
    ammo.zeroPowderTemp = Temperature(
      _zeroPowderTempRaw,
      FC.temperature.rawUnit,
    );
    ammo.zeroUseCoriolis = _zeroUseCoriolis;
    ammo.zeroLatitudeDeg = _zeroLatitudeRaw;
    ammo.zeroAzimuthDeg = _zeroAzimuthRaw;
    return ammo;
  }

  void _onSave() {
    _nameTouched = true;
    _validateName();
    if (!_isValid) return;
    context.pop(_buildAmmo());
  }

  void _onDiscard() => context.pop(null);

  // ── Build ─────────────────────────────────────────────────────────────────

  List<Widget> _buildBcSection({
    required DragType dt,
    required bool useMulti,
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
      // TODO: there should be a route to multi-bc edit screen (form)
      if (useMulti)
        ListTile(
          leading: Icon(IconDef.dragModel),
          title: Text('Edit $dtName Multi-BC table'),
          trailing: const Icon(IconDef.chevronRight),
          dense: true,
          onTap: () => showNotAvailableSnackBar(context, 'Multi-BC editor'),
        ),
    ];
  }

  Widget _buildDragModel() {
    final dtName = _dragType.name.toUpperCase();
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
            bcRaw: _bcG1,
            onMultiChanged: (v) => _useMultiBcG1 = v,
            onBcChanged: (v) => _bcG1 = v,
          ),
        if (_dragType == DragType.g7)
          ..._buildBcSection(
            dt: DragType.g7,
            useMulti: _useMultiBcG7,
            bcRaw: _bcG7,
            onMultiChanged: (v) => _useMultiBcG7 = v,
            onBcChanged: (v) => _bcG7 = v,
          ),
        if (_dragType == DragType.custom)
          // TODO: there should be a route to custom drag table edit/view screen (form)
          ListTile(
            leading: Icon(IconDef.dragModel),
            title: Text('Edit $dtName DragModel'),
            trailing: const Icon(IconDef.chevronRight),
            dense: true,
            onTap: () => showNotAvailableSnackBar(context, 'Drag Table editor'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSettingsProvider);
    final fmt = ref.watch(unitFormatterProvider);
    final title = _nameCtrl.text.trim().isEmpty
        ? 'New Ammo'
        : _nameCtrl.text.trim();

    return BaseScreen(
      title: title,
      isSubscreen: true,
      showBack: false,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                _AmmoPlaceholder(),
                // ── Name ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Ammo name',
                      errorText: _nameError,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_nameTouched) _validateName();
                      setState(() {}); // update title
                    },
                    onEditingComplete: _validateName,
                  ),
                ),
                // ── Projectile ──────────────────────────────────────────────
                const Divider(height: 1),
                const ListSectionTile('Projectile'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: TextField(
                    controller: _projectileNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Projectile name',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                InfoListTile(
                  label: 'Caliber',
                  value: _caliberRaw > 0
                      ? fmt.diameter(
                          Distance(_caliberRaw, FC.projectileDiameter.rawUnit),
                        )
                      : '—',
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
                const Divider(height: 1),
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
                const Divider(height: 1),
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
                // TODO: Zeroing atmo params

                // ── Powder sensitivity ──────────────────────────────────────────────
                if (_usePowderSensitivity) ...[
                  const Divider(height: 1),
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
                      return fmt.velocity(
                        ammo.toZeroAmmo().getVelocityForTemp(
                          ammo.toZeroAtmo().powderTemp,
                        ),
                      );
                    }(),
                    sensitivityValue: fmt.powderSensitivity(
                      Ratio.fraction(_powderSensRaw),
                    ),
                    onDiffTempToggled: (v) =>
                        setState(() => _zeroUseDiffPowderTemp = v),
                    onPowderTempChanged: (v) =>
                        setState(() => _zeroPowderTempRaw = v),
                    onPowderSensChanged: (v) =>
                        setState(() => _powderSensRaw = v),
                  ),
                ],

                // ── Zeroing coriolis ────────────────────────────────────────
                const Divider(height: 1),
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
                  onLatitudeChanged: (v) =>
                      setState(() => _zeroLatitudeRaw = v),
                  onAzimuthChanged: (v) => setState(() => _zeroAzimuthRaw = v),
                ),
              ],
            ),
          ),
          // ── Action bar ───────────────────────────────────────────────────
          _ActionBar(onDiscard: _onDiscard, onSave: _isValid ? _onSave : null),
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onDiscard, required this.onSave});

  final VoidCallback onDiscard;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          OutlinedButton(onPressed: onDiscard, child: const Text('Discard')),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(onPressed: onSave, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
