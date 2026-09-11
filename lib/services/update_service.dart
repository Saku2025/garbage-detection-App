import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool updateAvailable;
  final String currentVersion;
  final String latestVersion;
  final String downloadUrl;
  final String releaseNotes;

  const UpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static const String _repositoryOwner = 'Saku2025';
  static const String _repositoryName = 'garbage-detection-App';

  static const String _latestReleaseUrl =
      'https://api.github.com/repos/'
      '$_repositoryOwner/$_repositoryName/releases/latest';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // ----------------------------------------------------------
      // GET CURRENT APP VERSION
      // ----------------------------------------------------------
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion = packageInfo.version;

      // ----------------------------------------------------------
      // GET LATEST GITHUB RELEASE
      // ----------------------------------------------------------
      final response = await http.get(
        Uri.parse(_latestReleaseUrl),
        headers: const {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Example GitHub tag:
      // v1.1.0
      final tagName = data['tag_name']?.toString() ?? '';

      if (tagName.isEmpty) {
        return null;
      }

      final latestVersion = _cleanVersion(tagName);

      // ----------------------------------------------------------
      // FIND APK
      // ----------------------------------------------------------
      final assets = data['assets'];

      if (assets is! List) {
        return null;
      }

      String? downloadUrl;

      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) {
          continue;
        }

        final name = asset['name']?.toString() ?? '';

        if (name.toLowerCase().endsWith('.apk')) {
          downloadUrl = asset['browser_download_url']?.toString();
          break;
        }
      }

      if (downloadUrl == null || downloadUrl.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // RELEASE NOTES
      // ----------------------------------------------------------
      final releaseNotes = data['body']?.toString().trim() ?? '';

      // ----------------------------------------------------------
      // COMPARE VERSIONS
      // ----------------------------------------------------------
      final updateAvailable = _isNewerVersion(latestVersion, currentVersion);

      return UpdateInfo(
        updateAvailable: updateAvailable,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
      );
    } catch (_) {
      // Update checking should NEVER crash the app.
      return null;
    }
  }

  // ============================================================
  // REMOVE "v" FROM VERSION
  // ============================================================

  static String _cleanVersion(String version) {
    return version.trim().replaceFirst(RegExp(r'^v', caseSensitive: false), '');
  }

  // ============================================================
  // VERSION COMPARISON
  // ============================================================

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);

    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      }

      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  static List<int> _versionParts(String version) {
    final cleaned = _cleanVersion(version);

    final parts = cleaned.split('.');

    return List<int>.generate(3, (index) {
      if (index >= parts.length) {
        return 0;
      }

      return int.tryParse(parts[index].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    });
  }
}
