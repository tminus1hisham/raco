import 'package:atom/services/auth_service.dart';
import 'package:atom/services/local_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService.logoutUser', () {
    test('clears persisted auth data and keeps non-auth preferences', () async {
      SharedPreferences.setMockInitialValues({
        'isLoggedin': true,
        'access_token': 'access-token',
        'refreshToken': 'refresh-token',
        'phone': '+254712345678',
        'userId': 7,
        'userName': 'Orca User',
        'userRole': 'Admin',
        'userDbId': '42',
        'agentId': '12',
        'agentName': 'Tech Agent',
        'agentEmail': 'agent@example.com',
        'agentPhone': '+254700000000',
        'businessReg': 'BRN-001',
        'agentLocation': 'Nairobi',
        'theme_mode': 'dark',
      });

      final success = await AuthService().logoutUser();

      expect(success, isTrue);
      expect(await StorageService.getData('isLoggedin'), isFalse);
      expect(await StorageService.getData('access_token'), isNull);
      expect(await StorageService.getData('refreshToken'), isNull);
      expect(await StorageService.getData('userId'), isNull);
      expect(await StorageService.getData('userName'), isNull);
      expect(await StorageService.getData('userRole'), isNull);
      expect(await StorageService.getData('userDbId'), isNull);
      expect(await StorageService.getData('agentId'), isNull);
      expect(await StorageService.getData('agentName'), isNull);
      expect(await StorageService.getData('agentEmail'), isNull);
      expect(await StorageService.getData('agentPhone'), isNull);
      expect(await StorageService.getData('businessReg'), isNull);
      expect(await StorageService.getData('agentLocation'), isNull);
      expect(await StorageService.getData('phone'), '+254712345678');
      expect(await StorageService.getData('theme_mode'), 'dark');
    });
  });
}
