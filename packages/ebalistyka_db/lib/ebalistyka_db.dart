import 'dart:io';
import 'objectbox.g.dart';

export 'src/entities.dart';
export 'objectbox.g.dart';

/// Opens (or creates) the ObjectBox store at [directory].
///
/// The caller is responsible for resolving an appropriate path
/// (e.g. via `getApplicationSupportDirectory()` from path_provider).
Future<Store> initObjectBox({required String directory}) async {
  await Directory(directory).create(recursive: true);
  return openStore(directory: directory);
}
