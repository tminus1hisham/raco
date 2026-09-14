import 'package:atom/app.dart';
import 'package:atom/services/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.initialize();
  MapboxOptions.setAccessToken(
    "pk.eyJ1Ijoic2h1bGVkcml2ZSIsImEiOiJjbWx0azl0c2gwMTBrM2NzaDVmMnV4a2Q2In0.4nKQxxM4e2DcmF110KhyyA",
  );

  runApp(MyApp());
}
