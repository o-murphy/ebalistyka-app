import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/features/home/sub_screens/weapon_wizard_notifier.dart';
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
import 'package:ebalistyka/shared/widgets/dividers.dart';

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

  @override
  String get initialName => widget.initial?.name ?? '';

  @override
  String get initialVendor => widget.initial?.vendor ?? '';

  NotifierProvider<WeaponWizardNotifier, WeaponWizardState> get _provider =>
      weaponWizardProvider((initial: widget.initial));

  @override
  void initState() {
    super.initState();
    _caliberNameCtrl = TextEditingController(
      text: widget.initial?.caliberName ?? '',
    );
  }

  @override
  void dispose() {
    _caliberNameCtrl.dispose();
    super.dispose();
  }

  @override
  void onNameChanged() {
    ref.read(_provider.notifier).updateName(nameCtrl.text);
    super.onNameChanged();
  }

  void _onSave() {
    final notifier = ref.read(_provider.notifier);
    notifier.updateVendor(vendorCtrl.text);
    notifier.updateCaliberName(_caliberNameCtrl.text);
    commitSave(ref.read(_provider).buildWeapon);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    final units = ref.watch(unitSettingsProvider);
    final formatter = ref.watch(unitFormatterProvider);
    final caliberEditable = widget.caliberEditable ?? widget.initial == null;
    final twistDirIcon = st.rightHand ? IconDef.twistR : IconDef.twistL;

    return BaseScreen(
      title: wizardTitle('New Rifle'),
      isSubscreen: true,
      showBack: false,
      bottomBar: WizardActionBar(
        onDiscard: onDiscard,
        onSave: st.isValid ? _onSave : null,
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
              rawValue: st.caliberRaw,
              constraints: FC.projectileDiameter,
              displayUnit: units.diameterUnit,
              icon: IconDef.caliber,
              onChanged: notifier.updateCaliberRaw,
            )
          else
            InfoListTile(
              label: 'Caliber diameter',
              value: formatter.diameter(widget.initial?.caliber),
              icon: IconDef.caliber,
            ),
          // ── Hardware ─────────────────────────────────────────────────
          const ListSectionTile('Hardware'),
          UnitValueFieldTile(
            title: 'Twist rate',
            rawValue: st.twistRaw,
            constraints: FC.twist,
            displayUnit: units.twistUnit,
            symbol: '1:${units.twistUnit.symbol}',
            icon: twistDirIcon,
            onChanged: notifier.updateTwistRaw,
          ),
          SwitchListTile(
            secondary: Icon(twistDirIcon),
            title: const Text('Twist direction'),
            subtitle: Text(st.rightHand ? 'right' : 'left'),
            value: st.rightHand,
            onChanged: notifier.updateRightHand,
            dense: true,
          ),
          // ── Extra fields section ────────────────────────────────────
          const TileDivider(),
          SwitchListTile(
            secondary: const Icon(IconDef.moreHoriz),
            title: const Text('Additional parameters'),
            subtitle: const Text('Barrel length, etc.'),
            value: st.showExtraFields,
            onChanged: notifier.updateShowExtraFields,
            dense: true,
          ),
          if (st.showExtraFields) ...[
            const SizedBox(height: 8),
            NullableUnitValueFieldTile(
              title: 'Barrel length',
              rawValue: st.barrelLengthRaw,
              constraints: FC.barrelLength,
              displayUnit: units.barrelLengthUnit,
              icon: IconDef.length,
              onChanged: notifier.updateBarrelLengthRaw,
            ),
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
