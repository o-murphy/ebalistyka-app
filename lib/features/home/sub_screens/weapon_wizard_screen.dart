import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:bclibc_ffi/unit.dart' show Distance;
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/consts.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/mixins/wizard_form_mixin.dart';
import 'package:ebalistyka/shared/widgets/weapon_svg_view.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:ebalistyka/shared/widgets/wizard_action_bar.dart';
import 'package:ebalistyka/shared/widgets/wizard_name_field.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeaponWizardScreen extends ConsumerStatefulWidget {
  const WeaponWizardScreen({this.initial, this.caliberEditable, super.key});

  /// Pre-fill the form with an existing weapon (edit mode).
  /// null = new empty weapon.
  final Weapon? initial;

  /// Whether the caliber diameter field is editable.
  /// Defaults to true when [initial] is null (manual create), false otherwise.
  final bool? caliberEditable;

  @override
  ConsumerState<WeaponWizardScreen> createState() => _WeaponWizardScreenState();
}

class _WeaponWizardScreenState extends ConsumerState<WeaponWizardScreen>
    with WizardFormMixin<WeaponWizardScreen> {
  late final TextEditingController _caliberNameCtrl;

  // ── Draft state (all raw values in FC rawUnits) ───────────────────────────
  // caliberDiameter: Unit.millimeter (FC.bulletDiameter)
  late double _caliberRaw;
  // twist magnitude: Unit.inch (FC.twist) — always positive, direction via _rightHand
  late double _twistRaw;
  late bool _rightHand;

  // ── Extra fields ──────────────────────────────────────────────────────────
  bool _showExtraFields = false;
  late double? _barrelLengthRaw;

  @override
  String get initialName => widget.initial?.name ?? '';

  @override
  String get initialVendor => widget.initial?.vendor ?? '';

  @override
  void initState() {
    super.initState();
    final w = widget.initial;
    _caliberNameCtrl = TextEditingController(text: w?.caliberName ?? '');
    _caliberRaw = (w != null && w.caliberInch > 0)
        ? w.caliber.in_(FC.projectileDiameter.rawUnit)
        : Distance.inch(0.338).in_(FC.projectileDiameter.rawUnit);
    final twistAbs = w?.twist.in_(FC.twist.rawUnit).abs() ?? 0.0;
    _twistRaw = twistAbs > 0 ? twistAbs : FC.twist.minRaw;
    _rightHand = w != null ? w.isRightHandTwist : true;

    // Initialize barrel length from an existing value, if any
    _barrelLengthRaw = w?.barrelLength?.in_(FC.barrelLength.rawUnit);

    // Show the section if there is a value in the database
    _showExtraFields = _barrelLengthRaw != null;
  }

  @override
  void dispose() {
    _caliberNameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid {
    if (!isNameValid) return false;
    if (_caliberRaw <= 0) return false;
    if (_twistRaw < 0) return false;
    return true;
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Weapon _buildWeapon() {
    final weapon = widget.initial ?? Weapon();
    weapon.name = nameCtrl.text.trim();
    weapon.vendor = vendorCtrl.text.trim().isEmpty
        ? null
        : vendorCtrl.text.trim();
    weapon.caliberName = _caliberNameCtrl.text.trim();
    weapon.caliber = Distance(_caliberRaw, FC.projectileDiameter.rawUnit);
    weapon.twist = Distance(
      _rightHand ? _twistRaw : -_twistRaw,
      FC.twist.rawUnit,
    );
    weapon.barrelLength = (_showExtraFields && _barrelLengthRaw != null)
        ? Distance(_barrelLengthRaw!, FC.barrelLength.rawUnit)
        : null;
    return weapon;
  }

  void _onSave() {
    if (!_isValid) return;
    commitSave(_buildWeapon);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSettingsProvider);
    final fmt = ref.watch(unitFormatterProvider);
    final caliberEditable = widget.caliberEditable ?? widget.initial == null;
    final twistDirIcon = _rightHand ? IconDef.twistR : IconDef.twistL;

    return BaseScreen(
      title: wizardTitle('New Rifle'),
      isSubscreen: true,
      showBack: false,
      bottomBar: WizardActionBar(
        onDiscard: onDiscard,
        onSave: _isValid ? _onSave : null,
      ),
      body: ListView(
        children: [
          _RiflePlaceholder(imageId: widget.initial?.image),
          // ── Name ────────────────────────────────────────────────────
          WizardNameField(
            controller: nameCtrl,
            label: 'Weapon name',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _caliberNameCtrl,
              decoration: const InputDecoration(labelText: 'Caliber name'),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          // ── Ballistics ───────────────────────────────────────────────
          const ListSectionTile('Ballistics'),
          if (caliberEditable)
            UnitValueFieldTile(
              title: 'Caliber diameter',
              rawValue: _caliberRaw,
              constraints: FC.projectileDiameter,
              displayUnit: units.diameterUnit,
              icon: IconDef.caliber,
              onChanged: (v) => setState(() => _caliberRaw = v),
            )
          else
            InfoListTile(
              label: 'Caliber diameter',
              value: widget.initial != null
                  ? fmt.diameter(widget.initial!.caliber)
                  : nullStr,
              icon: IconDef.caliber,
            ),
          // ── Hardware ─────────────────────────────────────────────────
          const ListSectionTile('Hardware'),
          UnitValueFieldTile(
            title: 'Twist rate',
            rawValue: _twistRaw,
            constraints: FC.twist,
            displayUnit: units.twistUnit,
            symbol: '1:${units.twistUnit.symbol}',
            icon: twistDirIcon,
            onChanged: (v) => setState(() => _twistRaw = v),
          ),
          SwitchListTile(
            secondary: Icon(twistDirIcon),
            title: const Text('Twist direction'),
            subtitle: Text(_rightHand ? 'right' : 'left'),
            value: _rightHand,
            onChanged: (v) => setState(() => _rightHand = v),
            dense: true,
          ),
          // ── Extra fields section ────────────────────────────────────
          Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(IconDef.moreHoriz),
            title: const Text('Additional parameters'),
            subtitle: const Text('Barrel length, etc.'),
            value: _showExtraFields,
            onChanged: (v) => setState(() => _showExtraFields = v),
            dense: true,
          ),
          if (_showExtraFields) ...[
            const SizedBox(height: 8),
            NullableUnitValueFieldTile(
              title: 'Barrel length',
              rawValue: _barrelLengthRaw,
              constraints: FC.barrelLength,
              displayUnit: units.barrelLengthUnit,
              icon: IconDef.length,
              onChanged: (v) => setState(() => _barrelLengthRaw = v),
            ),
            // You can add other additional fields here in the future
          ],
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RiflePlaceholder extends StatelessWidget {
  const _RiflePlaceholder({this.imageId});

  final String? imageId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SizedBox(
        height: 160,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: WeaponSvgView(imageId: imageId, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
