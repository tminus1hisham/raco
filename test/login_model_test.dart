import 'package:atom/models/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginModel', () {
    test('serializes the login payload with the Firebase token', () {
      final payload = LoginModel(
        phoneNumber: '+254712345678',
        password: 'secret-password',
        firebaseToken: 'fcm-token',
        deviceModel: 'Google',
        userAgent: 'Pixel 8',
        location: 'Nairobi',
        ipAddress: '127.0.0.1',
      ).toJson();

      expect(payload, {
        'phoneNumber': '+254712345678',
        'password': 'secret-password',
        'firebaseToken': 'fcm-token',
        'deviceModel': 'Google',
        'userAgent': 'Pixel 8',
        'location': 'Nairobi',
        'ipAddress': '127.0.0.1',
      });
    });
  });
}
