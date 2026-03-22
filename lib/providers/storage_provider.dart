import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_storage.dart';
import '../storage/json_file_storage.dart';

final appStorageProvider = Provider<AppStorage>(
  (_) => JsonFileStorage.instance,
);
