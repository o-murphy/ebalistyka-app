import 'package:ebalistyka/core/utils/string_utils.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void showFeedback(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
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
  final l10n = AppLocalizations.of(context)!;
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  final message = feature != null
      ? '"$feature" ${l10n.notYetAvaliable}'
      : l10n.notYetAvaliable.capitalize();

  final snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: 2),
    showCloseIcon: true,
  );

  scaffoldMessenger.showSnackBar(snackBar);
}
