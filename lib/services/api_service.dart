import 'dart:convert';
import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/models/geofence_model.dart';
import 'package:atom/models/location_model.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/models/profile_picture_model.dart';
import 'package:atom/models/report_model.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/views/auth/login_screen.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'local_storage_service.dart';

class ApiService {
  static void _handleAuthError(int statusCode) async {
    if (statusCode == 403 || statusCode == 401) {
      Get.offAll(() => LoginScreen());
    }
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

  static Future<List<DeviceRecord>> fetchDeviceHistory(
    String numberPlate,
    String date,
  ) async {
    String token = await StorageService.getData('access_token');

    final response = await http.get(
      Uri.parse(
        '$base_url/devices/get/tracking/history?numberPlate=$numberPlate&date=$date',
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

    print("HAPA");
    print(response.body);

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
}
