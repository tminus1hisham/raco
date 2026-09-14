import 'dart:async';

import 'package:atom/models/notification_permission.dart';
import 'package:atom/services/api_service.dart';
import 'package:atom/views/settings/notification_permissions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePermissionsApi extends ApiService {
  bool failLoad = false;
  Completer<void>? save;
  NotificationPermission? updated;
  bool? enabled;

  @override
  Future<Map<NotificationPermission, bool>>
  fetchNotificationPermissions() async {
    if (failLoad) throw Exception('Offline');
    return {
      for (final permission in NotificationPermission.values) permission: true,
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
  Future<void> mount(WidgetTester tester, FakePermissionsApi api) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: NotificationPermissionsScreen(apiService: api)),
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
