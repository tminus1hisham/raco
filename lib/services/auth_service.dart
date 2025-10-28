import 'dart:convert';
import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/models/change_password_model.dart';
import 'package:atom/models/forgot_password_model.dart';
import 'package:atom/models/login_model.dart';
import 'package:atom/models/register_model.dart';
import 'package:atom/models/reset_password_model.dart';
import 'package:http/http.dart' as http;

import 'local_storage_service.dart';

class AuthService {
  static Future<void> _storeTokens(Map<String, dynamic> data) async {
    try {
      await StorageService.storeData({
        'access_token': data['token'],
        'refreshToken': data['refreshToken'],
        'phone': data['phone'],
        'userId': data['userId'],
        'userName': data['userName'],
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

  Future<Map<String, dynamic>?> forgotPassword(
    ForgotPasswordModel request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/auth/forgot/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to send code');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during sending code: $e');
    }
  }

  Future<Map<String, dynamic>?> changePassword(
    ChangePasswordModel request,
  ) async {
    String token = await StorageService.getData('access_token');
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/auth/change/password'),
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
        throw Exception('Failed to change password');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during changing password: $e');
    }
  }

  Future<Map<String, dynamic>?> resetPassword(
    ResetPasswordModel request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/auth/reset/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to reset password');
      }
    } on SocketException catch (_) {
      throw Exception('Network error, please check your connection');
    } catch (e) {
      throw Exception('An error occurred during resetting password: $e');
    }
  }

  Future<bool> logoutUser() async {
    try {
      await StorageService.storeData({'isLoggedin': false});

      return true;
    } catch (e) {
      return false;
    }
  }
}
