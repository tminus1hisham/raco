import 'package:atom/config/constants.dart';
import 'package:atom/controllers/geo_fence_controller.dart';
import 'package:atom/models/location_model.dart';
import 'package:atom/widgets/modal/infomation_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GeofencingScreen extends StatefulWidget {
  final String numberPlate;

  GeofencingScreen({required this.numberPlate});

  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  final MapController mapController = MapController();
  final GeoFenceController _geoFenceController = GeoFenceController();
  final TextEditingController radiusController = TextEditingController(
    text: '1.0',
  );

  LatLng? centerPoint;
  LatLng? drawStartPoint;
  double radiusKm = 1.0;
  bool isDrawingMode = true;
  bool isDrawing = false;
  List<LocationModel> geofenceZones = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildModeSelector(),
              if (!isDrawingMode) _buildRadiusInput(),
              Expanded(child: _buildMap()),
              _buildBottomPanel(),
            ],
          ),
        ),
        _buildLoadingOverlay(),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text('Geofencing', style: TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      actions: [
        IconButton(
          icon: Icon(Icons.format_clear_rounded),
          onPressed: _clearAllZones,
          tooltip: 'Clear All Zones',
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModeButton(true, Icons.gesture, 'Draw Circle'),
          _buildModeButton(false, Icons.place, 'Pin + Radius'),
        ],
      ),
    );
  }

  Widget _buildModeButton(bool isDrawMode, IconData icon, String label) {
    bool isActive = isDrawingMode == isDrawMode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          isDrawingMode = isDrawMode;
          centerPoint = null;
        }),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusInput() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.radio_button_unchecked, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(
            'Radius (km):',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: radiusController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '1.0',
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
                  setState(() => radiusKm = newRadius);
                }
              },
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Listener(
          onPointerMove: (event) => _handlePointerMove(event),
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(-1.2842328448615796, 36.816382318562034),
              initialZoom: 13.0,
              onTap: isDrawingMode ? null : _onMapTap,
              onLongPress: isDrawingMode ? _onMapLongPress : null,
              onPointerUp: isDrawingMode ? _onPointerUp : null,
              interactionOptions: InteractionOptions(
                flags: isDrawing ? InteractiveFlag.none : InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.atom',
              ),
              _buildCircleLayer(),
              _buildMarkerLayer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleLayer() {
    List<CircleMarker> circles = geofenceZones
        .map(
          (zone) => CircleMarker(
            point: LatLng(
              double.parse(zone.latitude),
              double.parse(zone.longitude),
            ),
            radius: zone.radius.toDouble() * 1000,
            useRadiusInMeter: true,
            color: Colors.blue.withOpacity(0.2),
            borderColor: Colors.blue,
            borderStrokeWidth: 2,
          ),
        )
        .toList();

    if (centerPoint != null) {
      circles.add(
        CircleMarker(
          point: centerPoint!,
          radius: radiusKm * 1000,
          useRadiusInMeter: true,
          color: Colors.orange.withOpacity(0.3),
          borderColor: isDrawing ? Colors.red : Colors.orange,
          borderStrokeWidth: isDrawing ? 3 : 2,
        ),
      );
    }

    return CircleLayer(circles: circles);
  }

  Widget _buildMarkerLayer() {
    List<Marker> markers = geofenceZones
        .map(
          (zone) => _createMarker(
            LatLng(double.parse(zone.latitude), double.parse(zone.longitude)),
            Colors.blue,
            Icons.gps_fixed,
          ),
        )
        .toList();

    if (centerPoint != null) {
      markers.add(
        _createMarker(
          centerPoint!,
          isDrawing ? Colors.red : Colors.orange,
          isDrawing ? Icons.circle : Icons.place,
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  Marker _createMarker(LatLng point, Color color, IconData icon) {
    return Marker(
      point: point,
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (centerPoint != null) _buildPreviewInfo(),
          _buildActionButtons(),
          SizedBox(height: 8),
          _buildInstructionText(),
        ],
      ),
    );
  }

  Widget _buildPreviewInfo() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDrawing ? Colors.red[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDrawing ? Colors.red[200]! : Colors.orange[200]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDrawing ? Icons.gesture : Icons.info_outline,
              color: isDrawing ? Colors.red[700] : Colors.orange[700],
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                isDrawing
                    ? 'Drawing... Move to adjust: ${radiusKm.toStringAsFixed(2)}km'
                    : 'Preview: ${radiusKm.toStringAsFixed(2)}km radius',
                style: TextStyle(
                  color: isDrawing ? Colors.red[700] : Colors.orange[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (centerPoint != null && !isDrawing) ...[
          Expanded(
            child: _buildButton(
              'Add Zone',
              Icons.add_circle_outline,
              Colors.green,
              _addGeofenceZone,
            ),
          ),
          SizedBox(width: 12),
        ],
        Expanded(
          child: _buildButton(
            'Submit (${geofenceZones.length})',
            Icons.send,
            Colors.blue,
            (geofenceZones.isEmpty || isDrawing) ? null : _submitGeofences,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInstructionText() {
    String instruction = isDrawingMode
        ? (isDrawing
              ? 'Release to finish drawing'
              : 'Long press and drag to draw')
        : 'Tap on the map to place a pin';

    return Text(
      instruction,
      style: TextStyle(
        color: isDrawing ? Colors.red[600] : Colors.grey[600],
        fontSize: 12,
        fontWeight: isDrawing ? FontWeight.w600 : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (_geoFenceController.isLoading.value) {
        return Container(
          color: Colors.black.withOpacity(0.3),
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

  void _handlePointerMove(PointerMoveEvent event) {
    if (isDrawingMode && isDrawing) {
      final localPoint = (context.findRenderObject() as RenderBox)
          .globalToLocal(event.position);
      final latLng = mapController.pointToLatLng(
        CustomPoint(localPoint.dx, localPoint.dy),
      );
      if (latLng != null && drawStartPoint != null) {
        final distance =
            Distance().as(LengthUnit.Meter, drawStartPoint!, latLng) / 1000;
        setState(() => radiusKm = distance.clamp(0.1, 50.0));
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!isDrawingMode && !isDrawing) {
      setState(() => centerPoint = point);
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    if (isDrawingMode && !isDrawing) {
      setState(() {
        isDrawing = true;
        drawStartPoint = point;
        centerPoint = point;
        radiusKm = 0.1;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event, LatLng point) {
    if (isDrawingMode && isDrawing) {
      setState(() => isDrawing = false);
      if (radiusKm > 0.1) _showDrawingCompleteDialog();
    }
  }

  void _showDrawingCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Circle Drawn'),
          ],
        ),
        content: Text(
          'Circle with ${radiusKm.toStringAsFixed(2)}km radius.\n\nAdd as geofence zone?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                centerPoint = null;
                drawStartPoint = null;
              });
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addGeofenceZone();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Add Zone'),
          ),
        ],
      ),
    );
  }

  void _addGeofenceZone() {
    if (centerPoint != null) {
      setState(() {
        geofenceZones.add(
          LocationModel(
            name: 'Zone ${geofenceZones.length + 1}',
            latitude: centerPoint!.latitude.toString(),
            longitude: centerPoint!.longitude.toString(),
            radius: radiusKm.round(),
            numberPlate: widget.numberPlate,
          ),
        );
        centerPoint = null;
        drawStartPoint = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('Zone added!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearAllZones() {
    if (geofenceZones.isNotEmpty) {
      setState(() {
        geofenceZones.clear();
        centerPoint = null;
        drawStartPoint = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All zones cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _submitGeofences() async {
    for (final zone in geofenceZones) {
      await _addGeofence(zone);
    }

    // Clear zones after successful submission
    setState(() {
      geofenceZones.clear();
      centerPoint = null;
      drawStartPoint = null;
    });
  }

  Future<void> _addGeofence(LocationModel zone) async {
    _geoFenceController.numberPlate.value = widget.numberPlate;
    _geoFenceController.fullName.value = zone.name;
    _geoFenceController.latitude.value = zone.latitude.toString();
    _geoFenceController.longitude.value = zone.longitude.toString();
    _geoFenceController.radius.value = zone.radius.round();

    bool success = await _geoFenceController.addGeoFence(context);

    // Show dialog but DON'T await it - this prevents navigation issues
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
  }
}
