import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:atom/config/constants.dart';
import 'package:atom/models/geofence_model.dart';
import 'package:atom/models/location_model.dart';
import 'package:atom/models/plans_model.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/models/profile_picture_model.dart';
import 'package:atom/models/register_device_model.dart';
import 'package:atom/models/report_model.dart';
import 'package:atom/models/technician_device_model.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/models/user_model.dart';
import 'package:atom/models/company_model.dart';
import 'package:atom/views/auth/login_screen.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/delete_account_model.dart';
import 'local_storage_service.dart';

class ApiService {
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

  static Future<DevicesModel> fetchDevices() async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse('$base_url/devices/get/vehicles/dashboard?company=All'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
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

    print('Fetch Companies Response: ${response.body}');

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

  Future<Map<String, dynamic>?> addGeoFence(LocationModel request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('${base_url}/devices/create/geo/fence'),
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
        Uri.parse('${BASE_URL}/auth/register'),
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
        Uri.parse('${base_url}/devices/renew/certificate'),
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

  Future<Map<String, dynamic>?> markAllNotificationsAsRead(List request) async {
    String token = await StorageService.getData('access_token');

    try {
      final response = await http.post(
        Uri.parse('${base_url}/devices/mark/read/notifications'),
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
        Uri.parse('${BASE_URL}/auth/request/delete/account'),
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
      final uri = Uri.parse('${BASE_URL}/auth/user/mobile/update').replace(
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
        final data = json.decode(response.body);
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

    print('Register Device Response: ${response}');
    print('Register Device Response: ${response.body}');
    print('Register Device Response: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      _handleAuthError(response.statusCode);
      throw Exception('Failed to register device: ${response.statusCode}');
    }
  }

  static Future<TechnicianDevicesModel> fetchTechnicianDevices() async {
    String token = await StorageService.getData('access_token');
    int userId = await StorageService.getData('userDbId');

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
}
