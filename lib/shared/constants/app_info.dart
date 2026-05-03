import 'package:flutter/foundation.dart' show debugPrint;

const String remoteUrl = 'https://github.com';
const String remoteApiUrl = 'https://api.github.com';
const String remoteRawContent = 'https://raw.githubusercontent.com';
const String repoSlug = 'o-murphy/ebalistyka-app';
const String defaultBranch = 'main';
const int checkIntervalHours = 24;
const String lastUpdateCheckFile = 'last_update_check';
const String lastCollectionCheckFile = 'last_collection_check';
const String versionFile = '.version';
const String lastCollectionSha = 'last_collection_sha';
const String collectionFile = 'collection.json';
const String repoUrl = '$remoteUrl/$repoSlug';
const String repoBlobUrl = '$repoUrl/blob/$defaultBranch';
const String privacyPolicyUrl = '$repoBlobUrl/PRIVACY_POLICY.md';
const String tosUrl = '$repoBlobUrl/TERMS.md';
const String changelogUrl = '$repoBlobUrl/CHANGELOG.md';
const String releasesUrl = '$remoteApiUrl/repos/$repoSlug/releases/latest';
const String allReleasesUrl = '$remoteApiUrl/repos/$repoSlug/releases';
const String googlePlayinstallerSource = 'com.android.vending';
const String rawCollectionUrlPattern =
    '$remoteRawContent/$repoSlug/%s/assets/json/collection.json';
const String apiCollectionUrlPattern =
    '$remoteApiUrl/repos/$repoSlug/contents/assets/json/collection.json?ref=%s';
const lastCommitHashUrl =
    '$remoteApiUrl/repos/$repoSlug/commits?sha=$defaultBranch&per_page=1';

void debugAppInfoConstants() {
  debugPrint('=== DEBUG CONSTANTS ===');
  debugPrint('remoteUrl: $remoteUrl');
  debugPrint('remoteApiUrl: $remoteApiUrl');
  debugPrint('repoSlug: $repoSlug');
  debugPrint('defaultBranch: $defaultBranch');
  debugPrint('checkIntervalHours: $checkIntervalHours');
  debugPrint('lastCheckFile: $lastUpdateCheckFile');
  debugPrint('repoUrl: $repoUrl');
  debugPrint('repoBlobUrl: $repoBlobUrl');
  debugPrint('privacyPolicyUrl: $privacyPolicyUrl');
  debugPrint('tosUrl: $tosUrl');
  debugPrint('changelogUrl: $changelogUrl');
  debugPrint('releasesUrl: $releasesUrl');
  debugPrint('googlePlayinstallerSource: $googlePlayinstallerSource');
  debugPrint('rawCollectionUrlPattern: $rawCollectionUrlPattern');
  debugPrint('apiCollectionUrlPattern: $apiCollectionUrlPattern');
  debugPrint('lastCommitHashUrl: $lastCommitHashUrl');
  debugPrint('=== END DEBUG CONSTANTS ===');
}
