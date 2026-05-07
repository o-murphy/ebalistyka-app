import 'dart:async';
import 'dart:io';

import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/app_info.dart';
import 'package:ebalistyka/update/update_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:url_launcher/url_launcher.dart';

void showPrereleaseWarningSheet(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PrereleaseWarningSheet(onConfirm: onConfirm),
    ),
  );
}

void showUpdateBottomSheet(BuildContext context, GithubRelease release) {
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _UpdateSheet(release: release),
    ),
  );
}

/// Wraps the shell widget tree. On first mount:
///  - listens for app-update notifications (via [updateCheckerProvider])
///  - fires a throttled collection-update check in the background
class UpdateListener extends ConsumerStatefulWidget {
  const UpdateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateListener> createState() => _UpdateListenerState();
}

class _UpdateListenerState extends ConsumerState<UpdateListener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(checkForCollectionUpdateThrottled(ref));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<GithubRelease?>>(updateCheckerProvider, (_, next) {
      final release = next.value;
      if (release == null) return;
      showUpdateBottomSheet(context, release);
    });
    return widget.child;
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

enum _DownloadStatus { idle, downloading, installing, error }

class _UpdateSheet extends StatefulWidget {
  const _UpdateSheet({required this.release});

  final GithubRelease release;

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  _DownloadStatus _status = _DownloadStatus.idle;
  int _progress = 0;
  StreamSubscription<OtaEvent>? _sub;

  bool get _canSideload =>
      Platform.isAndroid &&
      !widget.release.isPlayStore &&
      widget.release.apkUrl != null;

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _status = _DownloadStatus.downloading;
      _progress = 0;
    });
    _sub = OtaUpdate()
        .execute(widget.release.apkUrl!, destinationFilename: 'ebalistyka.apk')
        .listen(
          (OtaEvent event) {
            if (!mounted) return;
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                setState(() {
                  _status = _DownloadStatus.downloading;
                  _progress = int.tryParse(event.value ?? '0') ?? 0;
                });
              case OtaStatus.INSTALLING:
                setState(() => _status = _DownloadStatus.installing);
              case OtaStatus.INSTALLATION_DONE:
                Navigator.of(context).pop();
              case OtaStatus.CANCELED:
                setState(() => _status = _DownloadStatus.idle);
              default:
                setState(() => _status = _DownloadStatus.error);
            }
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _status = _DownloadStatus.error);
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);
    final l10n = AppLocalizations.of(context)!;
    final version = widget.release.tagName.startsWith('v')
        ? widget.release.tagName.substring(1)
        : widget.release.tagName;

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
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.system_update_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.updateAvailable(version),
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _canSideload
                  ? _SideloadButton(
                      status: _status,
                      progress: _progress,
                      l10n: l10n,
                      onTap:
                          _status == _DownloadStatus.idle ||
                              _status == _DownloadStatus.error
                          ? _startDownload
                          : null,
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.open_in_new_outlined),
                      label: Text(switch (widget.release) {
                        _ when widget.release.isSnap =>
                          l10n.openInSnapStoreAction,
                        _ when widget.release.isFlatpak =>
                          l10n.openInFlathubAction,
                        _ when widget.release.isPlayStore =>
                          l10n.openInPlayStoreAction,
                        _ => l10n.viewReleaseAction,
                      }),
                      onPressed: () {
                        Navigator.of(context).pop();
                        final url = switch (widget.release) {
                          _ when widget.release.isSnap => Uri.parse(
                            snapStoreUrl,
                          ),
                          _ when widget.release.isFlatpak => Uri.parse(
                            flathubUrl,
                          ),
                          _ when widget.release.isPlayStore => Uri.parse(
                            'https://play.google.com/store/apps/details?id=${widget.release.packageName}',
                          ),
                          _ => Uri.parse(widget.release.htmlUrl),
                        };
                        unawaited(
                          launchUrl(url, mode: LaunchMode.externalApplication),
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

class _SideloadButton extends StatelessWidget {
  const _SideloadButton({
    required this.status,
    required this.progress,
    required this.l10n,
    required this.onTap,
  });

  final _DownloadStatus status;
  final int progress;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      _DownloadStatus.idle => FilledButton.icon(
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.downloadAndInstallAction),
        onPressed: onTap,
      ),
      _DownloadStatus.downloading => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.downloadingUpdate(progress),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress / 100),
        ],
      ),
      _DownloadStatus.installing => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(l10n.installingUpdate),
        ],
      ),
      _DownloadStatus.error => FilledButton.icon(
        icon: const Icon(Icons.refresh_outlined),
        label: Text(l10n.downloadFailed),
        onPressed: onTap,
      ),
    };
  }
}

class _PrereleaseWarningSheet extends StatelessWidget {
  const _PrereleaseWarningSheet({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (cs, tt) = (theme.colorScheme, theme.textTheme);
    final l10n = AppLocalizations.of(context)!;

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
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(Icons.warning_amber_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              l10n.prereleaseWarningTitle,
              style: tt.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.prereleaseWarningBody,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: Text(l10n.prereleaseConfirmAction),
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
