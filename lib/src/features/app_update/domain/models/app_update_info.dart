/// Model data informasi pembaruan aplikasi
class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String title;
  final String releaseNotes;
  final String downloadUrl;
  final String releaseUrl;
  final DateTime? publishedAt;
  final bool isUpdateAvailable;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.title,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.releaseUrl,
    this.publishedAt,
    required this.isUpdateAvailable,
  });

  factory AppUpdateInfo.upToDate({required String currentVersion}) {
    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      title: '',
      releaseNotes: '',
      downloadUrl: '',
      releaseUrl: '',
      isUpdateAvailable: false,
    );
  }
}
