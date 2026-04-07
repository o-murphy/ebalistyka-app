import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/collection/collection_parser.dart';

/// Loads the built-in collection from the bundled asset.
final builtinCollectionProvider = FutureProvider<BuiltinCollection>((
  ref,
) async {
  final bundled = await rootBundle.loadString('assets/json/collection.json');
  return CollectionParser.parse(bundled);
});
