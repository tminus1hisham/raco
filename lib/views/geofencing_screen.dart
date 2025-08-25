import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibration/vibration.dart';

class GeofencingScreen extends StatefulWidget {
  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  final MapController mapController = MapController();
  final TextEditingController radiusController = TextEditingController(
    text: '1.0',
  );

  LatLng? centerPoint;
  LatLng? drawStartPoint;
  double radiusKm = 1.0;
  bool isDrawingMode = true;
  bool isDrawing = false;
  List<GeofenceZone> geofenceZones = [];

  Future<void> mediumImpact() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50, amplitude: 128);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Geofencing Setup',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: _clearAllZones,
            tooltip: 'Clear All Zones',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildModeSelector(),
          if (!isDrawingMode) _buildRadiusInput(),
          Expanded(child: _buildMapSection()),
          _buildBottomPanel(),
        ],
      ),
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
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                isDrawingMode = true;
                centerPoint = null;
              }),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDrawingMode ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gesture,
                      color: isDrawingMode ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Draw Circle',
                      style: TextStyle(
                        color: isDrawingMode ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                isDrawingMode = false;
                centerPoint = null;
              }),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isDrawingMode ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.place,
                      color: !isDrawingMode ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pin + Radius',
                      style: TextStyle(
                        color: !isDrawingMode ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                  borderSide: BorderSide(color: Colors.grey[300]!),
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
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
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
          onPointerMove: (event) {
            if (isDrawingMode && isDrawing) {
              final localPoint = (context.findRenderObject() as RenderBox)
                  .globalToLocal(event.position);

              final latLng = mapController.pointToLatLng(
                CustomPoint(localPoint.dx, localPoint.dy),
              );

              if (latLng != null) {
                _onPointerMove(event, latLng);
              }
            }
          },
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
              // Draw existing geofence circles
              CircleLayer(
                circles: geofenceZones
                    .map(
                      (zone) => CircleMarker(
                        point: zone.center,
                        radius: zone.radiusKm * 1000,
                        useRadiusInMeter: true,
                        color: Colors.blue.withOpacity(0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(),
              ),
              if (centerPoint != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: centerPoint!,
                      radius: radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: Colors.orange.withOpacity(0.3),
                      borderColor: isDrawing ? Colors.red : Colors.orange,
                      borderStrokeWidth: isDrawing ? 3 : 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  ...geofenceZones.map(
                    (zone) => Marker(
                      point: zone.center,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
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
                        child: Icon(
                          Icons.gps_fixed,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (centerPoint != null)
                    Marker(
                      point: centerPoint!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDrawing ? Colors.red : Colors.orange,
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
                        child: Icon(
                          isDrawing ? Icons.circle : Icons.place,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
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
          if (centerPoint != null) ...[
            Container(
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
                          ? 'Drawing... Move your finger to adjust radius: ${radiusKm.toStringAsFixed(2)}km'
                          : 'Preview: ${centerPoint!.latitude.toStringAsFixed(4)}, ${centerPoint!.longitude.toStringAsFixed(4)} • ${radiusKm.toStringAsFixed(2)}km radius',
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
            SizedBox(height: 12),
          ],
          Row(
            children: [
              if (centerPoint != null && !isDrawing) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addGeofenceZone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Zone',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: (geofenceZones.isEmpty || isDrawing)
                      ? null
                      : _submitGeofences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Submit (${geofenceZones.length})',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isDrawingMode)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                isDrawing
                    ? 'Release to finish drawing the circle'
                    : 'Long press and drag on the map to draw a circle',
                style: TextStyle(
                  color: isDrawing ? Colors.red[600] : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isDrawing ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (!isDrawingMode)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tap on the map to place a pin, then add the zone',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!isDrawingMode && !isDrawing) {
      setState(() {
        centerPoint = point;
      });
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    if (isDrawingMode && !isDrawing) {
      setState(() {
        isDrawing = true;
        drawStartPoint = point;
        centerPoint = point;
        radiusKm = 0.1; // start tiny
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event, LatLng point) {
    if (isDrawingMode && isDrawing && drawStartPoint != null) {
      final Distance distance = Distance();
      double distanceInMeters = distance.as(
        LengthUnit.Meter,
        drawStartPoint!,
        point,
      );
      double distanceInKm = distanceInMeters / 1000;
      setState(() {
        radiusKm = distanceInKm.clamp(0.1, 50.0);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event, LatLng point) async {
    if (isDrawingMode && isDrawing) {
      setState(() {
        isDrawing = false;
      });

      if (radiusKm > 0.1) {
        _showDrawingCompleteDialog();
      }
    }
  }

  void _showDrawingCompleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Circle Drawn'),
            ],
          ),
          content: Text(
            'You\'ve drawn a circle with ${radiusKm.toStringAsFixed(2)}km radius.\n\nWould you like to add this as a geofence zone?',
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
        );
      },
    );
  }

  void _addGeofenceZone() {
    if (centerPoint != null) {
      setState(() {
        geofenceZones.add(
          GeofenceZone(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            center: centerPoint!,
            radiusKm: radiusKm,
            name: 'Zone ${geofenceZones.length + 1}',
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
              Text('Geofence zone added successfully!'),
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
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _submitGeofences() {
    print('=== GEOFENCE SUBMISSION ===');
    print('Total Zones: ${geofenceZones.length}');

    for (int i = 0; i < geofenceZones.length; i++) {
      final zone = geofenceZones[i];
      print('\n--- Zone ${i + 1} ---');
      print('ID: ${zone.id}');
      print('Name: ${zone.name}');
      print('Center: ${zone.center.latitude}, ${zone.center.longitude}');
      print('Radius: ${zone.radiusKm} km');
      print('Created: ${DateTime.now()}');
    }

    print('\n=== END SUBMISSION ===');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${geofenceZones.length} geofence zone(s) submitted! Check console for details.',
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class GeofenceZone {
  final String id;
  final LatLng center;
  final double radiusKm;
  final String name;

  GeofenceZone({
    required this.id,
    required this.center,
    required this.radiusKm,
    required this.name,
  });

  @override
  String toString() {
    return 'GeofenceZone{id: $id, center: $center, radiusKm: $radiusKm, name: $name}';
  }
}
