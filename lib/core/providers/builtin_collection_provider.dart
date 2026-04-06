import 'package:ebalistyka/core/providers/storage_provider.dart';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/collection/collection_parser.dart';

/// Loads the built-in collection with the following priority:
///   1. ~/.eBalistyka/collection.json  — cached/updated version from network
///   2. assets/json/collection.json   — bundled fallback (always available)
final builtinCollectionProvider = FutureProvider<BuiltinCollection>((
  ref,
) async {
  // Отримуємо доступ до storage через appStateProvider або напряму
  // Оскільки це не користувацькі дані, а статична колекція, можемо залишити прямий доступ до storage
  final storage = ref.read(appStorageProvider);

  final cached = await storage.loadCollectionJson();
  if (cached != null) {
    return CollectionParser.parse(cached);
  }

  final bundled = await rootBundle.loadString('assets/json/collection.json');
  return CollectionParser.parse(bundled);
});
