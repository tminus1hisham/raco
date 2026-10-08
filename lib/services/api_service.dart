import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:atom/models/notification_permission.dart';

import 'package:flutter/foundation.dart';

import 'package:atom/config/constants.dart';
import 'package:atom/models/geofence_model.dart';
import 'package:atom/models/driver_behaviour_model.dart';
import 'package:atom/models/location_model.dart';
import 'package:atom/models/plans_model.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/models/profile_picture_model.dart';
import 'package:atom/models/report_model.dart';
import 'package:atom/models/technician_device_model.dart';
import 'package:atom/models/ticket_model.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/models/user_model.dart';
import 'package:atom/models/company_model.dart';
import 'package:atom/views/auth/login_screen.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/delete_account_model.dart';
import 'local_storage_service.dart';
import 'mqtt_client.dart';

class ApiService {
  static Future<void> _notificationUpdate = Future.value();

  Future<void> _queueNotificationUpdate(Future<void> Function() update) {
    final operation = _notificationUpdate.then((_) => update());
    _notificationUpdate = operation.catchError((_) {});
    return operation;
  }

  /// Preserve the account fields required by the documented full-user update.
  Future<void> registerFirebaseToken(String firebaseToken) =>
      _queueNotificationUpdate(() => _registerFirebaseToken(firebaseToken));

  Future<void> _registerFirebaseToken(String firebaseToken) async {
    final account = await fetchUserData();
    if (account == null) throw Exception('Unable to load account');
    if (account['firebaseToken'] == firebaseToken) return;
    final token = await StorageService.getData('access_token');
    final response = await http
        .put(
          Uri.parse('$BASE_URL/auth/update/user'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({...account, 'firebaseToken': firebaseToken}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      _handleAuthError(response.statusCode);
      throw Exception('Unable to register device for notifications');
    }
    final result = jsonDecode(response.body);
    if (result is! Map || result['success'] != true) {
      throw Exception('Unable to register device for notifications');
    }
  }

  Future<Map<NotificationPermission, bool>>
  fetchNotificationPermissions() async {
    final token = await StorageService.getData('access_token');
    final response = await http
        .get(
          Uri.parse('$BASE_URL/communications/get/notifications/status'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      _handleAuthError(response.statusCode);
      throw Exception('Notification settings are unavailable');
    }
    try {
      return parseNotificationPermissions(jsonDecode(response.body));
    } catch (_) {
      throw Exception('Notification settings are unavailable');
    }
  }

  @visibleForTesting
  static Map<NotificationPermission, bool> parseNotificationPermissions(
    dynamic decoded,
  ) {
    final source = _findNotificationStatusSource(decoded);
    if (source == null) {
      throw const FormatException('Missing notification settings');
    }
    return {
      for (final permission in NotificationPermission.values)
        permission: _readRequiredNotificationBool(source, permission),
    };
  }

  static Map<String, dynamic>? _findNotificationStatusSource(dynamic value) {
    if (value is Map<String, dynamic>) {
      final hasAllFields = NotificationPermission.values.every(
        (permission) => _readNotificationBool(value[permission.field]) != null,
      );
      if (hasAllFields) return value;

      for (final key in const [
        'data',
        'notifications',
        'notificationStatus',
        'notificationStatuses',
        'status',
        'result',
        'message',
      ]) {
        final nested = _findNotificationStatusSource(value[key]);
        if (nested != null) return nested;
      }
    }
    if (value is List && value.isNotEmpty) {
      for (final item in value) {
        final nested = _findNotificationStatusSource(item);
        if (nested != null) return nested;
      }
    }
    if (value is String && value.trim().startsWith('{')) {
      try {
        return _findNotificationStatusSource(jsonDecode(value));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static bool _readRequiredNotificationBool(
    Map<String, dynamic> source,
    NotificationPermission permission,
  ) {
    final value = _readNotificationBool(source[permission.field]);
    if (value == null) {
      throw FormatException('Missing ${permission.field}');
    }
    return value;
  }

  static bool? _readNotificationBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  Future<void> updateNotificationPermission(
    NotificationPermission permission,
    bool enabled,
  ) => _queueNotificationUpdate(
    () => _updateNotificationPermission(permission, enabled),
  );

  Future<void> _updateNotificationPermission(
    NotificationPermission permission,
    bool enabled,
  ) async {
    final token = await StorageService.getData('access_token');
    final response = await http
        .put(
          Uri.parse(
            '$BASE_URL/communications/update/${permission.path}/notifications',
          ).replace(queryParameters: {'status': enabled.toString()}),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      _handleAuthError(response.statusCode);
      throw Exception('Unable to update notification settings');
    }
    final result = jsonDecode(response.body);
    if (result is! Map || result['success'] != true) {
      throw Exception('Unable to update notification settings');
    }
  }

  static void _handleAuthError(int statusCode) async {
    if (statusCode == 403 || statusCode == 401) {
      Get.offAll(() => LoginScreen());
    }
  }

  static String generateBookingId({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<Map<String, dynamic>?> fetchUserData() async {
    String token = await StorageService.getData('access_token');
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/auth/get/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to fetch user data');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during fetching the user data: $e');
    }
  }

  Future<Map<String, dynamic>?> updateProfilePicture(
    ProfilePictureModel request,
  ) async {
    String token = await StorageService.getData('access_token');
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/update/profile/picture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to update profile picture');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred when changing profile picture: $e');
    }
  }

  /// Latest telemetry from the documented Devices_GetDeviceById endpoint.
  static Future<Device> fetchTrackingDevice(String serialNumber) async {
    if (serialNumber.trim().isEmpty) {
      throw ArgumentError('Vehicle serial number is missing');
    }
    final token = await StorageService.getData('access_token');
    final response = await http
        .get(
          Uri.parse(
            '$base_url/devices/get/${Uri.encodeComponent(serialNumber.trim())}',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      _handleAuthError(response.statusCode);
      throw Exception(
        'Unable to refresh vehicle location (${response.statusCode})',
      );
    }
    return Device.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<DevicesModel> fetchDevices() async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse('$base_url/devices/get/vehicles/dashboard?company=All'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    // debugPrint(
    //   '[fetchDevices] status: ${response.statusCode}, body: ${response.body}',
    // );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DevicesModel.fromJson(data);
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load devices');
    }
  }

  static Future<CompanyModel> fetchCompanies() async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse('$base_url/devices/get/companies'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Handle the raw list response: [{"fullName":"...", "phoneNumber":"..."}]
      if (data is List) {
        // Convert the raw list to CompanyModel
        return CompanyModel(
          success: true,
          message: 'Success',
          data: data
              .map((companyJson) => Company.fromJson(companyJson))
              .toList(),
        );
      }
      // If the response is not a list, throw an error or handle accordingly
      else {
        return CompanyModel(
          success: false,
          message: 'Unexpected response format',
          data: [],
        );
      }
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load companies');
    }
  }

  static Future<List<UserModel>> fetchUsers() async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse('$BASE_URL/auth/get/users'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => UserModel.fromJson(e)).toList();
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load users');
    }
  }

  static Future<List<DeviceRecord>> fetchDeviceHistory(
    String numberPlate,
    String startDate,
    String endDate,
  ) async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse(
        '$base_url/devices/get/tracking/history?numberPlate=$numberPlate&startDate=$startDate&endDate=$endDate',
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final dataPoints = decoded['dataPoints'] as List<dynamic>;
      return DeviceRecord.fromJsonList(dataPoints);
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load history');
    }
  }

  static Future<Map<String, dynamic>> fetchViolations(
    String numberPlate,
    String startDate,
    String endDate,
    String violationType,
  ) async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse(
        '$base_url/devices/get/violations?numberPlate=$numberPlate&startDate=$startDate&endDate=$endDate&violationType=$violationType',
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List<dynamic> data = decoded['devices'] ?? [];
      final String? reportUrl = decoded['reportUrl'];

      return {
        "devices": DeviceRecord.fromJsonList(data),
        "reportUrl": reportUrl,
      };
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load violations');
    }
  }

  static Future<Map<String, dynamic>> fetchReports(
    String numberPlate,
    String reportType,
  ) async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse(
        '$base_url/devices/get/tracking/reports?numberPlate=$numberPlate&reportType=$reportType',
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final List<dynamic> data = decoded['devices'] ?? [];
      final String? reportUrl = decoded['reportUrl'];

      return {
        "devices": ReportModel.fromJsonList(data),
        "reportUrl": reportUrl,
      };
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load reports');
    }
  }

  static Future<DriverBehaviourReport> fetchDriverBehaviour({
    required String serialNo,
    required String reportType,
  }) async {
    final token = await StorageService.getData('access_token');
    final uri = Uri.parse('$base_url/devices/get/driver/behaviour').replace(
      queryParameters: {'serialNo': serialNo.trim(), 'reportType': reportType},
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return DriverBehaviourReport.fromJson(const <String, dynamic>{});
        }
        return DriverBehaviourReport.fromJson(jsonDecode(response.body));
      }

      _handleAuthError(response.statusCode);
      throw Exception(
        _apiMessage(response.body) ?? 'Unable to load driver behaviour',
      );
    } on SocketException {
      throw Exception('Network error, please check your connection');
    } on FormatException {
      throw Exception('The driver behaviour response could not be read');
    }
  }

  static String? _apiMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['title'];
        return message?.toString();
      }
    } catch (_) {
      // The server may return an empty or non-JSON error response.
    }
    return null;
  }

  Future<Map<String, dynamic>?> addGeoFence(LocationModel request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('$base_url/devices/create/geo/fence'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to create geo fence');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during creation: $e');
    }
  }

  static Future<bool> addUser(RegisterModel request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/register'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to create user');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during creation: $e');
    }
  }

  static Future<List<GeofenceModel>> fetchGeoFence(String numberPlate) async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse(
        '$base_url/devices/get/all/geo/fences?numberPlate=$numberPlate',
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data.map((item) => GeofenceModel.fromJson(item)).toList();
      } else if (data is Map && data.containsKey("devices")) {
        return (data["devices"] as List)
            .map((item) => GeofenceModel.fromJson(item))
            .toList();
      } else {
        throw Exception("Unexpected API response format");
      }
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load geofences');
    }
  }

  static Future<List<dynamic>?> fetchNotifications() async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.get(
        Uri.parse('$base_url/devices/get/violations/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // debugPrint(
      //   '[fetchNotifications] status: ${response.statusCode}, body: ${response.body}',
      // );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to fetch notifications');
      }
    } on SocketException {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred while fetching notifications: $e');
    }
  }

  Future<Map<String, dynamic>?> renewCertificate(List request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('$base_url/devices/renew/certificate'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to renew certificate');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during renewal: $e');
    }
  }

  Future<Map<String, dynamic>?> markAllNotificationsAsRead(
    List<int> request,
  ) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('$base_url/devices/mark/read/notifications'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to mark all notifications as read');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<Map<String, dynamic>?> requestDeleteAccount(
    DeleteAccountModel request,
  ) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/request/delete/account'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to request delete account');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during account deletion: $e');
    }
  }

  static Future<List<PlanModel>> fetchPlans() async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse('$base_url/devices/get/all/pricing/plans'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    // debugPrint(
    //   '[fetchPlans] status: ${response.statusCode}, body: ${response.body}',
    // );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data.map((json) => PlanModel.fromJson(json)).toList();
      } else {
        throw Exception('Unexpected data format: expected a list');
      }
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load plans');
    }
  }

  static Future<bool> updateProfile(
    String userId,
    String email,
    String fullName,
  ) async {
    String token = await StorageService.getData('access_token');

    try {
      final uri = Uri.parse('$BASE_URL/auth/user/mobile/update').replace(
        queryParameters: {
          'userId': userId,
          'emailAddress': email,
          'fullName': fullName,
        },
      );

      final response = await http.put(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to update profile');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during update: $e');
    }
  }

  /// Reads the over-speed threshold currently set on the device, in km/h.
  ///
  /// Returns null when the vehicle has no custom limit, or when the value
  /// could not be read.
  static Future<double?> fetchSpeedLimit(String deviceId) async {
    final String token = await StorageService.getData('access_token');
    final uri = Uri.parse(
      '$BASE_URL/devices/get/speed/limit',
    ).replace(queryParameters: {'deviceId': deviceId});
    debugPrint('[fetchSpeedLimit] → GET $uri');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('[fetchSpeedLimit] status: ${response.statusCode}');
      debugPrint('[fetchSpeedLimit] body: ${response.body}');
      _handleAuthError(response.statusCode);
      if (response.statusCode != 200) return null;
      final limit = _readSpeedLimit(jsonDecode(response.body));
      return (limit != null && limit > 0) ? limit : null;
    } catch (e) {
      debugPrint('[fetchSpeedLimit] error: $e');
      return null;
    }
  }

  /// The endpoint is untyped in the spec, so accept a bare number as well as
  /// the wrapper shapes the other Devices endpoints use.
  static double? _readSpeedLimit(dynamic body) {
    if (body is num) return body.toDouble();
    if (body is String) return double.tryParse(body);
    if (body is Map) {
      for (final key in ['speedLimit', 'newSpeedLimit', 'data', 'result']) {
        if (body.containsKey(key)) {
          final value = _readSpeedLimit(body[key]);
          if (value != null) return value;
        }
      }
    }
    return null;
  }

  /// Sets the over-speed threshold the device alerts on, in km/h.
  static Future<Map<String, dynamic>> updateSpeedLimit({
    required String deviceId,
    required double newSpeedLimit,
  }) async {
    final String token = await StorageService.getData('access_token');
    final uri = Uri.parse('$BASE_URL/devices/update/speed/limit').replace(
      queryParameters: {
        'deviceId': deviceId,
        'newSpeedLimit': newSpeedLimit.toString(),
      },
    );
    debugPrint('[updateSpeedLimit] → PUT $uri');
    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('[updateSpeedLimit] status: ${response.statusCode}');
      debugPrint('[updateSpeedLimit] body: ${response.body}');
      _handleAuthError(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return {
            'success': true,
            ...jsonDecode(response.body) as Map<String, dynamic>,
          };
        } catch (_) {
          return {'success': true};
        }
      }
      return {
        'success': false,
        'message': 'Failed to update speed limit (${response.statusCode})',
      };
    } on SocketException catch (e) {
      debugPrint('[updateSpeedLimit] SocketException: $e');
      throw Exception('Network error, please check your connection');
    } catch (e) {
      debugPrint('[updateSpeedLimit] error: $e');
      throw Exception('An error occurred: $e');
    }
  }

  static Future<Map<String, dynamic>> sendVehicleCommand({
    required String deviceId,
    required String serialNumber,
    required String command,
    required String numberPlate,
    required String reason,
  }) async {
    final String token = await StorageService.getData('access_token');
    final payload = {
      'deviceId': deviceId,
      'serialNumber': serialNumber,
      'command': command,
      'numberPlate': numberPlate,
      'reason': reason,
    };
    debugPrint(
      '[sendVehicleCommand] → POST $BASE_URL/devices/vehicle/commands',
    );
    debugPrint('[sendVehicleCommand] payload: ${jsonEncode(payload)}');
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/devices/vehicle/commands'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      debugPrint('[sendVehicleCommand] status: ${response.statusCode}');
      debugPrint('[sendVehicleCommand] body: ${response.body}');
      _handleAuthError(response.statusCode);
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return {
            'success': true,
            ...jsonDecode(response.body) as Map<String, dynamic>,
          };
        } catch (_) {
          return {'success': true};
        }
      }
      return {
        'success': false,
        'message': 'Command failed (${response.statusCode})',
      };
    } on SocketException catch (e) {
      debugPrint('[sendVehicleCommand] SocketException: $e');
      throw Exception('Network error, please check your connection');
    } catch (e) {
      debugPrint('[sendVehicleCommand] error: $e');
      throw Exception('An error occurred: $e');
    }
  }

  static Future<bool> sendEngineCommand(String numberPlate, bool start) async {
    // 1. Publish directly to the device via MQTT so the command arrives instantly.
    //    The device subscribes to orca/cmd/{numberPlate} and acts on the payload.
    final mqttOk = await MqttService().sendEngineCommand(numberPlate, start);

    // 2. Notify the backend via HTTP so server-side state (ignitionStatus) is
    //    updated and visible to other users / the dashboard.
    try {
      final String token = await StorageService.getData('access_token');
      final response = await http.post(
        Uri.parse('$base_url/devices/engine/${start ? 'start' : 'stop'}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'numberPlate': numberPlate}),
      );
      _handleAuthError(response.statusCode);
      return response.statusCode == 200;
    } catch (_) {
      // Fall back to the MQTT result if HTTP fails — the device may still
      // have received the command directly.
      return mqttOk;
    }
  }

  static Future<Map<String, dynamic>> registerDevice(
    Map<String, dynamic> deviceData,
  ) async {
    String token = await StorageService.getData('access_token');

    final response = await http.post(
      Uri.parse('$base_url/devices/register'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(deviceData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      _handleAuthError(response.statusCode);
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'statusCode': response.statusCode,
          ...errorData,
        };
      } catch (_) {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': 'Registration failed (${response.statusCode})',
        };
      }
    }
  }

  /// Checks whether a device with the given serial number is registered
  /// on the server (visible to this technician). Returns the matching
  /// device record when found, or `null` otherwise.
  ///
  /// Uses the technician-devices endpoint because the per-serial GET endpoint
  /// returns 403 for the technician role.
  static Future<Map<String, dynamic>?> checkDeviceRegistration(
    String serialNo,
  ) async {
    final serial = serialNo.trim();
    if (serial.isEmpty) return null;

    final token = await StorageService.getData('access_token');
    final pathSegment = Uri.encodeComponent(serial);
    final queryValue = Uri.encodeQueryComponent(serial);

    // Canonical Swagger form: serialNo is required in BOTH path and query
    // (see api.md /v1/api/devices/get/{serialNo}).
    final response = await http.get(
      Uri.parse('$BASE_URL/devices/get/$pathSegment?serialNo=$queryValue'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint(
      '[checkDeviceRegistration] serial=$serial, status=${response.statusCode}, '
      'body=${response.body}',
    );

    // Non-200 (the per-serial endpoint 403s for technicians) → fall back to
    // the technician's own device list rather than bouncing to login.
    if (response.statusCode != 200) {
      try {
        final needle = serial.toLowerCase();
        for (final d in (await fetchTechnicianDevices()).devices) {
          if (d.serial.trim().toLowerCase() == needle ||
              d.certNo.trim().toLowerCase() == needle) {
            return d.toJson();
          }
        }
      } catch (e) {
        debugPrint('[checkDeviceRegistration] technician list fallback: $e');
      }
      return null;
    }

    final body = response.body.trim();
    if (body.isEmpty || body == 'null') return null;

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;

    Map<String, dynamic>? payload;
    if (decoded is Map<String, dynamic>) {
      payload = decoded;
      // Some APIs wrap the device in {"data": {...}} or {"device": {...}}
      for (final wrapper in const ['data', 'device', 'result']) {
        final inner = payload?[wrapper];
        if (inner is Map<String, dynamic>) {
          payload = inner;
          break;
        }
      }
      // Honor explicit "not found" envelopes
      if (payload?['success'] == false) return null;
    } else if (decoded is List) {
      if (decoded.isEmpty) return null;
      final first = decoded.first;
      if (first is Map<String, dynamic>) payload = first;
    }

    if (payload == null || payload.isEmpty) return null;

    String normalize(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), '');
    final needle = normalize(serial);

    bool matchesNeedle(dynamic v) {
      if (v == null) return false;
      final s = normalize(v.toString());
      if (s.isEmpty) return false;
      return s == needle || s.contains(needle) || needle.contains(s);
    }

    // Require at least one identifier field to match the queried serial.
    const idFields = [
      'serial',
      'Serial',
      'MnfSerial',
      'mnfSerial',
      'MNFSerial',
      'deviceId',
      'DeviceId',
      'certNo',
      'CertNo',
      'limiterID',
      'LimiterID',
      'imei',
    ];
    final hasMatch = idFields.any((k) => matchesNeedle(payload?[k]));
    if (!hasMatch) {
      debugPrint(
        '[checkDeviceRegistration] 200 received but no identifier matched '
        '"$serial". Treating as not registered. Payload keys: '
        '${payload.keys.toList()}',
      );
      return null;
    }

    return payload;
  }

  static Future<void> submitDeviceDeleteRequest({
    required String deviceId,
    required String deviceSerialNumber,
    required String requestedByFullname,
    required String requestedByPhoneNumber,
    required String requestedByRole,
    required String reason,
    required String previousNumberPlate,
  }) async {
    final token = await StorageService.getData('access_token');
    debugPrint(
      '[submitDeviceDeleteRequest] preparing request: '
      'deviceId="$deviceId", serial="$deviceSerialNumber", '
      'role="$requestedByRole", numberPlate="$previousNumberPlate"',
    );
    final payload = {
      'deviceId': deviceId,
      'deviceSerialNumber': deviceSerialNumber,
      'requestedByFullname': requestedByFullname,
      'requestedByPhoneNumber': requestedByPhoneNumber,
      'requestedByRole': requestedByRole,
      'reason': reason,
      'previousNumberPlate': previousNumberPlate,
    };

    final response = await http.post(
      Uri.parse('$BASE_URL/devices/create/device/delete/request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    debugPrint(
      '[submitDeviceDeleteRequest] status: ${response.statusCode}, '
      'payload: ${jsonEncode(payload)}, body: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Request failed (${response.statusCode})');
    }
  }

  static Future<TechnicianDevicesModel> fetchTechnicianDevices() async {
    String token = await StorageService.getData('access_token');
    // Auth stores userDbId as a string. Assigning that dynamic value directly
    // to an int throws before the request is sent, leaving the technician's
    // vehicle list empty. Accept both string and int values so existing
    // sessions continue to work after upgrading.
    final userId = await StorageService.getInt('userDbId');
    if (userId == null) {
      throw StateError('Technician user ID is missing or invalid');
    }

    final response = await http.get(
      Uri.parse('$base_url/devices/get/technician/devices?id=$userId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        final devices = decoded
            .map((e) => TechnicianDevice.fromJson(e as Map<String, dynamic>))
            .toList();

        return TechnicianDevicesModel(
          devices: devices,
          totalDevices: devices.length,
          onlineDevices: devices.where((d) => d.isDeviceOnline).length,
          offlineDevices: devices.where((d) => !d.isDeviceOnline).length,
          activeCertificates: devices
              .where((d) => d.certificateActiveStatus)
              .length,
          expiredCertificates: devices
              .where((d) => !d.certificateActiveStatus)
              .length,
          idle: 0,
          stopped: 0,
          inMotion: 0,
        );
      }

      return TechnicianDevicesModel.fromJson(decoded);
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to fetch devices: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> makePayment(
    String numberPlate,
    String phoneNumber,
    int amount,
    int planId,
  ) async {
    String bookingId = generateBookingId();

    final response = await http.get(
      Uri.parse(
        'http://payments.atomiot.live/atomiot-express/initiate_stk_push.php'
        '?stk_amount=$amount'
        '&stk_phone_number=$phoneNumber'
        '&stk_account_reference=$numberPlate'
        '&bookingId=$bookingId'
        '&planId=$planId',
      ),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        return _parsePhpArray(body);
      }
    } else {
      throw Exception('Failed: ${response.statusCode}');
    }
  }

  static Map<String, dynamic> _parsePhpArray(String raw) {
    raw = raw
        .replaceAll('Array', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .trim();

    final Map<String, dynamic> result = {};
    for (var line in raw.split('\n')) {
      line = line.trim();
      if (line.contains('=>')) {
        final parts = line.split('=>');
        if (parts.length >= 2) {
          // Remove square brackets from key
          final key = parts[0].trim().replaceAll('[', '').replaceAll(']', '');
          result[key] = parts[1].trim();
        }
      }
    }
    return result;
  }

  // ─── Geofence management ──────────────────────────────────────────────────

  static Future<bool> deleteGeofence(int id) async {
    String token = await StorageService.getData('access_token');
    try {
      final response = await http.delete(
        Uri.parse('$base_url/devices/delete/geo/fence/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) return true;
      _handleAuthError(response.statusCode);
      return false;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Support tickets ──────────────────────────────────────────────────────

  /// Fetches every ticket (`/v1/api/tickets/get/all`).
  static Future<List<TicketModel>> fetchTickets() async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse('$BASE_URL/tickets/get/all'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final body = response.body.trim();
      if (body.isEmpty || body == 'null') return <TicketModel>[];
      final decoded = jsonDecode(body);
      if (decoded is List) {
        return TicketModel.fromJsonList(decoded);
      } else if (decoded is Map && decoded['data'] is List) {
        return TicketModel.fromJsonList(decoded['data'] as List);
      }
      return <TicketModel>[];
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to load tickets');
    }
  }

  /// Creates a new ticket (`/v1/api/tickets/create`). Anyone can create one.
  static Future<bool> createTicket(CreateTicketModel request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/tickets/create'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to create ticket (${response.statusCode})');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred while creating the ticket: $e');
    }
  }

  /// Updates an existing ticket (`/v1/api/tickets/update/{id}`).
  static Future<bool> updateTicket(int id, CreateTicketModel request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.put(
        Uri.parse('$BASE_URL/tickets/update/$id'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to update ticket (${response.statusCode})');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred while updating the ticket: $e');
    }
  }

  /// Resolves/closes a ticket with a new [status] and [remarks]
  /// (`/v1/api/tickets/close/{id}`). Used by admins and technicians.
  static Future<bool> closeTicket(int id, String status, String remarks) async {
    String token = await StorageService.getData('access_token');

    try {
      final uri = Uri.parse(
        '$BASE_URL/tickets/close/$id',
      ).replace(queryParameters: {'status': status, 'remarks': remarks});

      final response = await http.put(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        _handleAuthError(response.statusCode);
        throw Exception('Failed to resolve ticket (${response.statusCode})');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred while resolving the ticket: $e');
    }
  }

  /// Fires a geofence-breach event to the backend.
  /// The backend is responsible for sending push notifications to Admin/Manager.
  static Future<void> reportGeofenceBreach({
    required int geofenceId,
    required String numberPlate,
    required String latitude,
    required String longitude,
    required String exitTime,
  }) async {
    String token = await StorageService.getData('access_token');
    try {
      await http.post(
        Uri.parse('$base_url/devices/geo/fence/breach'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'geofenceId': geofenceId,
          'numberPlate': numberPlate,
          'latitude': latitude,
          'longitude': longitude,
          'exitTime': exitTime,
        }),
      );
    } catch (e) {
      debugPrint('reportGeofenceBreach error: $e');
    }
  }
}
