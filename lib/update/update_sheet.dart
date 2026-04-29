import 'dart:async';

import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/update/update_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

void showUpdateBottomSheet(BuildContext context, GithubRelease release) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UpdateSheet(release: release),
    ),
  );
}

class UpdateListener extends ConsumerWidget {
  const UpdateListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<GithubRelease?>>(updateCheckerProvider, (_, next) {
      final release = next.value;
      if (release == null) return;
      showUpdateBottomSheet(context, release);
    });
    return child;
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({required this.release});

  final GithubRelease release;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = release.tagName.startsWith('v')
        ? release.tagName.substring(1)
        : release.tagName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.system_update_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.updateAvailable(version),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_new_outlined),
                label: Text(l10n.viewReleaseAction),
                onPressed: () {
                  Navigator.of(context).pop();
                  unawaited(
                    launchUrl(
                      Uri.parse(release.htmlUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
