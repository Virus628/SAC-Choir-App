/// Central app configuration.
///
/// Consider moving [updateDownloadUrl] to Firebase Remote Config so updates
/// can be pushed without releasing a new build for future iterations.
class AppConfig {
  /// Public link users open to download the latest app build.
  ///
  /// This is a Google Drive folder today. Serves as a stopgap — the more
  /// reliable long-term approach is Firebase App Distribution or GitLab/GitHub
  /// Releases + Remote Config.
  static const String updateDownloadUrl =
      'https://drive.google.com/drive/folders/1AwmsFcNHxD3TjScqpx_839PJEiPQgOqN?usp=drive_link';
}