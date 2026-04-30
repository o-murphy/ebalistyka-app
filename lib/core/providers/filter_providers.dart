import 'package:ebalistyka/core/extensions/sight_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Ammo filter ───────────────────────────────────────────────────────────────

@immutable
class AmmoFilterState {
  const AmmoFilterState({
    this.vendors = const {},
    this.calibers = const {},
    this.minWeightGrain,
    this.maxWeightGrain,
  });

  final Set<String> vendors;
  final Set<double> calibers;
  final double? minWeightGrain;
  final double? maxWeightGrain;

  bool get isActive =>
      vendors.isNotEmpty ||
      calibers.isNotEmpty ||
      minWeightGrain != null ||
      maxWeightGrain != null;
}

class AmmoFilterNotifier extends Notifier<AmmoFilterState> {
  AmmoFilterNotifier(this._defaultCaliberInch);
  final double? _defaultCaliberInch;

  @override
  AmmoFilterState build() => AmmoFilterState(
    calibers: _defaultCaliberInch != null ? {_defaultCaliberInch} : {},
  );

  void toggleVendor(String vendor) {
    final s = Set<String>.from(state.vendors);
    if (s.contains(vendor)) {
      s.remove(vendor);
    } else {
      s.add(vendor);
    }
    state = AmmoFilterState(
      vendors: s,
      calibers: state.calibers,
      minWeightGrain: state.minWeightGrain,
      maxWeightGrain: state.maxWeightGrain,
    );
  }

  void toggleCaliber(double caliberInch) {
    final s = Set<double>.from(state.calibers);
    if (s.contains(caliberInch)) {
      s.remove(caliberInch);
    } else {
      s.add(caliberInch);
    }
    state = AmmoFilterState(
      vendors: state.vendors,
      calibers: s,
      minWeightGrain: state.minWeightGrain,
      maxWeightGrain: state.maxWeightGrain,
    );
  }

  void setMinWeight(double? v) => state = AmmoFilterState(
    vendors: state.vendors,
    calibers: state.calibers,
    minWeightGrain: v,
    maxWeightGrain: state.maxWeightGrain,
  );

  void setMaxWeight(double? v) => state = AmmoFilterState(
    vendors: state.vendors,
    calibers: state.calibers,
    minWeightGrain: state.minWeightGrain,
    maxWeightGrain: v,
  );

  void apply({
    required Set<String> vendors,
    required Set<double> calibers,
    double? minWeightGrain,
    double? maxWeightGrain,
  }) => state = AmmoFilterState(
    vendors: vendors,
    calibers: calibers,
    minWeightGrain: minWeightGrain,
    maxWeightGrain: maxWeightGrain,
  );

  void reset() => state = AmmoFilterState(
    calibers: _defaultCaliberInch != null ? {_defaultCaliberInch} : {},
  );
}

final ammoFilterProvider = NotifierProvider.autoDispose
    .family<AmmoFilterNotifier, AmmoFilterState, double?>(
      (arg) => AmmoFilterNotifier(arg),
    );

final ammoCollectionFilterProvider = NotifierProvider.autoDispose
    .family<AmmoFilterNotifier, AmmoFilterState, double?>(
      (arg) => AmmoFilterNotifier(arg),
    );

// ── Sight filter ──────────────────────────────────────────────────────────────

@immutable
class SightFilterState {
  const SightFilterState({
    this.vendors = const {},
    this.focalPlanes = const {},
  });

  final Set<String> vendors;
  final Set<FocalPlane> focalPlanes;

  bool get isActive => vendors.isNotEmpty || focalPlanes.isNotEmpty;
}

class SightFilterNotifier extends Notifier<SightFilterState> {
  @override
  SightFilterState build() => const SightFilterState();

  void toggleVendor(String vendor) {
    final s = Set<String>.from(state.vendors);
    if (s.contains(vendor)) {
      s.remove(vendor);
    } else {
      s.add(vendor);
    }
    state = SightFilterState(vendors: s, focalPlanes: state.focalPlanes);
  }

  void toggleFocalPlane(FocalPlane fp) {
    final s = Set<FocalPlane>.from(state.focalPlanes);
    if (s.contains(fp)) {
      s.remove(fp);
    } else {
      s.add(fp);
    }
    state = SightFilterState(vendors: state.vendors, focalPlanes: s);
  }

  void apply({
    required Set<String> vendors,
    required Set<FocalPlane> focalPlanes,
  }) => state = SightFilterState(vendors: vendors, focalPlanes: focalPlanes);

  void reset() => state = const SightFilterState();
}

final sightFilterProvider =
    NotifierProvider.autoDispose<SightFilterNotifier, SightFilterState>(
      SightFilterNotifier.new,
    );

final sightCollectionFilterProvider =
    NotifierProvider.autoDispose<SightFilterNotifier, SightFilterState>(
      SightFilterNotifier.new,
    );

// ── Weapon filter ─────────────────────────────────────────────────────────────

@immutable
class WeaponFilterState {
  const WeaponFilterState({this.vendors = const {}});

  final Set<String> vendors;

  bool get isActive => vendors.isNotEmpty;
}

class WeaponFilterNotifier extends Notifier<WeaponFilterState> {
  @override
  WeaponFilterState build() => const WeaponFilterState();

  void toggleVendor(String vendor) {
    final s = Set<String>.from(state.vendors);
    if (s.contains(vendor)) {
      s.remove(vendor);
    } else {
      s.add(vendor);
    }
    state = WeaponFilterState(vendors: s);
  }

  void apply({required Set<String> vendors}) =>
      state = WeaponFilterState(vendors: vendors);

  void reset() => state = const WeaponFilterState();
}

final weaponCollectionFilterProvider =
    NotifierProvider.autoDispose<WeaponFilterNotifier, WeaponFilterState>(
      WeaponFilterNotifier.new,
    );
