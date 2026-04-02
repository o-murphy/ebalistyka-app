import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eballistica/core/collection/collection_parser.dart';
import 'storage_provider.dart';

/// Loads the built-in collection with the following priority:
///   1. ~/.eBalistyka/collection.json  — cached/updated version from network
///   2. assets/json/collection.json   — bundled fallback (always available)
final builtinCollectionProvider = FutureProvider<BuiltinCollection>((ref) async {
  final storage = ref.read(appStorageProvider);

  final cached = await storage.loadCollectionJson();
  if (cached != null) {
    return CollectionParser.parse(cached);
  }

  final bundled = await rootBundle.loadString('assets/json/collection.json');
  return CollectionParser.parse(bundled);
});
