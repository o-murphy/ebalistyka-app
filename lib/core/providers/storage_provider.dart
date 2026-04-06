import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/storage/app_storage.dart';
import 'package:ebalistyka/core/storage/json_file_storage.dart';

final appStorageProvider = Provider<AppStorage>(
  (_) => JsonFileStorage.instance,
);
