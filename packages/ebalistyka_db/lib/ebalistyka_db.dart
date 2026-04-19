import 'dart:io';
import 'objectbox.g.dart';

export 'src/entities.dart';
export 'src/export/ammo_export.dart';
export 'src/export/conditions_export.dart';
export 'src/export/ebcp_file.dart';
export 'src/export/ebcp_item.dart';
export 'src/export/float64list_converter.dart';
export 'src/export/general_settings_export.dart';
export 'src/export/profile_export.dart';
export 'src/export/sight_export.dart';
export 'src/export/tables_settings_export.dart';
export 'src/export/unit_settings_export.dart';
export 'src/export/weapon_export.dart';
export 'objectbox.g.dart';

/// Opens (or creates) the ObjectBox store at [directory].
///
/// The caller is responsible for resolving an appropriate path
/// (e.g. via `getApplicationSupportDirectory()` from path_provider).
Future<Store> initObjectBox({required String directory}) async {
  await Directory(directory).create(recursive: true);
  return openStore(directory: directory);
}
