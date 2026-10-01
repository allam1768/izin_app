import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateServiceProvider.overrideWithValue(FakeAppUpdateService()),
        ],
        child: const IzinApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Buat Surat Izin Kelas'), findsOneWidget);
  });
}
