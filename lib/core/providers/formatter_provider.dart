import 'package:riverpod/riverpod.dart';

import 'package:ebalistyka/core/formatting/unit_formatter.dart';
import 'package:ebalistyka/core/formatting/unit_formatter_impl.dart';
import 'package:ebalistyka/core/providers/settings_provider.dart';

final unitFormatterProvider = Provider<UnitFormatter>((ref) {
  final units = ref.watch(unitSettingsProvider);
  final l10n = ref.watch(appLocalizationsProvider);
  return UnitFormatterImpl(units, l10n);
});
