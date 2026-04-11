import 'package:ebalistyka_db/ebalistyka_db.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the open ObjectBox [Store].
///
/// Must be overridden before [runApp]:
/// ```dart
/// final store = await initObjectBox();
/// runApp(ProviderScope(
///   overrides: [dbProvider.overrideWithValue(store)],
///   child: MyApp(),
/// ));
/// ```
final dbProvider = Provider<Store>((ref) {
  throw UnimplementedError('dbProvider must be overridden with an open Store');
});

/// Returns the singleton local [Owner] (token = "local").
///
/// Creates it on first run. All local entities are linked to this owner —
/// ready for a future remote-repository swap without changing query logic.
final ownerProvider = Provider<Owner>((ref) {
  final store = ref.watch(dbProvider);
  final box = store.box<Owner>();

  final existing = box.query(Owner_.token.equals('local')).build().findFirst();
  if (existing != null) return existing;

  final owner = Owner()..token = 'local';
  box.put(owner);
  return owner;
});
