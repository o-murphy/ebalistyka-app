import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

class HelpData {
  static const String homeScreen = 'homeScreen';
  static const String conditionsScreen = 'conditionsScreen';
}

Widget helpAction(BuildContext context, {String? title, String? helpId}) {
  return IconButton(
    onPressed: () => showHelpDialog(context, title: title, helpId: helpId),
    icon: Icon(IconDef.help),
  );
}

Future<void> showHelpDialog(
  BuildContext context, {
  String? title,
  String? helpId,
}) async {
  final l10n = AppLocalizations.of(context)!;

  if (helpId == null) {
    return showNotAvailableSnackBar(context, l10n.helpButton);
  }

  final String markdownContent;
  try {
    markdownContent = await rootBundle.loadString(
      'assets/markdown/${l10n.localeName}/$helpId.md',
    );
  } catch (e) {
    debugPrint(e.toString());
    return showNotAvailableSnackBar(context, l10n.helpButton);
  }

  if (!context.mounted) return;

  final actualTitle = (title ?? l10n.helpTitle);

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actualTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: Markdown(data: markdownContent, selectable: true),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.closeButton),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
