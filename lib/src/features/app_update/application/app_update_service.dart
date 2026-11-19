import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/models/app_update_info.dart';

class AppUpdateService {
  static const String githubOwner = 'allam1768';
  static const String githubRepo = 'izin_app';

  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// Memeriksa rilis terbaru dari GitHub repository
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // contoh: 1.0.0
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await http.get(
        Uri.parse(latestReleaseApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'izin_app-mobile',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final tagName = (data['tag_name'] as String? ?? '').trim();
        final releaseTitle = (data['name'] as String? ?? tagName).trim();
        final body = (data['body'] as String? ?? '').trim();
        final releaseUrl = (data['html_url'] as String? ?? '').trim();
        final publishedAtStr = data['published_at'] as String?;
        final publishedAt = publishedAtStr != null
            ? DateTime.tryParse(publishedAtStr)
            : null;

        // Cari file asset APK di dalam rilis
        String downloadUrl = '';
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final assetName = (asset['name'] as String? ?? '').toLowerCase();
          if (assetName.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String? ?? '';
            break;
          }
        }

        // Jika tidak ditemukan file .apk, fallback ke halaman rilis
        if (downloadUrl.isEmpty) {
          downloadUrl = releaseUrl;
        }

        final isNewer = isRemoteVersionNewer(
          remoteTag: tagName,
          localVersion: currentVersion,
          localBuildNumber: currentBuild,
        );

        final isForceUpdate = isNewer &&
            checkIsForceUpdate(
              title: releaseTitle,
              body: body,
              tagName: tagName,
            );

        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: tagName.replaceFirst(RegExp(r'^[vV]'), ''),
          title: releaseTitle.isNotEmpty ? releaseTitle : 'Versi $tagName',
          releaseNotes: body,
          downloadUrl: downloadUrl,
          releaseUrl: releaseUrl,
          publishedAt: publishedAt,
          isUpdateAvailable: isNewer,
          isForceUpdate: isForceUpdate,
        );
      } else if (response.statusCode == 404) {
        // Belum ada rilis di GitHub repository
        debugPrint('[AppUpdateService] Belum ada rilis di repository GitHub.');
        return AppUpdateInfo.upToDate(currentVersion: currentVersion);
      } else {
        debugPrint(
          '[AppUpdateService] GitHub API status code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[AppUpdateService] Error saat cek update: $e\n$stackTrace');
    }
    return null;
  }

  /// Mengecek apakah rilis ini merupakan pembaruan wajib / darurat (Force Update)
  static bool checkIsForceUpdate({
    required String title,
    required String body,
    String tagName = '',
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerBody = body.toLowerCase();
    final lowerTag = tagName.toLowerCase();
    const forceKeywords = [
      '[urgent]',
      '(urgent)',
      'urgent',
      'force update',
      '[force]',
      '(force)',
      '[mandatory]',
      '(mandatory)',
      '[wajib]',
      '(wajib)',
      'wajib update',
      'wajib perbarui',
      'pembaruan wajib',
    ];

    for (final kw in forceKeywords) {
      if (lowerTitle.contains(kw) ||
          lowerBody.contains(kw) ||
          lowerTag.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  /// Membandingkan versi remote dengan versi lokal
  /// Mendukung format seperti "v1.0.1", "1.0.1+2", dsb.
  static bool isRemoteVersionNewer({
    required String remoteTag,
    required String localVersion,
    int localBuildNumber = 0,
  }) {
    if (remoteTag.isEmpty) return false;

    // Bersihkan 'v' atau 'V' di depan
    String cleanRemote = remoteTag.replaceFirst(RegExp(r'^[vV]'), '').trim();
    String cleanLocal = localVersion.replaceFirst(RegExp(r'^[vV]'), '').trim();

    int remoteBuild = 0;
    if (cleanRemote.contains('+')) {
      final parts = cleanRemote.split('+');
      cleanRemote = parts[0];
      remoteBuild = int.tryParse(parts[1]) ?? 0;
    }

    int parsedLocalBuild = localBuildNumber;
    if (cleanLocal.contains('+')) {
      final parts = cleanLocal.split('+');
      cleanLocal = parts[0];
      if (parsedLocalBuild == 0) {
        parsedLocalBuild = int.tryParse(parts[1]) ?? 0;
      }
    }

    final remoteParts =
        cleanRemote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final localParts =
        cleanLocal.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = remoteParts.length > localParts.length
        ? remoteParts.length
        : localParts.length;

    for (int i = 0; i < maxLen; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final l = i < localParts.length ? localParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }

    // Jika komponen semver sama, bandingkan build number
    return remoteBuild > parsedLocalBuild;
  }

  /// Membuka tautan unduhan APK di browser eksternal
  static Future<bool> openDownloadUrl(String url) async {
    if (url.isEmpty) return false;
    final uri = Uri.parse(url);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[AppUpdateService] Gagal membuka URL: $e');
      return false;
    }
  }
}
