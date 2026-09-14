import 'dart:async';

import 'package:atom/models/notification_permission.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/services/push_notification_service.dart';
import 'package:atom/views/settings/notification_permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePermissionsApi extends ApiService {
  bool failLoad = false;
  bool initialValue = true;
  Completer<void>? save;
  NotificationPermission? updated;
  bool? enabled;

  @override
  Future<Map<NotificationPermission, bool>>
  fetchNotificationPermissions() async {
    if (failLoad) throw Exception('Offline');
    return {
      for (final permission in NotificationPermission.values)
        permission: initialValue,
    };
  }

  @override
  Future<void> updateNotificationPermission(
    NotificationPermission permission,
    bool value,
  ) async {
    updated = permission;
    enabled = value;
    await save?.future;
  }
}

void main() {
  test(
    'parses notification status from a communications response envelope',
    () {
      final parsed = ApiService.parseNotificationPermissions({
        'success': true,
        'data': {
          'speedLimitNotification': true,
          'signalTamperingNotification': false,
          'batteryTamperingNotification': true,
          'engineOnNotification': false,
          'engineOffNotification': true,
        },
      });

      expect(parsed[NotificationPermission.speedLimit], isTrue);
      expect(parsed[NotificationPermission.signalTampering], isFalse);
      expect(parsed[NotificationPermission.batteryTampering], isTrue);
      expect(parsed[NotificationPermission.engineOn], isFalse);
      expect(parsed[NotificationPermission.engineOff], isTrue);
    },
  );

  test('rejects incomplete notification status responses', () {
    expect(
      () => ApiService.parseNotificationPermissions({
        'success': true,
        'data': {'speedLimitNotification': true},
      }),
      throwsFormatException,
    );
  });

  Future<void> mount(
    WidgetTester tester,
    FakePermissionsApi api, {
    Future<void> Function()? enablePush,
  }) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationPermissionsScreen(
          apiService: api,
          enablePush: enablePush,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('loads all permissions and saves a toggle', (tester) async {
    final api = FakePermissionsApi()..save = Completer<void>();
    await mount(tester, api);
    expect(find.byType(SwitchListTile), findsNWidgets(5));
    final tile = find.byKey(const ValueKey(NotificationPermission.speedLimit));
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await tester.tap(tile);
    await tester.pump();
    expect(api.updated, NotificationPermission.speedLimit);
    expect(api.enabled, isFalse);
    expect(tester.widget<SwitchListTile>(tile).onChanged, isNull);
    api.save!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(tester.widget<SwitchListTile>(tile).onChanged, isNotNull);
  });

  testWidgets('registers push before enabling the server alert', (
    tester,
  ) async {
    final api = FakePermissionsApi()..initialValue = false;
    final permission = Completer<void>();
    await mount(tester, api, enablePush: () => permission.future);
    await tester.tap(
      find.byKey(const ValueKey(NotificationPermission.speedLimit)),
    );
    await tester.pump();
    expect(api.updated, isNull);
    permission.complete();
    await tester.pumpAndSettle();
    expect(api.updated, NotificationPermission.speedLimit);
    expect(api.enabled, isTrue);
  });

  testWidgets('denied permission restores toggle without updating the API', (
    tester,
  ) async {
    final api = FakePermissionsApi()..initialValue = false;
    await mount(
      tester,
      api,
      enablePush: () async {
        throw const PushNotificationException('Notifications are blocked.');
      },
    );
    final tile = find.byKey(const ValueKey(NotificationPermission.speedLimit));
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(api.updated, isNull);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    expect(find.text('Notifications are blocked.'), findsOneWidget);
  });

  testWidgets('restores the previous value when saving fails', (tester) async {
    final api = FakePermissionsApi()..save = Completer<void>();
    await mount(tester, api);
    final tile = find.byKey(const ValueKey(NotificationPermission.engineOff));
    await tester.tap(tile);
    await tester.pump();
    api.save!.completeError(Exception('Offline'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(find.textContaining('Could not save'), findsOneWidget);
  });

  testWidgets('offers retry without displaying invented defaults', (
    tester,
  ) async {
    final api = FakePermissionsApi()..failLoad = true;
    await mount(tester, api);
    expect(find.byType(SwitchListTile), findsNothing);
    api.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNWidgets(5));
  });
}
