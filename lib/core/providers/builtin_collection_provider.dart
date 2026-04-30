import 'dart:io';

import 'package:ebalistyka/core/collection/collection_parser.dart';
import 'package:ebalistyka/shared/constants/app_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

/// Loads the active collection: cached download if present, bundled asset otherwise.
/// Invalidate this provider after a successful collection update to reload.
final builtinCollectionProvider = FutureProvider<BuiltinCollection>((
  ref,
) async {
  try {
    final appSupport = await getApplicationSupportDirectory();
    final cached = File('${appSupport.path}/$collectionFile');
    if (await cached.exists()) {
      final json = await cached.readAsString();
      return CollectionParser.parse(json);
    }
  } catch (e) {
    debugPrint('Failed to load cached collection, falling back to asset: $e');
  }
  final bundled = await rootBundle.loadString('assets/json/collection.json');
  return CollectionParser.parse(bundled);
});
