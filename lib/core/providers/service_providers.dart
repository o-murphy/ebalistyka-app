import 'package:riverpod/riverpod.dart';

import 'package:eballistica/core/domain/ballistics_service.dart';
import 'package:eballistica/core/services/ballistics_service_impl.dart';

final ballisticsServiceProvider = Provider<BallisticsService>((ref) {
  return BallisticsServiceImpl();
});
