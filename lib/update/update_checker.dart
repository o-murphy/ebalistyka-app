import 'dart:convert';
import 'dart:io';

import 'package:ebalistyka/core/collection/collection_parser.dart';
import 'package:ebalistyka/core/providers/builtin_collection_provider.dart';
import 'package:ebalistyka/shared/constants/app_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

// ── App update ────────────────────────────────────────────────────────────────

Future<bool> checkIsNewVersion() async {
  final info = await PackageInfo.fromPlatform();
  final currentVersion = info.version;

  final appSupport = await getApplicationSupportDirectory();
  final file = File('${appSupport.path}/$versionFile');

  debugPrint('===== CHECK IS NEW VERSION =====');
  debugPrint('Path: ${file.path}');
  debugPrint('Current version: $currentVersion');

  final exists = await file.exists();
  debugPrint('Exists: $exists');

  if (exists) {
    final savedVersion = await file.readAsString();
    debugPrint('Saved version: "$savedVersion"');

    if (savedVersion.trim() == currentVersion) {
      debugPrint('→ Version matches, NOT first run');
      return false; // версія співпадає -> не перший запуск
    } else {
      debugPrint(
        '→ Version mismatch (saved: "$savedVersion", current: "$currentVersion"), updating and RETURN true',
      );
      await file.writeAsString(currentVersion);
      return true;
    }
  } else {
    debugPrint(
      '→ File not exists, creating with version "$currentVersion" and RETURN true',
    );
    await file.writeAsString(currentVersion);
    return true;
  }
}

class GithubRelease {
  final String tagName;
  final String htmlUrl;
  final bool prerelease;
  final bool isPlayStore;
  final String packageName;

  const GithubRelease({
    required this.tagName,
    required this.htmlUrl,
    required this.prerelease,
    required this.isPlayStore,
    required this.packageName,
  });
}

class _ParsedRelease {
  final String tagName;
  final String htmlUrl;
  final bool prerelease;
  final List<int> versionNumbers;

  _ParsedRelease({
    required this.tagName,
    required this.htmlUrl,
    required this.prerelease,
    required this.versionNumbers,
  });
}

Future<GithubRelease?> _fetchIfNewer(
  String currentVersion, {
  required bool isPlayStore,
  required String packageName,
}) async {
  final response = await http
      .get(
        Uri.parse(allReleasesUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) return null;

  final List<dynamic> releases = jsonDecode(response.body);

  final parsedReleases = <_ParsedRelease>[];
  for (final release in releases) {
    final isPrerelease = release['prerelease'] as bool? ?? false;

    if (!kDebugMode && isPrerelease) continue;

    final tagName = release['tag_name'] as String? ?? '';
    final versionStr = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final versionNumbers = _parseSemver(versionStr);

    if (versionNumbers != null) {
      parsedReleases.add(
        _ParsedRelease(
          tagName: tagName,
          htmlUrl: release['html_url'] as String? ?? '',
          prerelease: isPrerelease,
          versionNumbers: versionNumbers,
        ),
      );
    }
  }

  parsedReleases.sort((a, b) {
    for (var i = 0; i < 3; i++) {
      if (a.versionNumbers[i] != b.versionNumbers[i]) {
        return b.versionNumbers[i].compareTo(a.versionNumbers[i]);
      }
    }
    return 0;
  });

  if (parsedReleases.isEmpty) return null;

  final latestRelease = parsedReleases.first;
  final latestVersion =
      '${latestRelease.versionNumbers[0]}.${latestRelease.versionNumbers[1]}.${latestRelease.versionNumbers[2]}';

  if (!_isNewer(latestVersion, currentVersion)) return null;

  return GithubRelease(
    tagName: latestRelease.tagName,
    htmlUrl: latestRelease.htmlUrl,
    prerelease: latestRelease.prerelease,
    isPlayStore: isPlayStore,
    packageName: packageName,
  );
}

/// Manual app update check. Resets the 24 h throttle timer.
Future<GithubRelease?> checkForUpdate() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final isPlayStore = info.installerStore == googlePlayinstallerSource;
    final result = await _fetchIfNewer(
      info.version,
      isPlayStore: isPlayStore,
      packageName: info.packageName,
    );
    final appSupport = await getApplicationSupportDirectory();
    await File(
      '${appSupport.path}/$lastUpdateCheckFile',
    ).writeAsString(DateTime.now().toIso8601String());
    return result;
  } catch (e) {
    debugPrint('Manual update check failed: $e');
    return null;
  }
}

/// Auto-check: skips the API call if already done within [checkIntervalHours].
final updateCheckerProvider = FutureProvider<GithubRelease?>((ref) async {
  try {
    final appSupport = await getApplicationSupportDirectory();
    final checkFile = File('${appSupport.path}/$lastUpdateCheckFile');

    if (await checkFile.exists()) {
      final lastCheck = DateTime.tryParse(
        (await checkFile.readAsString()).trim(),
      );
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck).inHours < checkIntervalHours) {
        return null;
      }
    }

    final info = await PackageInfo.fromPlatform();
    final isPlayStore = info.installerStore == googlePlayinstallerSource;
    await checkFile.writeAsString(DateTime.now().toIso8601String());
    return _fetchIfNewer(
      info.version,
      isPlayStore: isPlayStore,
      packageName: info.packageName,
    );
  } catch (e) {
    debugPrint('Update check failed: $e');
    return null;
  }
});

bool _isNewer(String latest, String current) {
  final l = _parseSemver(latest);
  final c = _parseSemver(current);
  if (l == null || c == null) return false;
  for (var i = 0; i < 3; i++) {
    if (l[i] > c[i]) return true;
    if (l[i] < c[i]) return false;
  }
  return false;
}

List<int>? _parseSemver(String v) {
  final parts = v.split('+').first.split('.');
  if (parts.length < 3) return null;
  final nums = parts.take(3).map(int.tryParse).toList();
  if (nums.any((n) => n == null)) return null;
  return nums.cast<int>();
}

// ── Collection update ─────────────────────────────────────────────────────────

class CollectionCommit {
  final String sha;
  const CollectionCommit({required this.sha});
}

Future<CollectionCommit?> _fetchLatestCollectionCommit() async {
  final response = await http
      .get(
        Uri.parse(lastCommitHashUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to fetch collection commits: ${response.statusCode}',
    );
  }

  final data = jsonDecode(response.body) as List<dynamic>;
  if (data.isEmpty) return null;

  final sha = (data[0] as Map<String, dynamic>)['sha'] as String? ?? '';
  if (sha.isEmpty) return null;
  return CollectionCommit(sha: sha);
}

Future<String> _fetchCollection(CollectionCommit commit) async {
  final rawUrl = rawCollectionUrlPattern.replaceFirst('%s', commit.sha);
  final apiUrl = apiCollectionUrlPattern.replaceFirst('%s', commit.sha);

  final response = await http
      .get(Uri.parse(rawUrl), headers: {'Accept': 'application/json'})
      .timeout(const Duration(seconds: 20));

  if (response.statusCode == 200) return response.body;

  debugPrint('Raw URL failed (${response.statusCode}), trying API…');
  final apiResponse = await http
      .get(
        Uri.parse(apiUrl),
        headers: {'Accept': 'application/vnd.github.raw+json'},
      )
      .timeout(const Duration(seconds: 20));

  if (apiResponse.statusCode != 200) {
    throw Exception('Failed to fetch collection: ${apiResponse.statusCode}');
  }
  return apiResponse.body;
}

/// Downloads a new collection if the remote SHA differs from the cached one.
/// Saves to disk and invalidates [builtinCollectionProvider] on success.
/// Returns true if updated, false if already up to date.
/// Throws on network / parse errors — caller is responsible for showing UI.
Future<bool> checkForCollectionUpdate(WidgetRef ref) async {
  final appSupport = await getApplicationSupportDirectory();
  final shaFile = File('${appSupport.path}/$lastCollectionSha');

  final savedSha = await shaFile.exists()
      ? (await shaFile.readAsString()).trim()
      : null;

  final commit = await _fetchLatestCollectionCommit();
  if (commit == null) return false;
  if (commit.sha == savedSha) return false;

  final json = await _fetchCollection(commit);
  CollectionParser.parse(json); // validate before caching; throws if invalid

  await File('${appSupport.path}/$collectionFile').writeAsString(json);
  await shaFile.writeAsString(commit.sha);
  ref.invalidate(builtinCollectionProvider);
  return true;
}

/// Throttled collection update: skips if checked within [checkIntervalHours].
/// Silently swallows errors — use [checkForCollectionUpdate] for manual checks.
Future<void> checkForCollectionUpdateThrottled(WidgetRef ref) async {
  try {
    final appSupport = await getApplicationSupportDirectory();
    final checkFile = File('${appSupport.path}/$lastCollectionCheckFile');

    if (await checkFile.exists()) {
      final lastCheck = DateTime.tryParse(
        (await checkFile.readAsString()).trim(),
      );
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck).inHours < checkIntervalHours) {
        return;
      }
    }

    await checkFile.writeAsString(DateTime.now().toIso8601String());
    await checkForCollectionUpdate(ref);
  } catch (e) {
    debugPrint('Collection auto-check failed: $e');
  }
}

/// The locally cached collection commit SHA, or null if using the bundled asset.
/// Re-evaluates whenever the collection is reloaded.
final collectionShaProvider = FutureProvider<String?>((ref) async {
  ref.watch(builtinCollectionProvider);
  final appSupport = await getApplicationSupportDirectory();
  final shaFile = File('${appSupport.path}/$lastCollectionSha');
  if (!await shaFile.exists()) return null;
  return (await shaFile.readAsString()).trim();
});
