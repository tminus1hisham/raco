import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:atom/config/constants.dart';
import 'package:atom/models/change_password_model.dart';
import 'package:atom/models/forgot_password_model.dart';
import 'package:atom/models/login_model.dart';
import 'package:atom/models/register_model.dart';
import 'package:atom/models/reset_password_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'local_storage_service.dart';

/// Error thrown by [AuthService] carrying enough detail to tell apart a bad
/// password from a bad URL, a dead server or a malformed response.
class AuthException implements Exception {
  /// Message safe to show to the user.
  final String message;

  /// HTTP status code, when the request actually reached the server.
  final int? statusCode;

  /// Raw response body, for logs only.
  final String? responseBody;

  /// Short tag describing the failure class, e.g. `http_401`, `network`,
  /// `timeout`, `bad_json`.
  final String kind;

  AuthException(
    this.message, {
    this.statusCode,
    this.responseBody,
    this.kind = 'unknown',
  });

  @override
  String toString() =>
      'AuthException($kind${statusCode != null ? ' $statusCode' : ''}): $message';
}

class AuthService {
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Keys whose values must never reach the console.
  static const _redactedKeys = {
    'password',
    'newPassword',
    'oldPassword',
    'confirmPassword',
    'token',
    'refreshToken',
    'firebaseToken',
    'userFirebaseToken',
  };

  static void _log(String operation, String message) {
    debugPrint('[Auth/$operation] $message');
  }

  static Map<String, dynamic> _redact(Map<String, dynamic> json) {
    return json.map(
      (key, value) => MapEntry(
        key,
        _redactedKeys.contains(key)
            ? (value == null || value.toString().isEmpty
                  ? '<empty>'
                  : '<redacted:${value.toString().length} chars>')
            : value,
      ),
    );
  }

  /// Pulls the server's own error text out of a JSON body so the log shows
  /// "Invalid credentials" instead of just a status code.
  static String? _extractServerMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail', 'msg']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
          if (value is List && value.isNotEmpty) return value.join(', ');
        }
      }
      if (decoded is String && decoded.trim().isNotEmpty) return decoded.trim();
    } catch (_) {
      // Not JSON - fall through and let the caller log the raw body.
    }
    return null;
  }

  static String _truncate(String value, [int max = 1000]) =>
      value.length <= max ? value : '${value.substring(0, max)}… (${value.length} chars)';

  static Future<void> _storeTokens(Map<String, dynamic> data) async {
    try {
      await StorageService.storeData({
        'access_token': data['token'],
        'refreshToken': data['refreshToken'],
        'phone': data['phone'],
        'userId': data['userId'],
        'userName': data['userName'],
        'isLoggedin': true,
        'userRole': data['user']['userRole'],
        'userDbId': data['user']['id'].toString(),
      });

      final userRole = data['user']['userRole']?.toString().toLowerCase() ?? '';
      if (userRole == 'technician') {
        // Store agent data from the 'agent' object in response
        if (data['agent'] != null) {
          final agent = data['agent'] as Map<String, dynamic>;

          // Store agent ID
          if (agent['id'] != null) {
            await StorageService.storeData({'agentId': agent['id'].toString()});
          }

          // Store agent name
          if (agent['agentName'] != null) {
            await StorageService.storeData({'agentName': agent['agentName']});
          }

          // Store agent email
          if (agent['email'] != null) {
            await StorageService.storeData({'agentEmail': agent['email']});
          }

          // Store agent phone
          if (agent['phoneNumber'] != null) {
            await StorageService.storeData({
              'agentPhone': agent['phoneNumber'],
            });
          }

          // Store business registration
          if (agent['businessReg'] != null) {
            await StorageService.storeData({
              'businessReg': agent['businessReg'],
            });
          }

          // Store location
          if (agent['location'] != null) {
            await StorageService.storeData({
              'agentLocation': agent['location'],
            });
          }
        }
      }
    } catch (e, stack) {
      _log('storeTokens', 'FAILED to persist session: ${e.runtimeType}: $e');
      _log('storeTokens', 'available keys were: ${data.keys.toList()}');
      _log('storeTokens', 'stack: $stack');
      // Behaviour unchanged: login still proceeds, but the failure is no
      // longer invisible.
    }
  }

  Future<Map<String, dynamic>?> register(RegisterModel request) async {
    String token = await StorageService.getData('access_token');
    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // await _storeTokens(data);
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

  Future<bool> deleteUser(int id) async {
    String token = await StorageService.getData('access_token');
    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}/auth/delete/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
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
    final url = Uri.parse('$BASE_URL/auth/login');
    final payload = request.toJson();
    final stopwatch = Stopwatch()..start();

    _log('login', 'POST $url');
    _log('login', 'payload: ${jsonEncode(_redact(payload))}');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);

      _log(
        'login',
        'status ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms '
            '(${response.contentLength ?? response.bodyBytes.length} bytes, '
            'content-type: ${response.headers['content-type'] ?? 'none'})',
      );

      if (response.statusCode != 200) {
        final serverMessage = _extractServerMessage(response.body);
        _log('login', 'error body: ${_truncate(response.body)}');
        throw AuthException(
          serverMessage ?? _defaultMessageForStatus(response.statusCode),
          statusCode: response.statusCode,
          responseBody: response.body,
          kind: 'http_${response.statusCode}',
        );
      }

      final Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        _log('login', 'could not parse success body ($e): ${_truncate(response.body)}');
        throw AuthException(
          'The server sent an unexpected response. Please try again.',
          statusCode: response.statusCode,
          responseBody: response.body,
          kind: 'bad_json',
        );
      }

      _log('login', 'response keys: ${data.keys.toList()}');

      if (data['token'] == null) {
        _log('login', 'WARNING: 200 OK but no "token" in response');
        throw AuthException(
          'Login response did not include a session token.',
          statusCode: response.statusCode,
          responseBody: response.body,
          kind: 'missing_token',
        );
      }

      await _storeTokens(data);
      _log(
        'login',
        'success for userId=${data['userId']} role=${data['user']?['userRole']}',
      );
      return data;
    } on AuthException {
      rethrow;
    } on TimeoutException catch (e) {
      _log('login', 'timed out after ${stopwatch.elapsedMilliseconds}ms: $e');
      throw AuthException(
        'The server took too long to respond. Please try again.',
        kind: 'timeout',
      );
    } on SocketException catch (e) {
      _log('login', 'socket error: ${e.message} (host: ${e.address?.host ?? url.host}, os: ${e.osError})');
      throw AuthException(
        'Network error, please check your connection',
        kind: 'network',
      );
    } on http.ClientException catch (e) {
      _log('login', 'http client error: ${e.message} (uri: ${e.uri})');
      throw AuthException(
        'Could not reach the server. Please check your connection.',
        kind: 'client',
      );
    } catch (e, stack) {
      _log('login', 'unexpected ${e.runtimeType}: $e');
      _log('login', 'stack: $stack');
      throw AuthException(
        'An unexpected error occurred during login.',
        kind: 'unexpected',
      );
    } finally {
      stopwatch.stop();
    }
  }

  static String _defaultMessageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid login details. Please check and try again.';
      case 401:
      case 403:
        return 'Incorrect phone number or password.';
      case 404:
        return 'Login endpoint not found (404). Check the API base URL.';
      case 429:
        return 'Too many login attempts. Please wait and try again.';
      default:
        if (statusCode >= 500) {
          return 'The server is having problems ($statusCode). Please try again later.';
        }
        return 'Login failed with status $statusCode.';
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
      await StorageService.removeData("userId");
      await StorageService.removeData("userName");
      await StorageService.removeData("userRole");
      await StorageService.removeData("userDbId");

      return true;
    } catch (e) {
      return false;
    }
  }
}
