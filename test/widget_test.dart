import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:izin_app/main.dart';
import 'package:izin_app/src/features/app_update/application/app_update_service.dart';
import 'package:izin_app/src/features/app_update/domain/models/app_update_info.dart';
import 'package:izin_app/src/features/app_update/presentation/app_update_controller.dart';

class FakeAppUpdateService extends AppUpdateService {
  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    return null;
  }
}

void main() {
  testWidgets('IzinApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateServiceProvider.overrideWithValue(FakeAppUpdateService()),
        ],
        child: const IzinApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Surat Izin Mahasiswa'), findsOneWidget);
  });
}
