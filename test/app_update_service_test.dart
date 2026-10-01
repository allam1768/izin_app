import 'package:flutter_test/flutter_test.dart';
import 'package:izin_app/src/features/app_update/application/app_update_service.dart';

void main() {
  group('AppUpdateService.isRemoteVersionNewer', () {
    test('returns true when remote major is higher', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v2.0.0',
          localVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('returns true when remote minor is higher', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: '1.1.0',
          localVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('returns true when remote patch is higher', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v1.0.1',
          localVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('returns false when remote is equal or lower', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v1.0.0',
          localVersion: '1.0.0',
        ),
        isFalse,
      );
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v0.9.9',
          localVersion: '1.0.0',
        ),
        isFalse,
      );
    });

    test('compares build numbers when versions are equal', () {
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: 'v1.0.0+2',
          localVersion: '1.0.0',
          localBuildNumber: 1,
        ),
        isTrue,
      );
      expect(
        AppUpdateService.isRemoteVersionNewer(
          remoteTag: '1.0.0+1',
          localVersion: '1.0.0',
          localBuildNumber: 1,
        ),
        isFalse,
      );
    });
  });
}
