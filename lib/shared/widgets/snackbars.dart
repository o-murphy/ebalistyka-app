import 'package:flutter/material.dart';

void showFeedback(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: isError ? colorScheme.error : null,
    ),
  );
}

void showNotAvailableSnackBar(BuildContext context, [String? feature]) {
  final message = feature != null
      ? '$feature not yet available'
      : 'Not yet available';
  showFeedback(context, message);
}
