import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:atom/controllers/notifcations_controller.dart';
import 'package:atom/views/notification_screen.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

class PushNotificationException implements Exception {
  const PushNotificationException(this.message);
  final String message;
}

/// FCM delivers messages; the Communications API controls which alerts the
/// server sends to this user's token. No shared vehicle topics are used.
class PushNotificationService {
  static final instance = PushNotificationService();
  Future<void>? _initializing;
  bool _ready = false;
  Object? _lastInitializationError;
  bool _dashboardReady = false;
  bool _pendingOpen = false;
  Future<void> _registration = Future.value();

  Future<void> initialize() {
    if (_ready) return Future.value();
    return _initializing ??= _initialize().whenComplete(() {
      if (!_ready) _initializing = null;
    });
  }

  Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = FirebaseMessaging.instance;
      // Foreground messages use the in-app banner on both platforms.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      messaging.onTokenRefresh.listen((_) => syncToken(), onError: (_) {});
      FirebaseMessaging.onMessage.listen(_onMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openNotifications());
      _pendingOpen = await messaging.getInitialMessage() != null;
      _ready = true;
      _lastInitializationError = null;
    } catch (error, stack) {
      _ready = false;
      _lastInitializationError = error;
      debugPrint(
        '[Push] Firebase initialization unavailable: ${error.runtimeType}: $error',
      );
      debugPrint('[Push] Firebase initialization stack: $stack');
    }
  }

  Future<String?> tokenForLogin() async {
    await initialize();
    if (!_ready) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> enableNotifications() async {
    await initialize();
    if (!_ready) {
      debugPrint(
        '[Push] Enable blocked because Firebase is not ready. '
        'Last init error: $_lastInitializationError',
      );
      throw PushNotificationException(
        'Push notifications are not configured in this build. Rebuild the app after adding Firebase config.',
      );
    }
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      throw const PushNotificationException(
        'Notifications are blocked. Allow notifications for Orca in your phone settings, then try again.',
      );
    }
    await _registerToken();
  }

  Future<void> _registerToken() {
    // Full-account updates must not overlap each other.
    final operation = _registration.then((_) async {
      if (await StorageService.getData('isLoggedin') != true) {
        throw const PushNotificationException(
          'Sign in to enable notifications.',
        );
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        throw const PushNotificationException(
          'Could not connect to push notifications. Please try again.',
        );
      }
      await ApiService().registerFirebaseToken(token);
    });
    _registration = operation.catchError((_) {});
    return operation;
  }

  Future<void> syncToken() async {
    await initialize();
    if (!_ready) return;
    try {
      await _registerToken();
    } catch (_) {
      // Retry on the next app resume or when an alert is enabled.
      debugPrint('[Push] Token registration pending retry.');
    }
  }

  void dashboardReady() {
    _dashboardReady = true;
    if (_pendingOpen) _openNotifications();
    unawaited(syncToken());
  }

  void dashboardClosed() => _dashboardReady = false;

  Future<void> _onMessage(RemoteMessage message) async {
    if (!_dashboardReady || await StorageService.getData('isLoggedin') != true)
      return;
    if (Get.isRegistered<NotificationsController>()) {
      unawaited(Get.find<NotificationsController>().fetchNotifications());
    }
    final notification = message.notification;
    if (notification == null) return;
    Get.snackbar(
      notification.title ?? 'Orca alert',
      notification.body ?? 'You have a new alert.',
      onTap: (_) => _openNotifications(),
      duration: const Duration(seconds: 5),
    );
  }

  void _openNotifications() {
    if (!_dashboardReady) {
      _pendingOpen = true;
      return;
    }
    _pendingOpen = false;
    Get.to(() => const NotificationScreen());
  }

  Future<void> logout() async {
    if (_ready) {
      await _registration;
      // Invalidate this installation's token so the signed-out account cannot
      // continue delivering notifications to this device.
      await FirebaseMessaging.instance.deleteToken();
    }
    _dashboardReady = false;
    _pendingOpen = false;
  }
}
