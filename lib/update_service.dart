import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Details of an available update, read from the `app_meta/current`
/// document in Firestore.
class AppUpdate {
  final String version;
  final String apkUrl;
  final String description;
  final int? fileSize;
  final bool force;

  const AppUpdate({
    required this.version,
    required this.apkUrl,
    required this.description,
    this.fileSize,
    this.force = false,
  });
}

/// Checks Firestore for a published update and reports whether the installed
/// build is older than the published one.
class UpdateService {
  static const _metaDoc = 'app_meta/current';

  /// Returns an [AppUpdate] when a newer version is published, otherwise null.
  /// Any failure (offline, missing doc, bad data) silently returns null.
  Future<AppUpdate?> checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final installed = '${info.version}+${info.buildNumber}';

      final snap = await FirebaseFirestore.instance.doc(_metaDoc).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;

      final latest = data['version'] as String?;
      final apkUrl = data['apkUrl'] as String?;
      if (latest == null ||
          latest.isEmpty ||
          apkUrl == null ||
          apkUrl.isEmpty) {
        return null;
      }
      if (!UpdateService.needUpdate(installed, latest)) return null;

      return AppUpdate(
        version: latest,
        apkUrl: apkUrl,
        description: (data['description'] as String?) ??
            'A new version is available.',
        fileSize: data['fileSize'] as int?,
        force: data['force'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Compares `installed` and `published` in `major.minor.patch+build` form.
  /// Returns true only when the published version is newer than the installed.
  static bool needUpdate(String installed, String published) {
    final a = _parts(installed);
    final b = _parts(published);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return b[i] > a[i];
    }
    return b[3] > a[3];
  }

  static List<int> _parts(String version) {
    final hasBuild = version.contains('+');
    final versionPart = hasBuild ? version.split('+').first : version;
    final buildPart = hasBuild ? version.split('+').last : '0';
    final segments = versionPart.split('.');
    return [
      int.tryParse(segments.isNotEmpty ? segments[0] : '0') ?? 0,
      int.tryParse(segments.length > 1 ? segments[1] : '0') ?? 0,
      int.tryParse(segments.length > 2 ? segments[2] : '0') ?? 0,
      int.tryParse(buildPart) ?? 0,
    ];
  }
}