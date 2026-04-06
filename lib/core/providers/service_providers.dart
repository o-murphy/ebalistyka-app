import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/domain/ballistics_service.dart';
import 'package:ebalistyka/core/services/ballistics_service_impl.dart';

final ballisticsServiceProvider = Provider<BallisticsService>((ref) {
  return BallisticsServiceImpl();
});
