import 'dart:convert';
import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/models/profile_picture_model.dart';
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
}
