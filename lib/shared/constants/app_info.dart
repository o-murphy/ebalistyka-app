import 'package:flutter/foundation.dart' show debugPrint;

const remoteUrl = 'https://github.com';
const remoteApiUrl = 'https://api.github.com';
const repoSlug = 'o-murphy/ebalistyka-app';
const defaultBranch = 'main';
const checkIntervalHours = 24;
const lastCheckFile = 'last_update_check';
const repoUrl = '$remoteUrl/$repoSlug';
const repoBlobUrl = '$repoUrl/blob/$defaultBranch';
const privacyPolicyUrl = '$repoBlobUrl/PRIVACY_POLICY.md';
const tosUrl = '$repoBlobUrl/TERMS.md';
const changelogUrl = '$repoBlobUrl/CHANGELOG.md';
const releasesUrl = '$remoteApiUrl/repos/$repoSlug/releases/latest';
const googlePlayinstallerSource = 'com.android.vending';
const collectionUrl = '$repoBlobUrl/assets/json/collection.json';
const lastCommitHashUrl =
    '$remoteApiUrl/repos/$repoSlug/commits?sha=$defaultBranch&per_page=1';

void debugAppInfoConstants() {
  debugPrint('=== DEBUG CONSTANTS ===');
  debugPrint('remoteUrl: $remoteUrl');
  debugPrint('remoteApiUrl: $remoteApiUrl');
  debugPrint('repoSlug: $repoSlug');
  debugPrint('defaultBranch: $defaultBranch');
  debugPrint('checkIntervalHours: $checkIntervalHours');
  debugPrint('lastCheckFile: $lastCheckFile');
  debugPrint('repoUrl: $repoUrl');
  debugPrint('repoBlobUrl: $repoBlobUrl');
  debugPrint('privacyPolicyUrl: $privacyPolicyUrl');
  debugPrint('tosUrl: $tosUrl');
  debugPrint('changelogUrl: $changelogUrl');
  debugPrint('releasesUrl: $releasesUrl');
  debugPrint('googlePlayinstallerSource: $googlePlayinstallerSource');
  debugPrint('collectionUrl: $collectionUrl');
  debugPrint('lastCommitHashUrl: $lastCommitHashUrl');
  debugPrint('=== END DEBUG CONSTANTS ===');
}
