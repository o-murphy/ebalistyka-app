import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/ammo_extensions.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
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

  String? _nameError;
  bool _nameTouched = false;

  late double _caliberRaw;
  late double _weightRaw;
  late double _lengthRaw;
  late DragType _dragType;
  late bool _useMultiBcG1;
  late bool _useMultiBcG7;
  late double _bcG1;
  late double _bcG7;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _caliberRaw =
        a?.caliber.in_(FC.projectileDiameter.rawUnit) ??
        Distance.inch(
          widget.caliberInch ?? 0.0,
        ).in_(FC.projectileDiameter.rawUnit);
    _weightRaw = a?.weight.in_(FC.projectileWeight.rawUnit) ?? 0.0;
    _lengthRaw = a?.length.in_(FC.projectileLength.rawUnit) ?? 0.0;
    _dragType = a?.dragType ?? DragType.g1;
    _useMultiBcG1 = a?.useMultiBcG1 ?? false;
    _useMultiBcG7 = a?.useMultiBcG7 ?? false;
    _bcG1 = a?.bcG1 ?? 1.0;
    _bcG7 = a?.bcG7 ?? 1.0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get _isValid => _nameCtrl.text.trim().isNotEmpty;

  void _validateName() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? 'Name is required' : null;
    });
  }

  // ── Build result ──────────────────────────────────────────────────────────

  Ammo _buildAmmo() {
    final ammo = widget.initial ?? Ammo();
    ammo.name = _nameCtrl.text.trim();
    ammo.caliber = Distance(_caliberRaw, FC.projectileDiameter.rawUnit);
    ammo.weight = Weight(_weightRaw, FC.projectileWeight.rawUnit);
    ammo.length = Distance(_lengthRaw, FC.projectileLength.rawUnit);
    ammo.dragType = _dragType;
    ammo.useMultiBcG1 = _useMultiBcG1;
    ammo.useMultiBcG7 = _useMultiBcG7;
    ammo.bcG1 = _bcG1;
    ammo.bcG7 = _bcG7;
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
    required double bcRaw,
    required ValueChanged<bool> onMultiChanged,
    required ValueChanged<double> onBcChanged,
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
        UnitValueFieldTile(
          label: 'Ballistic coefficient $dtName',
          rawValue: bcRaw,
          constraints: FC.ballisticCoefficient,
          displayUnit: Unit.fraction,
          icon: IconDef.dragModel,
          onChanged: (v) => setState(() => onBcChanged(v)),
        ),
      // TODO: there should be a route to multi-bc edit screen (form)
      if (useMulti)
        ListTile(
          title: Text('Edit $dtName Multi-BC table'),
          trailing: Icon(
            IconDef.edit,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          dense: true,
          onTap: () => debugPrint("Route to multi-bc editor"),
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
            title: Text('Edit $dtName DragModel'),
            trailing: Icon(
              IconDef.edit,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            dense: true,
            onTap: () => debugPrint("Route to drag table editor"),
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
                // ── Mounting ──────────────────────────────────────────────
                const Divider(height: 1),
                const ListSectionTile('Projectile'),
                InfoListTile(
                  label: 'Caliber',
                  value: _caliberRaw > 0
                      ? fmt.diameter(
                          Distance(_caliberRaw, FC.projectileDiameter.rawUnit),
                        )
                      : '—',
                  icon: IconDef.caliber,
                ),
                UnitValueFieldTile(
                  label: 'Weight',
                  rawValue: _weightRaw,
                  constraints: FC.projectileWeight,
                  displayUnit: units.weightUnit,
                  icon: IconDef.weigth,
                  onChanged: (v) => setState(() => _weightRaw = v),
                ),
                UnitValueFieldTile(
                  label: 'Length',
                  rawValue: _lengthRaw,
                  constraints: FC.projectileLength,
                  displayUnit: units.lengthUnit,
                  icon: IconDef.length,
                  onChanged: (v) => setState(() => _lengthRaw = v),
                ),
                _buildDragModel(),
              ],
            ),
          ),
          // ── Action bar ───────────────────────────────────────────────────
          _ActionBar(onDiscard: _onDiscard, onSave: _onSave),
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
        height: 120,
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
