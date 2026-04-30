import 'dart:convert';
import 'dart:io';

import 'package:ebalistyka/shared/constants/app_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

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

/// Hits the GitHub API and returns the latest [GithubRelease] if it is newer
/// than [currentVersion], or null if already up-to-date / on error.
Future<GithubRelease?> _fetchIfNewer(
  String currentVersion, {
  required bool isPlayStore,
  required String packageName,
}) async {
  final response = await http
      .get(
        Uri.parse(releasesUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) return null;

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final tagName = (data['tag_name'] as String?) ?? '';
  final htmlUrl = (data['html_url'] as String?) ?? '';
  final prerelease = (data['prerelease'] as bool?) ?? false;

  final latestVersion = tagName.startsWith('v')
      ? tagName.substring(1)
      : tagName;
  if (!_isNewer(latestVersion, currentVersion)) return null;

  return GithubRelease(
    tagName: tagName,
    htmlUrl: htmlUrl,
    prerelease: prerelease,
    isPlayStore: isPlayStore,
    packageName: packageName,
  );
}

/// Hits the GitHub API unconditionally and resets the 24 h throttle timer.
/// Use this for manual checks.
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

/// Auto-check: skips the API call if it was already done within [_checkIntervalHours].
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

class CollectionCommit {
  final String sha;

  const CollectionCommit({required this.sha});
}

Future<CollectionCommit?> _fetchIfNewerCommit(
  String currentVersion, {
  required bool isPlayStore,
  required String packageName,
}) async {
  final response = await http
      .get(
        Uri.parse(lastCommitHashUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode != 200) return null;

  final data = jsonDecode(response.body) as List<dynamic>;
  if (data.isEmpty) return null;

  // Правильний спосіб отримати SHA коміту
  final firstCommit = data[0] as Map<String, dynamic>;
  final sha = firstCommit['sha'] as String? ?? '';

  return CollectionCommit(sha: sha);
}

Future<String> _fetchCollection(CollectionCommit commit) async {
  // Використовуємо константи для формування URL
  final String rawUrl = rawCollectionUrlPattern.replaceFirst('%s', commit.sha);
  final String apiUrl = apiCollectionUrlPattern.replaceFirst('%s', commit.sha);

  // Використовуємо raw URL як основний (швидше та простіше)
  // API URL залишаємо як резервний варіант або для особливих випадків

  try {
    // Спроба 1: Raw content (без авторизації, швидше)
    final response = await http
        .get(Uri.parse(rawUrl), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return response.body;
    }

    // Спроба 2: Якщо raw URL не спрацював, пробуємо API з raw header
    debugPrint('Raw URL failed with ${response.statusCode}, trying API URL...');

    final apiResponse = await http
        .get(
          Uri.parse(apiUrl),
          headers: {'Accept': 'application/vnd.github.raw+json'},
        )
        .timeout(const Duration(seconds: 10));

    if (apiResponse.statusCode != 200) {
      throw Exception(
        'Failed to fetch collection via API: ${apiResponse.statusCode}',
      );
    }

    return apiResponse.body;
  } catch (e) {
    debugPrint('Error fetching collection: $e');
    rethrow;
  }
}
