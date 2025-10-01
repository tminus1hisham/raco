import 'dart:convert';
import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/models/playback_model.dart';
import 'package:atom/models/profile_picture_model.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:http/http.dart' as http;

import 'local_storage_service.dart';

class ApiService {
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
      Uri.parse('$base_url/devices/get/vehicles/dashboard'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DevicesModel.fromJson(data);
    } else {
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
      final data = jsonDecode(response.body) as List;
      return DeviceRecord.fromJsonList(data);
    } else {
      throw Exception('Failed to load history');
    }
  }

  static Future<List<DeviceRecord>> fetchViolations(
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

      return DeviceRecord.fromJsonList(data);
    } else {
      throw Exception('Failed to load violations');
    }
  }

  static Future<List<DeviceRecord>> fetchReports(
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

      final data = decoded['devices'] as List<dynamic>;

      return DeviceRecord.fromJsonList(data);
    } else {
      throw Exception('Failed to load reports');
    }
  }
}
