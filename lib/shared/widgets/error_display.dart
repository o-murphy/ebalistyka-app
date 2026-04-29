import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final Object error;

  const ErrorDisplay({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(child: Text('${l10n.error}: $error'));
  }
}
