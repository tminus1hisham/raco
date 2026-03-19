import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/services/mqtt_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

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

class _VehicleLocationScreenState extends State<VehicleLocationScreen>
    with SingleTickerProviderStateMixin {
  MapboxMap? mapboxMap;
  bool isLoading = true;
  final MqttService _mqttService = MqttService();

  double _bearing = 0.0;
  String speed = '0';
  String numberPlate = '';
  double _currentZoom = 15.0;
  Uint8List? carIcon;

  StreamSubscription? _mqttSubscription;

  PointAnnotationManager? _annotationManager;
  PointAnnotation? _vehicleAnnotation;

  late AnimationController _moveController;
  void Function()? _moveListener;
  double _animLat = 0;
  double _animLng = 0;

  @override
  void initState() {
    super.initState();
    _animLat = widget.latitude;
    _animLng = widget.longitude;
    _moveController = AnimationController(vsync: this);
    _loadCarIcon().then((_) => _subscribeToVehicleTopic());
  }

  @override
  void dispose() {
    _moveController.dispose();
    _unsubscribeFromVehicleTopic();
    _mqttSubscription?.cancel();
    super.dispose();
  }

  // ─── MQTT ─────────────────────────────────────────────────────────────────

  void _subscribeToVehicleTopic() {
    if (!_mqttService.isConnected) return;

    final topic = 'orca/payload/${widget.deviceId}';
    _mqttService.subscribeToTopic(topic);

    _mqttSubscription = _mqttService.client.updates!.listen((messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      if (messages[0].topic == topic) {
        _handleCarLocation(payload);
      }
    });
  }

  void _unsubscribeFromVehicleTopic() {
    if (_mqttService.isConnected) {
      _mqttService.unsubscribeFromTopic('vehicles/${widget.deviceId}');
    }
  }

  void _handleCarLocation(String message) {
    try {
      final data = jsonDecode(message);
      final double lat = _convertToDecimalDegrees(
        data['Lt'] ?? '',
        data['NS'] ?? 'N',
      );
      final double lng = _convertToDecimalDegrees(
        data['Lg'] ?? '',
        data['EW'] ?? 'E',
      );

      if (lat == 0.0 && lng == 0.0) return;

      setState(() {
        numberPlate = data['Rg'] ?? numberPlate;
        speed = data['Spd'] ?? '0';
        _bearing = double.tryParse(data['course']?.toString() ?? '0') ?? 0.0;
      });

      if (_vehicleAnnotation != null) {
        _vehicleAnnotation!.iconRotate = _bearing;
      }

      _animateMarkerTo(lat, lng);
    } catch (e) {
      print('❌ Error parsing message: $e');
    }
  }

  double _convertToDecimalDegrees(String coord, String direction) {
    if (coord.isEmpty) return 0.0;
    final double value = double.tryParse(coord) ?? 0.0;
    final double degrees = (value ~/ 100).toDouble();
    final double minutes = value - (degrees * 100);
    double decimal = degrees + (minutes / 60);
    if (direction == 'S' || direction == 'W') decimal *= -1;
    return decimal;
  }

  // ─── Smooth animation ─────────────────────────────────────────────────────

  void _animateMarkerTo(double newLat, double newLng) {
    final fromLat = _animLat;
    final fromLng = _animLng;

    if (_moveListener != null) {
      _moveController.removeListener(_moveListener!);
    }

    _moveController.stop();
    _moveController.duration = const Duration(milliseconds: 800);

    _moveListener = () {
      final t = Curves.easeInOut.transform(_moveController.value);
      _animLat = fromLat + (newLat - fromLat) * t;
      _animLng = fromLng + (newLng - fromLng) * t;

      final pt = Point(coordinates: Position(_animLng, _animLat));

      if (_vehicleAnnotation != null && _annotationManager != null) {
        _vehicleAnnotation!.geometry = pt;
        _annotationManager!.update(_vehicleAnnotation!);
      }

      mapboxMap?.setCamera(CameraOptions(center: pt, zoom: _currentZoom));
    };

    _moveController.addListener(_moveListener!);
    _moveController.forward(from: 0.0).then((_) {
      _animLat = newLat;
      _animLng = newLng;
    });
  }

  // ─── Icon loading ─────────────────────────────────────────────────────────

  Future<void> _loadCarIcon() async {
    carIcon = await _resizeAndLoadIcon('assets/green_car.png', 140);
    setState(() => isLoading = false);
  }

  Future<Uint8List> _resizeAndLoadIcon(String assetPath, int width) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? bytes = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return bytes!.buffer.asUint8List();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
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
                // ── Map ────────────────────────────────────────────
                Positioned.fill(
                  child: MapWidget(
                    styleUri: isDark
                        ? MapboxStyles.DARK
                        : MapboxStyles.MAPBOX_STREETS,
                    cameraOptions: CameraOptions(
                      center: Point(
                        coordinates: Position(
                          widget.longitude,
                          widget.latitude,
                        ),
                      ),
                      zoom: _currentZoom,
                    ),
                    onMapCreated: (MapboxMap map) {
                      mapboxMap = map;
                      map.annotations.createPointAnnotationManager().then((
                        manager,
                      ) {
                        _annotationManager = manager;
                        manager
                            .create(
                              PointAnnotationOptions(
                                geometry: Point(
                                  coordinates: Position(
                                    widget.longitude,
                                    widget.latitude,
                                  ),
                                ),
                                image: carIcon,
                                iconSize: 1.6,
                                iconRotate: _bearing,
                                textField: numberPlate.toUpperCase(),
                                textSize: 11.0,
                                textOffset: [0.0, 2.2],
                              ),
                            )
                            .then((ann) => _vehicleAnnotation = ann);
                      });
                    },
                  ),
                ),

                // ── Header ─────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 0,
                  right: 0,
                  child: _buildHeader(col),
                ),

                // ── Speed / status card ────────────────────────────
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _buildInfoCard(col),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(AppColors col) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(kRadiusSM),
                boxShadow: [kShadowMD],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: col.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(kRadiusSM),
                boxShadow: [kShadowMD],
              ),
              child: Row(
                children: [
                  const Icon(Icons.drive_eta_rounded, color: kBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    numberPlate.isNotEmpty
                        ? numberPlate.toUpperCase()
                        : 'Live Location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: col.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kSuccessGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 12,
                      color: kSuccessGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(AppColors col) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(kRadiusLG),
        boxShadow: [kShadowLG],
      ),
      child: Row(
        children: [
          // Speed dial
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: kBlue.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speed,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kBlue,
                  ),
                ),
                Text(
                  'km/h',
                  style: TextStyle(fontSize: 9, color: col.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Direction + device info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.navigation_rounded,
                      color: kBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _bearingToDirection(_bearing),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: col.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_bearing.toStringAsFixed(0)}°',
                      style: TextStyle(fontSize: 12, color: col.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Device: ${widget.deviceId}',
                  style: TextStyle(fontSize: 12, color: col.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // GPS indicator
          Column(
            children: [
              const Icon(
                Icons.gps_fixed_rounded,
                color: kSuccessGreen,
                size: 22,
              ),
              const SizedBox(height: 2),
              const Text(
                'GPS',
                style: TextStyle(
                  fontSize: 10,
                  color: kSuccessGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _bearingToDirection(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N'];
    return dirs[((bearing + 22.5) / 45).floor() % 8];
  }
}
