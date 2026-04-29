import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const _repoSlug = 'o-murphy/ebalistyka-app';
const _checkIntervalHours = 24;
const _lastCheckFile = 'last_update_check';

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
        Uri.parse('https://api.github.com/repos/$_repoSlug/releases/latest'),
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
    final isPlayStore = info.installerStore == 'com.android.vending';
    final result = await _fetchIfNewer(
      info.version,
      isPlayStore: isPlayStore,
      packageName: info.packageName,
    );
    final appSupport = await getApplicationSupportDirectory();
    await File(
      '${appSupport.path}/$_lastCheckFile',
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
    final checkFile = File('${appSupport.path}/$_lastCheckFile');

    if (await checkFile.exists()) {
      final lastCheck = DateTime.tryParse(
        (await checkFile.readAsString()).trim(),
      );
      if (lastCheck != null &&
          DateTime.now().difference(lastCheck).inHours < _checkIntervalHours) {
        return null;
      }
    }

    final info = await PackageInfo.fromPlatform();
    final isPlayStore = info.installerStore == 'com.android.vending';
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
