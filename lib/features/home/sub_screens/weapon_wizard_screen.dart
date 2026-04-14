import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:bclibc_ffi/unit.dart' show Distance;
import 'package:ebalistyka/core/extensions/weapon_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/formatter_provider.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/base_screen.dart';
import 'package:ebalistyka/shared/widgets/info_tile.dart';
import 'package:ebalistyka/shared/widgets/list_section_tile.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_tile.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _WeaponWizardScreenState extends ConsumerState<WeaponWizardScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _vendorCtrl;
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

  String? _nameError;
  bool _nameTouched = false;

  @override
  void initState() {
    super.initState();
    final w = widget.initial;
    _nameCtrl = TextEditingController(text: w?.name ?? '');
    _vendorCtrl = TextEditingController(text: w?.vendor ?? '');
    _caliberNameCtrl = TextEditingController(text: w?.caliberName ?? '');
    _caliberRaw = (w != null && w.caliberInch > 0)
        ? w.caliber.in_(FC.projectileDiameter.rawUnit)
        : Distance.inch(0.338).in_(FC.projectileDiameter.rawUnit);
    final twistAbs = w?.twist.in_(FC.twist.rawUnit).abs() ?? 0.0;
    _twistRaw = twistAbs > 0 ? twistAbs : FC.twist.minRaw;
    _rightHand = w != null ? w.isRightHandTwist : true;

    // Ініціалізуємо barrel length з існуючого значення, якщо воно є
    _barrelLengthRaw = w?.barrelLength?.in_(FC.barrelLength.rawUnit);

    // Показуємо секцію, якщо є значення в базі
    _showExtraFields = _barrelLengthRaw != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _vendorCtrl.dispose();
    _caliberNameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid {
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_caliberRaw <= 0) return false;
    if (_twistRaw <= 0) return false;
    return true;
  }

  void _validateName() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Name is required' : null;
    });
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Weapon _buildWeapon() {
    final weapon = widget.initial ?? Weapon();
    weapon.name = _nameCtrl.text.trim();
    weapon.vendor = _vendorCtrl.text.trim().isEmpty ? null : _vendorCtrl.text.trim();
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
    _nameTouched = true;
    _validateName();
    if (!_isValid) return;
    context.pop(_buildWeapon());
  }

  void _onDiscard() => context.pop(null);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(unitSettingsProvider);
    final fmt = ref.watch(unitFormatterProvider);
    final title = _nameCtrl.text.trim().isEmpty
        ? 'New Rifle'
        : _nameCtrl.text.trim();
    final caliberEditable = widget.caliberEditable ?? widget.initial == null;
    final twistDirIcon = _rightHand ? IconDef.twistR : IconDef.twistL;

    return BaseScreen(
      title: title,
      isSubscreen: true,
      showBack: false,
      bottomBar: _ActionBar(
        onDiscard: _onDiscard,
        onSave: _isValid ? _onSave : null,
      ),
      body: ListView(
        children: [
          _RiflePlaceholder(),
          // ── Name ────────────────────────────────────────────────────
          ColoredBox(
            color: _nameCtrl.text.trim().isEmpty
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Weapon name',
                  errorText: _nameError,
                  labelStyle: _nameCtrl.text.trim().isEmpty
                      ? TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        )
                      : null,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (_nameTouched) _validateName();
                  setState(() {});
                },
                onEditingComplete: _validateName,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _vendorCtrl,
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
                  : '—',
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
            // Тут можна додати інші додаткові поля в майбутньому
          ],
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _RiflePlaceholder extends StatelessWidget {
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
                  IconDef.image,
                  size: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rifle image',
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
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
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
      ),
    );
  }
}
