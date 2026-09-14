import 'package:atom/config/app_theme.dart';
import 'package:atom/models/vehicle_model.dart';
import 'package:atom/views/cars/vehicle_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Device _device({required int ignitionStatus}) {
  return Device.fromJson({
    'id': 1,
    'deviceId': 'dev-1',
    'numberPlate': 'KDA 123A',
    'make': 'Toyota',
    'serial': 'sn-1',
    'location': 'Kilimani, Nairobi',
    'certificateUrl': 'https://example.test/cert.pdf',
    'certificateActiveStatus': true,
    'certificateExpirey': '2030-01-01T00:00:00Z',
    'signalStrength': 27,
    'speed': '0',
    'latitude': '-1.2921',
    'longitude': '36.8219',
    'ignitionStatus': ignitionStatus,
    'isDeviceOnline': true,
  });
}

Future<void> _pump(WidgetTester tester, Device device) async {
  tester.view.physicalSize = const Size(420, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        extensions: const [AppColors.light],
      ),
      home: VehicleDetails(vehiclePlate: device.numberPlate, device: device),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('ignition status 0 shows the engine as on', (tester) async {
    await _pump(tester, _device(ignitionStatus: 0));

    expect(find.text('Running'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('ignition status 1 shows the engine as off', (tester) async {
    await _pump(tester, _device(ignitionStatus: 1));

    expect(find.text('Immobilized'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('engine reason dialog focuses the reason field', (tester) async {
    await _pump(tester, _device(ignitionStatus: 0));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });
}
