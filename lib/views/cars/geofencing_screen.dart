import 'package:atom/config/app_theme.dart';
import 'package:atom/config/constants.dart';
import 'package:atom/controllers/fetch_geofence_controller.dart';
import 'package:atom/controllers/geo_fence_controller.dart';
import 'package:atom/models/geofence_model.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class GeofencingScreen extends StatefulWidget {
  final String numberPlate;

  GeofencingScreen({required this.numberPlate});

  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  MapboxMap? mapboxMap;
  Point? selectedPoint;
  final GeoFenceController _geoFenceController = GeoFenceController();
  final FetchGeofenceController _fetchGeofenceController =
      FetchGeofenceController();

  final TextEditingController zoneNameController = TextEditingController();
  final TextEditingController radiusController = TextEditingController(
    text: '0.0',
  );

  List<PointAnnotationOptions> markers = [];
  List<CircleAnnotationOptions> circles = [];
  GeofenceModel? selectedGeofence;
  bool isAddingGeofence = false;
  bool isSaveEnabled = false;
  double radiusKm = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingGeofences();
  }

  @override
  void dispose() {
    zoneNameController.dispose();
    radiusController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGeofences() async {
    await _fetchGeofenceController.fetchGeofence(widget.numberPlate);

    setState(() {
      _updateMapMarkers();
    });
  }

  void _updateMapMarkers() {
    markers.clear();
    circles.clear();

    if (selectedGeofence != null) {
      final point = Point(
        coordinates: Position(
          double.parse(selectedGeofence!.longitude),
          double.parse(selectedGeofence!.latitude),
        ),
      );
      markers.add(
        PointAnnotationOptions(
          geometry: point,
          iconSize: 1.5,
          iconImage: "assets/blue_car.png",
          textField: selectedGeofence!.name,
          textSize: 12.0,
        ),
      );
      circles.add(
        CircleAnnotationOptions(
          geometry: point,
          circleRadius: selectedGeofence!.radius.toDouble(),
          circleColor: kBlue.withValues(alpha: 0.2).value,
          circleStrokeColor: kBlue.value,
          circleStrokeWidth: 2.0,
        ),
      );
    }

    if (isAddingGeofence && selectedPoint != null) {
      markers.add(
        PointAnnotationOptions(
          geometry: selectedPoint!,
          iconSize: 1.5,
          iconImage: "assets/orange_car.png",
          textField: "New Point",
          textSize: 12.0,
        ),
      );
      circles.add(
        CircleAnnotationOptions(
          geometry: selectedPoint!,
          circleRadius: radiusKm * 1000,
          circleColor: Colors.orange.withValues(alpha: 0.3).value,
          circleStrokeColor: Colors.orange.value,
          circleStrokeWidth: 2.0,
        ),
      );
    }

    setState(() {});
  }

  void _onMapTap(Point point) {
    if (!isAddingGeofence) return;

    setState(() {
      selectedPoint = point;
      selectedGeofence = null;
    });
    _updateMapMarkers();
  }

  void _onGeofenceSelected(GeofenceModel? geofence) {
    setState(() {
      selectedGeofence = geofence;
      selectedPoint = null;
    });

    if (geofence != null) {
      final point = Point(
        coordinates: Position(
          double.parse(geofence.longitude),
          double.parse(geofence.latitude),
        ),
      );

      mapboxMap?.flyTo(CameraOptions(center: point, zoom: 14.0), null);
    }

    _updateMapMarkers();
  }

  Future<void> _addGeofenceZone() async {
    if (selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap on the map to select a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (zoneNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a zone name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _geoFenceController.numberPlate.value = widget.numberPlate;
    _geoFenceController.fullName.value = zoneNameController.text.trim();
    _geoFenceController.latitude.value = selectedPoint!.coordinates.lat
        .toString();
    _geoFenceController.longitude.value = selectedPoint!.coordinates.lng
        .toString();
    _geoFenceController.radius.value = radiusKm.round() * 1000;

    bool success = await _geoFenceController.addGeoFence(context);

    CustomAlertDialog(
      context: context,
      title: success ? "Success" : "Error",
      message: success
          ? "Geofence added successfully"
          : "Failed to add geofence",
      icon: success
          ? "assets/animations/Success.json"
          : "assets/animations/Failed.json",
      buttonColor: success ? kSuccessGreen : kRed,
    );

    if (success) {
      setState(() {
        selectedPoint = null;
        zoneNameController.clear();
        radiusController.text = '0.0';
        radiusKm = 0.0;
      });
      await _loadExistingGeofences();
    }
  }

  void _checkSaveButtonState() {
    final hasZoneName = zoneNameController.text.trim().isNotEmpty;
    final hasPin = selectedPoint != null;
    final hasRadius =
        double.tryParse(radiusController.text.trim()) != null &&
        double.parse(radiusController.text.trim()) > 0;

    setState(() {
      isSaveEnabled = hasZoneName && hasRadius && hasPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = context.isDark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: col.bg,
          appBar: AppBar(
            title: const Text(
              'Geofencing',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            // inherits backgroundColor and foregroundColor from AppBarTheme
          ),
          body: Column(
            children: [
              if (!isAddingGeofence) _buildGeofenceDropdown(col),
              if (isAddingGeofence) _buildZoneNameInput(),
              Expanded(child: _buildMap(isDark)),
              _buildBottomPanel(col),
            ],
          ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildGeofenceDropdown(AppColors col) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GeofenceModel>(
          isExpanded: true,
          dropdownColor: col.surface,
          hint: Text(
            'Select existing geofence to view',
            style: TextStyle(color: col.textSecondary),
          ),
          value: selectedGeofence,
          icon: Icon(Icons.arrow_drop_down, color: col.textSecondary),
          items: _fetchGeofenceController.geofences.map((
            GeofenceModel geofence,
          ) {
            return DropdownMenuItem<GeofenceModel>(
              value: geofence,
              child: Text(
                '${geofence.name} (${geofence.radius / 1000}km)',
                style: TextStyle(color: col.textPrimary),
              ),
            );
          }).toList(),
          onChanged: _onGeofenceSelected,
        ),
      ),
    );
  }

  Widget _buildZoneNameInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                const Text("Zone Name"),
                const SizedBox(height: 5),
                TextField(
                  controller: zoneNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter zone name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (_) => _checkSaveButtonState(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text("Radius ( KM )"),
                const SizedBox(height: 5),
                TextField(
                  controller: radiusController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    double? newRadius = double.tryParse(value);
                    if (newRadius != null && newRadius > 0) {
                      setState(() {
                        radiusKm = newRadius;
                        _updateMapMarkers();
                      });
                    }
                    _checkSaveButtonState();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MapWidget(
          styleUri: isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center:
                selectedPoint ??
                Point(
                  coordinates: Position(
                    36.816382318562034,
                    -1.2842328448615796,
                  ),
                ),
            zoom: 13.0,
          ),
          onMapCreated: (MapboxMap map) {
            mapboxMap = map;
            map.annotations.createPointAnnotationManager().then((manager) {
              if (markers.isNotEmpty) {
                manager.createMulti(markers);
              }
            });
            map.annotations.createCircleAnnotationManager().then((manager) {
              if (circles.isNotEmpty) {
                manager.createMulti(circles);
              }
            });
          },
          onTapListener: (context) => _onMapTap(context.point),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(AppColors col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomButton(
                callBackFunction: () {
                  setState(() {
                    if (isAddingGeofence) {
                      isAddingGeofence = false;
                      selectedPoint = null;
                      zoneNameController.clear();
                      radiusController.text = '0';
                      radiusKm = 0;
                      _updateMapMarkers();
                    } else {
                      isAddingGeofence = true;
                      selectedGeofence = null;
                      markers.clear();
                      circles.clear();
                    }
                  });
                },
                label: isAddingGeofence ? "Cancel" : "Add Geofence",
                backgroundColor: isAddingGeofence ? kRed : kBlue,
                txtColor: kWhite,
              ),
            ),
            const SizedBox(width: 5),
            if (isAddingGeofence)
              Expanded(
                child: CustomButton(
                  callBackFunction: () {
                    if (isSaveEnabled) {
                      _addGeofenceZone();
                    }
                  },
                  label: "Save",
                  backgroundColor: isSaveEnabled ? kBlue : col.border,
                  txtColor: kWhite,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (_geoFenceController.isLoading.value) {
        return Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: kBlue,
              size: 50,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
