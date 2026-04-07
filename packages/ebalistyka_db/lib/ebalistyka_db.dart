import 'dart:io';
import 'objectbox.g.dart';

export 'src/entities.dart';

/// Opens (or creates) the ObjectBox store at [directory].
///
/// Defaults to `~/.eBallistyka` when [directory] is not provided.
Future<Store> initObjectBox({String? directory}) async {
  final dir = directory ?? '${Platform.environment['HOME']}/.eBallistyka';
  await Directory(dir).create(recursive: true);
  return openStore(directory: dir);
}
