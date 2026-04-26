import 'package:ebalistyka/l10n/app_localizations.dart';

class GenericConvertorField {
  final String Function(AppLocalizations) labelBuilder;
  final String formattedValue;
  final double value;
  final String symbol;
  final int decimals;

  const GenericConvertorField({
    required this.labelBuilder,
    required this.formattedValue,
    required this.value,
    required this.symbol,
    required this.decimals,
  });
}
