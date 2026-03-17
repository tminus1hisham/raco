import 'package:atom/config/constants.dart';
import 'package:atom/controllers/fetch_geofence_controller.dart';
import 'package:atom/controllers/geo_fence_controller.dart';
import 'package:atom/models/geofence_model.dart';
import 'package:atom/widgets/buttons/custom_button.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GeofencingScreen extends StatefulWidget {
  final String numberPlate;

  GeofencingScreen({required this.numberPlate});

  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  GoogleMapController? mapController;
  final GeoFenceController _geoFenceController = GeoFenceController();
  final FetchGeofenceController _fetchGeofenceController =
      FetchGeofenceController();

  final TextEditingController zoneNameController = TextEditingController();
  final TextEditingController radiusController = TextEditingController(
    text: '0.0',
  );

  LatLng? selectedPoint;
  double radiusKm = 0.0;
  List<GeofenceModel> existingGeofences = [];
  GeofenceModel? selectedGeofence;
  bool isAddingGeofence = false;

  Set<Marker> markers = {};
  Set<Circle> circles = {};
  bool isSaveEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadExistingGeofences();
  }

  @override
  void dispose() {
    zoneNameController.dispose();
    radiusController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGeofences() async {
    await _fetchGeofenceController.fetchGeofence(widget.numberPlate);

    setState(() {
      existingGeofences = _fetchGeofenceController.geofences;
      _updateMapMarkers();
    });
  }

  void _updateMapMarkers() {
    markers.clear();
    circles.clear();

    // Show only selected geofence
    if (selectedGeofence != null) {
      final latLng = LatLng(
        double.parse(selectedGeofence!.latitude),
        double.parse(selectedGeofence!.longitude),
      );

      markers.add(
        Marker(
          markerId: MarkerId('selected_geofence'),
          position: latLng,
          infoWindow: InfoWindow(title: selectedGeofence!.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      circles.add(
        Circle(
          circleId: CircleId('selected_circle'),
          center: latLng,
          radius: selectedGeofence!.radius.toDouble(),
          fillColor: kBlue.withValues(alpha: 0.2),
          strokeColor: kBlue,
          strokeWidth: 2,
        ),
      );
    }

    // Add new pin if adding geofence
    if (isAddingGeofence && selectedPoint != null) {
      markers.add(
        Marker(
          markerId: MarkerId('new_point'),
          position: selectedPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );

      circles.add(
        Circle(
          circleId: CircleId('new_circle'),
          center: selectedPoint!,
          radius: radiusKm * 1000,
          fillColor: Colors.orange.withValues(alpha: 0.3),
          strokeColor: Colors.orange,
          strokeWidth: 2,
        ),
      );
    }

    setState(() {});
  }

  void _onMapTap(LatLng point) {
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
      final latLng = LatLng(
        double.parse(geofence.latitude),
        double.parse(geofence.longitude),
      );

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
    }

    _updateMapMarkers();
  }

  Future<void> _addGeofenceZone() async {
    if (selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please tap on the map to select a location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (zoneNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a zone name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _geoFenceController.numberPlate.value = widget.numberPlate;
    _geoFenceController.fullName.value = zoneNameController.text.trim();
    _geoFenceController.latitude.value = selectedPoint!.latitude.toString();
    _geoFenceController.longitude.value = selectedPoint!.longitude.toString();
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: kBgGrey,
          appBar: AppBar(
            title: Text(
              'Geofencing',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: kWhite,
            foregroundColor: kBlack,
            elevation: 0.5,
          ),
          body: Column(
            children: [
              if (!isAddingGeofence) _buildGeofenceDropdown(),
              if (isAddingGeofence) _buildZoneNameInput(),
              Expanded(child: _buildMap()),
              _buildBottomPanel(),
            ],
          ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildGeofenceDropdown() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<GeofenceModel>(
          isExpanded: true,
          hint: Text('Select existing geofence to view'),
          value: selectedGeofence,
          icon: Icon(Icons.arrow_drop_down),
          items: existingGeofences.map((GeofenceModel geofence) {
            return DropdownMenuItem<GeofenceModel>(
              value: geofence,
              child: Text('${geofence.name} (${geofence.radius / 1000}km)'),
            );
          }).toList(),
          onChanged: _onGeofenceSelected,
        ),
      ),
    );
  }

  Widget _buildZoneNameInput() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),

      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text("Zone Name"),
                SizedBox(height: 5),
                TextField(
                  controller: zoneNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter zone name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (_) => _checkSaveButtonState(),
                ),
              ],
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text("Radius ( KM )"),
                SizedBox(height: 5),
                TextField(
                  controller: radiusController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(
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

  Widget _buildMap() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(-1.2842328448615796, 36.816382318562034),
            zoom: 13.0,
          ),
          onTap: _onMapTap,
          markers: markers,
          circles: circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kWhite,
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
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
                      // Start adding
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
            SizedBox(width: 5),
            if (isAddingGeofence)
              Expanded(
                child: CustomButton(
                  callBackFunction: () {
                    if (isSaveEnabled) {
                      _addGeofenceZone();
                    }
                  },
                  label: "Save",
                  backgroundColor: isSaveEnabled ? kBlue : kLightGrey,
                  // grey when inactive
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
          color: kBlack.withValues(alpha: 0.3),
          child: Center(
            child: LoadingAnimationWidget.fourRotatingDots(
              color: kBlue,
              size: 50,
            ),
          ),
        );
      }
      return SizedBox.shrink();
    });
  }
}
