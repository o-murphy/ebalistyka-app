import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod/riverpod.dart';

const weaponAssetPrefix = 'assets/svg/weapon/';
const defaultWeaponId = 'default';

/// Loads a weapon SVG asset by image ID (filename without extension).
/// Falls back to [defaultWeaponId].svg when [id] is null, empty, or not found.
///
/// Color-role substitution (e.g. fill="onSurface") is intentionally left to
/// the widget layer via [resolveSvgColorRoles] so the provider stays pure.
final weaponSvgProvider = FutureProvider.family<String, String?>((
  ref,
  id,
) async {
  const fallback = '$weaponAssetPrefix$defaultWeaponId.svg';
  final resolved = (id == null || id.isEmpty) ? null : id;
  if (resolved == null) return rootBundle.loadString(fallback);
  try {
    return await rootBundle.loadString('$weaponAssetPrefix$resolved.svg');
  } catch (_) {
    return rootBundle.loadString(fallback);
  }
});
