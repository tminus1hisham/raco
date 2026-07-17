import 'package:atom/config/app_theme.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/views/cars/selected_car_screen.dart';
import 'package:atom/widgets/vehicle/vehicle_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Device _device({
  bool online = true,
  String speed = '47',
  String certExpiry = '2030-01-01T00:00:00Z',
  String location = 'Kilimani, Nairobi',
  String latitude = '-1.2921',
  String longitude = '36.8219',
  int ignitionStatus = 1,
}) {
  return Device.fromJson({
    'id': 1,
    'deviceId': 'dev-1',
    'numberPlate': 'KDA 123A',
    'make': 'Toyota',
    'serial': 'sn-1',
    'location': location,
    'certificateUrl': 'https://example.test/cert.pdf',
    'certificateActiveStatus': true,
    'certificateExpirey': certExpiry,
    'signalStrength': 27,
    'speed': speed,
    'latitude': latitude,
    'longitude': longitude,
    'ignitionStatus': ignitionStatus,
    'isDeviceOnline': online,
  });
}

/// Mounts the screen on a surface tall enough that the whole page builds — the
/// page is a lazy ListView, which would skip off-screen rows at 800x600.
Future<void> _pump(WidgetTester tester, Device device) async {
  tester.view.physicalSize = const Size(420, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        extensions: const [AppColors.light],
      ),
      home: SelectedCarScreen(
        carModel: 'Premio',
        licensePlate: 'KDA 123A',
        devices: device,
      ),
    ),
  );

  // The hero's live dot pulses forever, so pumpAndSettle would never return.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'phone': '254712345678'});
  });

  tearDown(Get.reset);

  testWidgets('composes the hero, engine control and both sections', (
    tester,
  ) async {
    await _pump(tester, _device());

    expect(find.byType(VehicleHeroCard), findsOneWidget);
    expect(find.byType(VehicleEngineCard), findsOneWidget);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
    expect(find.text('VEHICLE MANAGEMENT'), findsOneWidget);

    // Live telemetry comes off the device, not the placeholder.
    expect(find.text('Premio'), findsOneWidget);
    expect(find.text('47'), findsOneWidget);
    expect(find.text('Kilimani, Nairobi'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('offers exactly one route to the live map', (tester) async {
    await _pump(tester, _device());

    // Previously this sat in both the quick actions and the management list.
    expect(find.text('Live Location'), findsOneWidget);
    expect(find.text('View Live Location'), findsNothing);
  });

  testWidgets('states each vehicle fact once', (tester) async {
    await _pump(tester, _device());

    // Engine state belongs to the engine card, not also to a hero chip.
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Engine On'), findsNothing);
    expect(find.text('Engine Off'), findsNothing);

    // Connection state belongs to the hero's live pill.
    expect(find.text('Online'), findsNothing);
  });

  testWidgets('an expired certificate is surfaced beside the hero', (
    tester,
  ) async {
    await _pump(tester, _device(certExpiry: '2020-01-01T00:00:00Z'));

    expect(find.byType(VehicleAlertBanner), findsOneWidget);
    expect(find.text('Certificate expired'), findsOneWidget);
    expect(find.text('Renew'), findsOneWidget);
    // The list row still marks itself, so the two agree.
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('a valid certificate raises no alert', (tester) async {
    await _pump(tester, _device());

    expect(find.byType(VehicleAlertBanner), findsNothing);
    expect(find.text('Certificate expired'), findsNothing);
    expect(find.text('Expired'), findsNothing);
    expect(find.text('Certificate'), findsOneWidget);
  });

  testWidgets('an offline vehicle reports no signal and zero speed', (
    tester,
  ) async {
    await _pump(tester, _device(online: false, speed: '47'));

    expect(find.text('OFFLINE'), findsOneWidget);
    expect(find.text('No signal'), findsOneWidget);
    // The model zeroes speed when offline; a stale 47 must not be shown.
    expect(find.text('47'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('an immobilized engine reads as such', (tester) async {
    await _pump(tester, _device(ignitionStatus: 0));

    expect(find.text('Immobilized'), findsOneWidget);
    expect(find.text('Running'), findsNothing);
  });

  testWidgets('a vehicle with no fix leaves the location footer inert', (
    tester,
  ) async {
    await _pump(
      tester,
      _device(latitude: '', longitude: '', location: ''),
    );

    expect(find.text('Location unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('engine confirmation', () {
    testWidgets('immobilizing warns and demands a reason before it will send', (
      tester,
    ) async {
      await _pump(tester, _device(ignitionStatus: 1));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Turn Off Engine'), findsOneWidget);
      expect(
        find.textContaining('engine will not start again'),
        findsOneWidget,
      );

      // Confirming with no reason must not dismiss the dialog.
      await tester.tap(find.text('Turn Off'));
      await tester.pump();
      expect(find.text('Reason is required'), findsOneWidget);
      expect(find.text('Turn Off Engine'), findsOneWidget);
    });

    testWidgets('cancelling leaves the engine untouched', (tester) async {
      await _pump(tester, _device(ignitionStatus: 1));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Turn Off Engine'), findsNothing);
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('restoring an engine raises no immobilize warning', (
      tester,
    ) async {
      await _pump(tester, _device(ignitionStatus: 0));

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Turn On Engine'), findsOneWidget);
      expect(find.textContaining('engine will not start again'), findsNothing);
    });
  });
}
