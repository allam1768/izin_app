import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider status lisensi Pro untuk fitur Surat Izin (selalu aktif di aplikasi standalone)
final licenseControllerProvider =
    StateNotifierProvider<LicenseNotifier, AsyncValue<bool>>((ref) {
  return LicenseNotifier();
});

class LicenseNotifier extends StateNotifier<AsyncValue<bool>> {
  LicenseNotifier() : super(const AsyncValue.data(true));

  Future<bool> isLicenseActive() async => true;
}
