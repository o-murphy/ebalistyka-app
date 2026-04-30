import 'package:bclibc_ffi/unit.dart';
import 'package:ebalistyka/core/extensions/settings_extensions.dart';
import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:ebalistyka/core/models/field_constraints.dart';
import 'package:ebalistyka/core/providers/filter_providers.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/widgets/unit_constrained_input_field.dart';
import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Public entry points ───────────────────────────────────────────────────────

Future<void> showAmmoFilterSheet(
  BuildContext context, {
  required List<Ammo> allItems,
  required double? defaultCaliberInch,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AmmoFilterSheet(
    allItems: allItems,
    defaultCaliberInch: defaultCaliberInch,
  ),
);

Future<void> showAmmoCollectionFilterSheet(
  BuildContext context, {
  required List<Ammo> allItems,
  required double? defaultCaliberInch,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _AmmoFilterSheet(
    allItems: allItems,
    defaultCaliberInch: defaultCaliberInch,
    forCollection: true,
  ),
);

Future<void> showSightFilterSheet(
  BuildContext context, {
  required List<Sight> allItems,
  bool forCollection = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      _SightFilterSheet(allItems: allItems, forCollection: forCollection),
);

Future<void> showWeaponFilterSheet(
  BuildContext context, {
  required List<Weapon> allItems,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _WeaponFilterSheet(allItems: allItems),
);

// ── Ammo filter sheet ─────────────────────────────────────────────────────────

class _AmmoFilterSheet extends ConsumerStatefulWidget {
  const _AmmoFilterSheet({
    required this.allItems,
    required this.defaultCaliberInch,
    this.forCollection = false,
  });

  final List<Ammo> allItems;
  final double? defaultCaliberInch;
  final bool forCollection;

  @override
  ConsumerState<_AmmoFilterSheet> createState() => _AmmoFilterSheetState();
}

class _AmmoFilterSheetState extends ConsumerState<_AmmoFilterSheet> {
  late Set<String> _vendors;
  late Set<double> _calibers;
  double? _minWeightGrain;
  double? _maxWeightGrain;

  AmmoFilterState get _defaultState => AmmoFilterState(
    calibers: widget.defaultCaliberInch != null
        ? {widget.defaultCaliberInch!}
        : {},
  );

  @override
  void initState() {
    super.initState();
    final applied = ref.read(
      widget.forCollection
          ? ammoCollectionFilterProvider(widget.defaultCaliberInch)
          : ammoFilterProvider(widget.defaultCaliberInch),
    );
    _vendors = Set.from(applied.vendors);
    _calibers = Set.from(applied.calibers);
    _minWeightGrain = applied.minWeightGrain;
    _maxWeightGrain = applied.maxWeightGrain;
  }

  void _reset() => setState(() {
    final d = _defaultState;
    _vendors = Set.from(d.vendors);
    _calibers = Set.from(d.calibers);
    _minWeightGrain = d.minWeightGrain;
    _maxWeightGrain = d.maxWeightGrain;
  });

  void _apply() {
    final notifier = ref.read(
      widget.forCollection
          ? ammoCollectionFilterProvider(widget.defaultCaliberInch).notifier
          : ammoFilterProvider(widget.defaultCaliberInch).notifier,
    );
    notifier.apply(
      vendors: _vendors,
      calibers: _calibers,
      minWeightGrain: _minWeightGrain,
      maxWeightGrain: _maxWeightGrain,
    );
    Navigator.of(context).pop();
  }

  void _toggleVendor(String v) => setState(() {
    final s = Set<String>.from(_vendors);
    if (s.contains(v)) {
      s.remove(v);
    } else {
      s.add(v);
    }
    _vendors = s;
  });

  void _toggleCaliber(double c) => setState(() {
    final s = Set<double>.from(_calibers);
    if (s.contains(c)) {
      s.remove(c);
    } else {
      s.add(c);
    }
    _calibers = s;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final units = ref.watch(unitSettingsProvider);

    final vendorCounts = <String, int>{};
    for (final a in widget.allItems) {
      final v = a.vendor ?? '';
      if (v.isNotEmpty) vendorCounts[v] = (vendorCounts[v] ?? 0) + 1;
    }
    final vendors = vendorCounts.keys.toList()..sort();

    final caliberCounts = <double, int>{};
    for (final a in widget.allItems) {
      if (a.caliberInch > 0) {
        caliberCounts[a.caliberInch] = (caliberCounts[a.caliberInch] ?? 0) + 1;
      }
    }
    final calibers = caliberCounts.keys.toList()..sort();

    final draftIsDefault =
        _vendors.isEmpty &&
        setEquals(
          _calibers,
          widget.defaultCaliberInch != null
              ? {widget.defaultCaliberInch!}
              : <double>{},
        ) &&
        _minWeightGrain == null &&
        _maxWeightGrain == null;

    return _FilterSheetLayout(
      title: l10n.filterTitle,
      canReset: !draftIsDefault,
      onReset: _reset,
      onApply: _apply,
      sections: [
        if (vendors.isNotEmpty)
          _CheckboxSection(
            title: l10n.vendor,
            initiallyExpanded: _vendors.isNotEmpty,
            children: [
              for (final vendor in vendors)
                _CheckboxTile(
                  label: vendor,
                  count: vendorCounts[vendor]!,
                  checked: _vendors.contains(vendor),
                  onChanged: (_) => _toggleVendor(vendor),
                ),
            ],
          ),
        if (calibers.isNotEmpty)
          _CheckboxSection(
            title: l10n.caliber,
            initiallyExpanded: _calibers.isNotEmpty,
            children: [
              for (final c in calibers)
                _CheckboxTile(
                  label: _formatCaliber(c, units.diameterUnit),
                  count: caliberCounts[c]!,
                  checked: _calibers.contains(c),
                  onChanged: (_) => _toggleCaliber(c),
                ),
            ],
          ),
        _WeightRangeSection(
          l10n: l10n,
          weightUnit: units.weightUnit,
          minRaw: _minWeightGrain,
          maxRaw: _maxWeightGrain,
          onMinChanged: (v) => setState(() => _minWeightGrain = v),
          onMaxChanged: (v) => setState(() => _maxWeightGrain = v),
        ),
      ],
    );
  }

  String _formatCaliber(double caliberInch, Unit displayUnit) {
    final value = caliberInch.convert(Unit.inch, displayUnit);
    final precision = displayUnit == Unit.inch ? 3 : 2;
    return value.toStringAsFixed(precision);
  }
}

// ── Sight filter sheet ────────────────────────────────────────────────────────

class _SightFilterSheet extends ConsumerStatefulWidget {
  const _SightFilterSheet({required this.allItems, this.forCollection = false});

  final List<Sight> allItems;
  final bool forCollection;

  @override
  ConsumerState<_SightFilterSheet> createState() => _SightFilterSheetState();
}

class _SightFilterSheetState extends ConsumerState<_SightFilterSheet> {
  late Set<String> _vendors;
  late Set<FocalPlane> _focalPlanes;

  @override
  void initState() {
    super.initState();
    final applied = ref.read(
      widget.forCollection
          ? sightCollectionFilterProvider
          : sightFilterProvider,
    );
    _vendors = Set.from(applied.vendors);
    _focalPlanes = Set.from(applied.focalPlanes);
  }

  void _reset() => setState(() {
    _vendors = {};
    _focalPlanes = {};
  });

  void _apply() {
    final notifier = ref.read(
      widget.forCollection
          ? sightCollectionFilterProvider.notifier
          : sightFilterProvider.notifier,
    );
    notifier.apply(vendors: _vendors, focalPlanes: _focalPlanes);
    Navigator.of(context).pop();
  }

  void _toggleVendor(String v) => setState(() {
    final s = Set<String>.from(_vendors);
    if (s.contains(v)) {
      s.remove(v);
    } else {
      s.add(v);
    }
    _vendors = s;
  });

  void _toggleFocalPlane(FocalPlane fp) => setState(() {
    final s = Set<FocalPlane>.from(_focalPlanes);
    if (s.contains(fp)) {
      s.remove(fp);
    } else {
      s.add(fp);
    }
    _focalPlanes = s;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final vendorCounts = <String, int>{};
    for (final s in widget.allItems) {
      final v = s.vendor ?? '';
      if (v.isNotEmpty) vendorCounts[v] = (vendorCounts[v] ?? 0) + 1;
    }
    final vendors = vendorCounts.keys.toList()..sort();

    final fpCounts = <FocalPlane, int>{};
    for (final s in widget.allItems) {
      fpCounts[s.focalPlane] = (fpCounts[s.focalPlane] ?? 0) + 1;
    }

    return _FilterSheetLayout(
      title: l10n.filterTitle,
      canReset: _vendors.isNotEmpty || _focalPlanes.isNotEmpty,
      onReset: _reset,
      onApply: _apply,
      sections: [
        if (vendors.isNotEmpty)
          _CheckboxSection(
            title: l10n.vendor,
            initiallyExpanded: _vendors.isNotEmpty,
            children: [
              for (final vendor in vendors)
                _CheckboxTile(
                  label: vendor,
                  count: vendorCounts[vendor]!,
                  checked: _vendors.contains(vendor),
                  onChanged: (_) => _toggleVendor(vendor),
                ),
            ],
          ),
        _CheckboxSection(
          title: l10n.focalPlane,
          initiallyExpanded: _focalPlanes.isNotEmpty,
          children: [
            for (final fp in FocalPlane.values)
              _CheckboxTile(
                label: _fpLabel(fp, l10n),
                count: fpCounts[fp] ?? 0,
                checked: _focalPlanes.contains(fp),
                onChanged: (_) => _toggleFocalPlane(fp),
              ),
          ],
        ),
      ],
    );
  }

  String _fpLabel(FocalPlane fp, AppLocalizations l10n) => switch (fp) {
    FocalPlane.ffp => l10n.focalPlaneFFP,
    FocalPlane.sfp => l10n.focalPlaneSFP,
    FocalPlane.lwir => l10n.focalPlaneLWIR,
  };
}

// ── Weapon filter sheet ───────────────────────────────────────────────────────

class _WeaponFilterSheet extends ConsumerStatefulWidget {
  const _WeaponFilterSheet({required this.allItems});

  final List<Weapon> allItems;

  @override
  ConsumerState<_WeaponFilterSheet> createState() => _WeaponFilterSheetState();
}

class _WeaponFilterSheetState extends ConsumerState<_WeaponFilterSheet> {
  late Set<String> _vendors;

  @override
  void initState() {
    super.initState();
    _vendors = Set.from(ref.read(weaponCollectionFilterProvider).vendors);
  }

  void _reset() => setState(() => _vendors = {});

  void _apply() {
    ref.read(weaponCollectionFilterProvider.notifier).apply(vendors: _vendors);
    Navigator.of(context).pop();
  }

  void _toggleVendor(String v) => setState(() {
    final s = Set<String>.from(_vendors);
    if (s.contains(v)) {
      s.remove(v);
    } else {
      s.add(v);
    }
    _vendors = s;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final vendorCounts = <String, int>{};
    for (final w in widget.allItems) {
      final v = w.vendor ?? '';
      if (v.isNotEmpty) vendorCounts[v] = (vendorCounts[v] ?? 0) + 1;
    }
    final vendors = vendorCounts.keys.toList()..sort();

    return _FilterSheetLayout(
      title: l10n.filterTitle,
      canReset: _vendors.isNotEmpty,
      onReset: _reset,
      onApply: _apply,
      sections: [
        if (vendors.isNotEmpty)
          _CheckboxSection(
            title: l10n.vendor,
            initiallyExpanded: _vendors.isNotEmpty,
            children: [
              for (final vendor in vendors)
                _CheckboxTile(
                  label: vendor,
                  count: vendorCounts[vendor]!,
                  checked: _vendors.contains(vendor),
                  onChanged: (_) => _toggleVendor(vendor),
                ),
            ],
          ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _FilterSheetLayout extends StatelessWidget {
  const _FilterSheetLayout({
    required this.title,
    required this.canReset,
    required this.onReset,
    required this.onApply,
    required this.sections,
  });

  final String title;
  final bool canReset;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: canReset ? onReset : null,
                child: Text(l10n.filterResetAction),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: sections,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onApply,
              child: Text(l10n.filterApplyAction),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckboxSection extends StatelessWidget {
  const _CheckboxSection({
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title),
      initiallyExpanded: initiallyExpanded,
      children: children,
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({
    required this.label,
    required this.count,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final int count;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: checked,
      onChanged: onChanged,
      title: Text(label),
      secondary: _CountBadge(count: count),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _WeightRangeSection extends StatelessWidget {
  const _WeightRangeSection({
    required this.l10n,
    required this.weightUnit,
    required this.minRaw,
    required this.maxRaw,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  final AppLocalizations l10n;
  final Unit weightUnit;
  final double? minRaw;
  final double? maxRaw;
  final ValueChanged<double?> onMinChanged;
  final ValueChanged<double?> onMaxChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(l10n.weight),
      initiallyExpanded: minRaw != null || maxRaw != null,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: ConstrainedUnitInputField(
                  rawValue: minRaw,
                  constraints: FC.projectileWeight,
                  displayUnit: weightUnit,
                  label: l10n.filterWeightMin,
                  onChanged: onMinChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ConstrainedUnitInputField(
                  rawValue: maxRaw,
                  constraints: FC.projectileWeight,
                  displayUnit: weightUnit,
                  label: l10n.filterWeightMax,
                  onChanged: onMaxChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
