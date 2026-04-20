import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:riverpod/riverpod.dart';

const reticleAssetPrefix = 'assets/svg/reticles/';
const defaultReticleId = 'default';

const targetAssetPrefix = 'assets/svg/targets/';
const defaultTargetId = 'default';

/// Lists all available reticle IDs by scanning the asset manifest.
/// The list is sorted with "default" always first.
final reticleListProvider = FutureProvider<List<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final ids =
      manifest
          .listAssets()
          .where((k) => k.startsWith(reticleAssetPrefix) && k.endsWith('.svg'))
          .map((k) => k.substring(reticleAssetPrefix.length, k.length - 4))
          .toList()
        ..sort((a, b) {
          if (a == defaultReticleId) return -1;
          if (b == defaultReticleId) return 1;
          return a.compareTo(b);
        });
  return ids;
});

/// Loads an SVG asset by reticle ID (corresponds to filename without extension).
/// Falls back to [defaultReticleId].svg when [id] is null, empty, or not found.
final reticleSvgProvider = FutureProvider.family<String, String?>((
  ref,
  id,
) async {
  const fallback = '$reticleAssetPrefix$defaultReticleId.svg';
  final resolved = (id == null || id.isEmpty) ? null : id;
  if (resolved == null) return rootBundle.loadString(fallback);
  try {
    return await rootBundle.loadString('$reticleAssetPrefix$resolved.svg');
  } catch (_) {
    return rootBundle.loadString(fallback);
  }
});

/// Lists all available target IDs by scanning the asset manifest.
final targetListProvider = FutureProvider<List<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest
      .listAssets()
      .where((k) => k.startsWith(targetAssetPrefix) && k.endsWith('.svg'))
      .map((k) => k.substring(targetAssetPrefix.length, k.length - 4))
      .toList()
    ..sort((a, b) {
      if (a == defaultTargetId) return -1;
      if (b == defaultTargetId) return 1;
      return a.compareTo(b);
    });
});

/// Loads a target SVG asset by ID. Falls back to [defaultTargetId].svg.
final targetSvgProvider = FutureProvider.family<String, String?>((
  ref,
  id,
) async {
  const fallback = '$targetAssetPrefix$defaultTargetId.svg';
  final resolved = (id == null || id.isEmpty) ? null : id;
  if (resolved == null) return rootBundle.loadString(fallback);
  try {
    return await rootBundle.loadString('$targetAssetPrefix$resolved.svg');
  } catch (_) {
    return rootBundle.loadString(fallback);
  }
});
