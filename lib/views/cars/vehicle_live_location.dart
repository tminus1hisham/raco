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
  double _bearing = 0.0;
  String speed = '';
  String numberPlate = '';
  double _currentZoom = 15.0;

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

    final topic = "orca/payload/${widget.deviceId}";
    _mqttService.subscribeToTopic(topic);
    print("✅ Subscribed to $topic");

    _mqttSubscription = _mqttService.client.updates!.listen((messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = messages[0].topic;

      print("📦 Raw Payload: $payload");

      if (topic == "orca/payload/${widget.deviceId}") {
        _handleCarLocation(payload);
      }

      print("HAPA");
      print("orca/payload/${widget.deviceId}");
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

  void _handleCarLocation(String message) {
    try {
      final data = jsonDecode(message);

      final String rawLat = data['Lt'] ?? "";
      final String ns = data['NS'] ?? "N";
      final String rawLng = data['Lg'] ?? "";
      final String ew = data['EW'] ?? "E";
      numberPlate = data['Rg'] ?? "";
      speed = data['Spd'] ?? "0";
      final String course = data['course']?.toString() ?? "0";

      final double lat = _convertToDecimalDegrees(rawLat, ns);
      final double lng = _convertToDecimalDegrees(rawLng, ew);

      print("📍 Location: $lat, $lng, 🧭 Course: $course");

      setState(() {
        position = LatLng(lat, lng);
        _bearing = double.tryParse(course) ?? 0.0;
      });

      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: _currentZoom),
        ),
      );

      _showMarkerInfoWindow();
    } catch (e) {
      print("❌ Error parsing message: $e");
    }
  }

  void _showMarkerInfoWindow() {
    if (mapController != null) {
      mapController!.showMarkerInfoWindow(const MarkerId("vehicle_marker"));
    }
  }

  double _convertToDecimalDegrees(String coord, String direction) {
    if (coord.isEmpty) return 0.0;
    final double value = double.tryParse(coord) ?? 0.0;
    final double degrees = (value ~/ 100).toDouble();
    final double minutes = value - (degrees * 100);
    double decimalDegrees = degrees + (minutes / 60);
    if (direction == 'S' || direction == 'W') decimalDegrees *= -1;
    return decimalDegrees;
  }

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
                      zoom: _currentZoom,
                    ),
                    onCameraMove: (CameraPosition position) {
                      _currentZoom = position.zoom;
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId("vehicle_marker"),
                        position: position,
                        icon: carIcon ?? BitmapDescriptor.defaultMarker,
                        rotation: _bearing,
                        anchor: const Offset(0.5, 0.5),
                        infoWindow: InfoWindow(
                          title: numberPlate.toUpperCase(),
                          snippet:
                              "Speed: ${speed} km/h"
                              "",
                        ),
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
