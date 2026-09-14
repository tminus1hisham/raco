import 'dart:convert';

import 'package:atom/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'test-token'});
  });

  test('fetches current telemetry by encoded serial with authentication', () async {
    await http.runWithClient(() async {
      final device = await ApiService.fetchTrackingDevice('SN/123');
      expect(device.latitude, '-1.286389');
      expect(device.longitude, '36.817223');
      expect(device.speed, '45');
      expect(device.course, '270');
      expect(device.isDeviceOnline, isTrue);
    }, () => MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.pathSegments.last, 'SN/123');
      expect(request.url.path, contains('/devices/get/'));
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(jsonEncode({
        'latitude': '-1.286389',
        'longitude': '36.817223',
        'speed': '45',
        'course': '270',
        'isDeviceOnline': true,
      }), 200);
    }));
  });

  test('rejects missing serial numbers', () async {
    await expectLater(ApiService.fetchTrackingDevice(' '), throwsArgumentError);
  });

  test('surfaces API failures for retry status', () async {
    await http.runWithClient(() async {
      await expectLater(ApiService.fetchTrackingDevice('SN123'), throwsException);
    }, () => MockClient((_) async => http.Response('Unavailable', 503)));
  });
}
