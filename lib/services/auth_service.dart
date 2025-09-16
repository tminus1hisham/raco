import 'dart:convert';
import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/models/login_model.dart';
import 'package:atom/models/register_model.dart';
import 'package:http/http.dart' as http;

import 'local_storage_service.dart';

class AuthService {
  static Future<void> _storeTokens(Map<String, dynamic> data) async {
    try {
      await StorageService.storeData({
        'access_token': data['token'],
        'refreshToken': data['refreshToken'],
        'userId': data['userId'],
        'isLoggedin': true,
      });
    } catch (e) {
      print('Error storing tokens: $e');
    }
  }

  Future<Map<String, dynamic>?> register(RegisterModel request) async {
    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storeTokens(data);
        return data;
      } else {
        throw Exception('Failed to register');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during login: $e');
    }
  }

  Future<Map<String, dynamic>?> login(LoginModel request) async {
    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storeTokens(data);
        return data;
      } else {
        throw Exception('Failed to login');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during login: $e');
    }
  }

  Future<bool> logoutUser() async {
    try {
      // await StorageService.removeData('access_token');
      await StorageService.storeData({'isLoggedin': false});

      return true;
    } catch (e) {
      return false;
    }
  }
}
