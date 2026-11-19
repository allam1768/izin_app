import 'package:flutter_test/flutter_test.dart';
import 'package:izin_app/src/features/app_update/application/app_update_service.dart';

void main() {
  group('AppUpdateService Tests', () {
    test('isRemoteVersionNewer correctly detects newer versions', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v1.1.0',
          localVersion: '1.0.0',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v1.0.0',
          localVersion: '1.1.0',
        ),
        isFalse,
      );
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v1.1.0',
          localVersion: '1.1.0',
        ),
        isFalse,
      );
    });

    test('checkIsForceUpdate correctly detects urgent releases', () {
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: '[URGENT] Release v1.1.0',
          body: 'Pembaruan ini wajib',
        ),
        isTrue,
      );
      expect(
        AppUpdateService.checkIsForceUpdate(
          title: 'Release v1.1.0',
          body: 'Fitur baru tanpa kata kunci darurat',
        ),
        isFalse,
      );
    });
  });
}
