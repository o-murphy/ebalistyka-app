import 'package:flutter/services.dart' show rootBundle;
import 'package:riverpod/riverpod.dart';

const ammoAssetPrefix = 'assets/svg/ammo/';
const defaultAmmoId = 'default';

/// Loads an ammo SVG asset by image ID (filename without extension).
/// Falls back to [defaultAmmoId].svg when [id] is null, empty, or not found.
final ammoSvgProvider = FutureProvider.family<String, String?>((ref, id) async {
  const fallback = '$ammoAssetPrefix$defaultAmmoId.svg';
  final resolved = (id == null || id.isEmpty) ? null : id;
  if (resolved == null) return rootBundle.loadString(fallback);
  try {
    return await rootBundle.loadString('$ammoAssetPrefix$resolved.svg');
  } catch (_) {
    return rootBundle.loadString(fallback);
  }
});
