import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/icons_definitions.dart';
import 'package:ebalistyka/shared/widgets/snackbars.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class HelpData {
  static const String firstRun = 'firstRun';
  static const String homeScreen = 'homeScreen';
  static const String conditionsScreen = 'conditionsScreen';
  static const String tablesScreen = 'tablesScreen';
  static const String settingsScreen = 'settingsScreen';
  static const String convertorsScreen = 'convertorsScreen';
  static const String velocityConvertor = 'velocityConvertor';
  static const String targetDistanceConvertor = 'targetDistanceConvertor';
  static const String angularConvertor = 'angularConvertor';
  static const String reticleScreen = 'reticleScreen';
  static const String profilesScreen = 'profilesScreen';
  static const String weaponCollectionScreen = 'weaponCollectionScreen';
  static const String ammoCollectionScreen = 'ammoCollectionScreen';
  static const String sightCollectionScreen = 'sightCollectionScreen';
  static const String mySightsScreen = 'mySightsScreen';
  static const String myAmmoScreen = 'myAmmoScreen';
  static const String multiBcEditor = 'multiBcEditor';
  static const String customDragEditor = 'customDragEditor';
  static const String powderSensEditor = 'powderSensEditor';

  final String title;
  final String body;

  const HelpData._({required this.title, required this.body});

  static Future<HelpData?> load(String id, AppLocalizations l10n) async {
    for (final locale in [l10n.localeName, 'en']) {
      try {
        final markdown = await rootBundle.loadString(
          'assets/markdown/$locale/$id.md',
        );
        return _parse(markdown, l10n.helpTitle);
      } catch (_) {}
    }
    debugPrint('HelpData: no markdown found for "$id"');
    return null;
  }

  static HelpData _parse(String markdown, String fallbackTitle) {
    final re = RegExp(r'^#{1,6}\s+(.+)$', multiLine: true);
    final match = re.firstMatch(markdown);
    if (match == null) return HelpData._(title: fallbackTitle, body: markdown);
    return HelpData._(
      title: match.group(1)!.trim(),
      body: markdown.replaceFirst(match.group(0)!, '').trimLeft(),
    );
  }
}

Widget helpAction(BuildContext context, {String? helpId}) {
  return IconButton(
    onPressed: () => showHelpDialog(context, helpId: helpId),
    icon: Icon(IconDef.help),
  );
}

Future<void> showHelpDialog(BuildContext context, {String? helpId}) async {
  final l10n = AppLocalizations.of(context)!;

  if (helpId == null) {
    return showNotAvailableSnackBar(context, l10n.helpButton);
  }

  final data = await HelpData.load(helpId, l10n);

  if (!context.mounted) return;

  if (data == null) {
    return showNotAvailableSnackBar(context, l10n.helpButton);
  }

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.all(24),
        title: Text(data.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(child: MarkdownBody(data: data.body)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.closeButton),
          ),
        ],
      );
    },
  );
}
