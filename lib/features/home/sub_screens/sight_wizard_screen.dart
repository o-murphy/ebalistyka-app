import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:bclibc_ffi/unit.dart' show Angular, Distance, Unit;
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
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
  // ── Draft state (all raw values in FC rawUnits) ───────────────────────────
  // sightHeight / horizontalOffset: Unit.millimeter (FC.sightHeight)
  late double _sightHeightRaw;
  late double _horizontalOffsetRaw;

  // focalPlane enum
  late FocalPlane _focalPlane;

  // clicks: raw in FC.adjustment.rawUnit (mil), display unit stored separately
  late double _vClickRaw;
  late Unit _vClickUnit;
  late double _hClickRaw;
  late Unit _hClickUnit;

  // magnification: dimensionless scalar (FC.magnification, Unit.scalar)
  late double _minMagRaw;
  late double _maxMagRaw;

  late String? _reticleImage;

  @override
  String get initialName => widget.initial?.name ?? '';

  @override
  String get initialVendor => widget.initial?.vendor ?? '';

  @override
  void initState() {
    super.initState();
    final s = widget.initial;

    _sightHeightRaw = s?.sightHeight.in_(FC.sightHeight.rawUnit) ?? 0.0;
    _horizontalOffsetRaw =
        s?.horizontalOffset.in_(FC.sightHeight.rawUnit) ?? 0.0;

    _focalPlane = s?.focalPlane ?? FocalPlane.ffp;

    _vClickUnit = s?.verticalClickUnitValue ?? Unit.mil;
    _vClickRaw = s != null
        ? Angular(s.verticalClick, _vClickUnit).in_(FC.adjustment.rawUnit)
        : Angular.mil(0.1).in_(FC.adjustment.rawUnit);

    _hClickUnit = s?.horizontalClickUnitValue ?? Unit.mil;
    _hClickRaw = s != null
        ? Angular(s.horizontalClick, _hClickUnit).in_(FC.adjustment.rawUnit)
        : Angular.mil(0.1).in_(FC.adjustment.rawUnit);

    final storedMin = s?.minMagnification ?? 0.0;
    final storedMax = s?.maxMagnification ?? 0.0;
    _minMagRaw = storedMin > 0 ? storedMin : 1.0;
    _maxMagRaw = storedMax > 0 ? storedMax : 1.0;

    _reticleImage = s?.reticleImage;
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid {
    if (!isNameValid) return false;
    if (_minMagRaw <= 0) return false;
    if (_maxMagRaw <= 0) return false;
    if (_vClickRaw <= 0) return false;
    if (_hClickRaw <= 0) return false;
    return true;
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Sight _buildSight() {
    final sight = widget.initial ?? Sight();
    sight.name = nameCtrl.text.trim();
    sight.vendor = vendorCtrl.text.trim().isEmpty
        ? null
        : vendorCtrl.text.trim();
    sight.sightHeight = Distance(_sightHeightRaw, FC.sightHeight.rawUnit);
    sight.horizontalOffset = Distance(
      _horizontalOffsetRaw,
      FC.sightHeight.rawUnit,
    );
    sight.focalPlane = _focalPlane;
    sight.verticalClickUnitValue = _vClickUnit;
    sight.verticalClick = Angular(
      _vClickRaw,
      FC.adjustment.rawUnit,
    ).in_(_vClickUnit);
    sight.horizontalClickUnitValue = _hClickUnit;
    sight.horizontalClick = Angular(
      _hClickRaw,
      FC.adjustment.rawUnit,
    ).in_(_hClickUnit);
    sight.minMagnification = _minMagRaw;
    sight.maxMagnification = _maxMagRaw;
    sight.reticleImage = _reticleImage;
    return sight;
  }

  void _onSave() {
    if (!_isValid) return;
    commitSave(_buildSight);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSettingsProvider);

    return BaseScreen(
      title: wizardTitle('New Sight'),
      isSubscreen: true,
      showBack: false,
      bottomBar: WizardActionBar(
        onDiscard: onDiscard,
        onSave: _isValid ? _onSave : null,
      ),
      body: ListView(
        children: [
          _SightPlaceholder(),
          // ── Name ──────────────────────────────────────────────────
          WizardNameField(
            controller: nameCtrl,
            label: 'Sight name',
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
          // ── Mounting ──────────────────────────────────────────────
          const TileDivider(),
          const ListSectionTile('Mounting'),
          UnitValueFieldTile(
            title: 'Sight height',
            rawValue: _sightHeightRaw,
            constraints: FC.sightHeight,
            displayUnit: units.sightHeightUnit,
            icon: IconDef.height,
            onChanged: (v) => setState(() => _sightHeightRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Horizontal offset',
            rawValue: _horizontalOffsetRaw,
            constraints: FC.sightHeight,
            displayUnit: units.sightHeightUnit,
            icon: IconDef.horizontalOffset,
            onChanged: (v) => setState(() => _horizontalOffsetRaw = v),
          ),
          // ── Reticle ────────────────────────────────────────────────
          const TileDivider(),
          const ListSectionTile('Reticle'),
          ListTile(
            leading: const Icon(IconDef.sight),
            title: const Text('Reticle pattern'),
            subtitle: Text(_reticleImage ?? 'default'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final route = widget.initial != null
                  ? Routes.sightEditReticlePicker
                  : Routes.sightReticlePicker;
              final result = await context.push<String?>(
                route,
                extra: _reticleImage,
              );
              if (result != null && mounted) {
                setState(() => _reticleImage = result);
              }
            },
            dense: true,
          ),
          const TileDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<FocalPlane>(
              segments: const [
                ButtonSegment(
                  value: FocalPlane.ffp,
                  label: Text('FFP'),
                  icon: Icon(IconDef.ffp),
                ),
                ButtonSegment(
                  value: FocalPlane.sfp,
                  label: Text('SFP'),
                  icon: Icon(IconDef.sfp),
                ),
                ButtonSegment(
                  value: FocalPlane.lwir,
                  label: Text('LWIR'),
                  icon: Icon(IconDef.lwir),
                ),
              ],
              selected: {_focalPlane},
              onSelectionChanged: (s) => setState(() => _focalPlane = s.first),
            ),
          ),
          UnitValueFieldTile(
            title: 'Min magnification',
            rawValue: _minMagRaw,
            constraints: FC.magnification,
            displayUnit: Unit.scalar,
            symbol: 'x',
            icon: IconDef.magnificationMin,
            onChanged: (v) => setState(() => _minMagRaw = v),
          ),
          UnitValueFieldTile(
            title: 'Max magnification',
            rawValue: _maxMagRaw,
            constraints: FC.magnification,
            displayUnit: Unit.scalar,
            symbol: 'x',
            icon: IconDef.magnificationMax,
            onChanged: (v) => setState(() => _maxMagRaw = v),
          ),
          // ── Clicks ────────────────────────────────────────────────
          const TileDivider(),
          const ListSectionTile('Clicks'),
          offsetsTile(
            context: context,
            yLabel: 'Vertical click',
            xLabel: 'Horizontal click',
            unitLabel: 'Click unit',
            yRaw: _vClickRaw,
            xRaw: _hClickRaw,
            yUnits: _vClickUnit,
            xUnits: _hClickUnit,
            onYChanged: (v) => setState(() => _vClickRaw = v),
            onXChanged: (v) => setState(() => _hClickRaw = v),
            onYUnitChanged: (u) => setState(() => _vClickUnit = u),
            onXUnitChanged: (u) => setState(() => _hClickUnit = u),
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
                  IconDef.sight,
                  size: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sight image',
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
