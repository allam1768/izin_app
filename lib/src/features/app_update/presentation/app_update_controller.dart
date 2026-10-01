import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/app_update_service.dart';
import 'app_update_dialog.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

/// Controller untuk menangani alur pengecekan pembaruan aplikasi
class AppUpdateController {
  final AppUpdateService _service;

  AppUpdateController(this._service);

  /// Pengecekan pembaruan otomatis (misal saat aplikasi pertama kali dibuka)
  Future<void> checkOnStartup(BuildContext context) async {
    if (!context.mounted) return;

    final info = await _service.checkForUpdate();
    if (!context.mounted || info == null) return;

    if (info.isUpdateAvailable) {
      AppUpdateDialog.show(context, info);
    }
  }

  /// Pengecekan pembaruan secara manual oleh pengguna (misal klik tombol di AppBar/Pengaturan)
  Future<void> checkManually(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Memeriksa pembaruan aplikasi...'),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );

    final info = await _service.checkForUpdate();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (info == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal memeriksa pembaruan. Pastikan perangkat terhubung ke internet.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (info.isUpdateAvailable) {
      AppUpdateDialog.show(context, info);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Aplikasi Anda sudah versi terbaru (v${info.currentVersion}).',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

final appUpdateControllerProvider = Provider<AppUpdateController>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return AppUpdateController(service);
});
