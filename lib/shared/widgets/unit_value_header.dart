import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:flutter/material.dart';
import 'package:bclibc_ffi/unit.dart';

/// Reusable header widget showing current value and unit
class UnitValueHeader extends StatelessWidget {
  const UnitValueHeader({
    super.key,
    required this.isNullValue,
    required this.displayValue,
    required this.unit,
    required this.symbol,
    required this.errorText,
    this.accuracy,
  });

  final bool isNullValue;
  final double displayValue;
  final Unit unit;
  final String symbol;
  final String? errorText;
  final int? accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String displayHeader;
    Color headerColor;

    if (errorText != null) {
      displayHeader = 'Invalid';
      headerColor = theme.colorScheme.error;
    } else if (isNullValue) {
      displayHeader = nullStr;
      headerColor = theme.colorScheme.onSurfaceVariant;
    } else {
      final acc = accuracy ?? 2;
      displayHeader = displayValue.toStringAsFixed(acc);
      headerColor = theme.colorScheme.primary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          displayHeader,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: headerColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (errorText == null && !isNullValue) ...[
          const SizedBox(width: 6),
          Text(
            symbol,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}
