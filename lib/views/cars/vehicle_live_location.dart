import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:atom/config/constants.dart';
import 'package:atom/services/mqtt_client.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mqtt_client/mqtt_client.dart';

class VehicleLocationScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String deviceId;

  const VehicleLocationScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.deviceId,
  }) : super(key: key);

  @override
  State<VehicleLocationScreen> createState() => _VehicleLocationScreenState();
}

class _VehicleLocationScreenState extends State<VehicleLocationScreen> {
  GoogleMapController? mapController;
  late LatLng position;
  BitmapDescriptor? carIcon;
  bool isLoading = true;
  final MqttService _mqttService = MqttService();

  StreamSubscription? _mqttSubscription;

  @override
  void initState() {
    super.initState();
    position = LatLng(widget.latitude, widget.longitude);
    _loadCarIcon().then((_) => _subscribeToVehicleTopic());
  }

  @override
  void dispose() {
    _unsubscribeFromVehicleTopic();
    _mqttSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToVehicleTopic() {
    if (!_mqttService.isConnected) {
      print("MQTT not connected yet");
      return;
    }

    final topic = "${widget.deviceId}";
    _mqttService.subscribeToTopic(topic);
    print("✅ Subscribed to $topic");

    _mqttSubscription = _mqttService.client.updates!.listen((messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = messages[0].topic;

      if (topic == "orca/payload/${widget.deviceId}") {
        _handleCarLocation(payload);
      }
    });
  }

  /// Unsubscribe when user exits screen
  void _unsubscribeFromVehicleTopic() {
    final topic = "vehicles/${widget.deviceId}";
    if (_mqttService.isConnected) {
      _mqttService.unsubscribeFromTopic(topic);
      print("🛑 Unsubscribed from $topic");
    }
  }

  /// Handle incoming location data
  void _handleCarLocation(String message) {
    try {
      final data = jsonDecode(message);
      final double lat = data['lat'] ?? 0.0;
      final double lng = data['lng'] ?? 0.0;

      print("📍 New location: $lat, $lng");

      setState(() {
        position = LatLng(lat, lng);
      });

      // Optionally animate map camera to new position
      mapController?.animateCamera(CameraUpdate.newLatLng(position));
    } catch (e) {
      print("❌ Error parsing message: $e");
    }
  }

  /// Load custom car icon
  Future<void> _loadCarIcon() async {
    carIcon = await _resizeAndLoadIcon('assets/green_car.png', 140);
    setState(() {
      isLoading = false;
    });
  }

  Future<BitmapDescriptor> _resizeAndLoadIcon(
    String assetPath,
    int width,
  ) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.threeArchedCircle(
                color: kBlue,
                size: 50,
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: position,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId("vehicle_marker"),
                        position: position,
                        icon: carIcon ?? BitmapDescriptor.defaultMarker,
                        infoWindow: const InfoWindow(title: "Vehicle"),
                      ),
                    },
                    onMapCreated: (controller) => mapController = controller,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 0,
                  right: 0,
                  child: customHeader(
                    label: "Live Location",
                    icon: Icons.drive_eta_rounded,
                    showBackButton: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
    );
  }
}
