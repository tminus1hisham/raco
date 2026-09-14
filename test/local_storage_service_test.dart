import 'package:atom/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService.getInt', () {
    test('reads an integer value', () async {
      SharedPreferences.setMockInitialValues({'userDbId': 42});

      expect(await StorageService.getInt('userDbId'), 42);
    });

    test('reads the numeric string used by technician login', () async {
      SharedPreferences.setMockInitialValues({'userDbId': '42'});

      expect(await StorageService.getInt('userDbId'), 42);
    });

    test('returns null for a missing or invalid value', () async {
      SharedPreferences.setMockInitialValues({'userDbId': 'not-an-id'});

      expect(await StorageService.getInt('userDbId'), isNull);
      expect(await StorageService.getInt('missing'), isNull);
    });
  });
}
