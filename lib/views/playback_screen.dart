import 'package:atom/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart'; // for formatting time
import 'package:latlong2/latlong.dart';

class PlaybackScreen extends StatefulWidget {
  @override
  _PlaybackScreenState createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final MapController _mapController = MapController();

  LatLng? _selectedPoint; // track which marker is tapped
  String? _selectedMessage;

  final List<CarRoute> carRoutes = [
    CarRoute(
      name: "Car A",
      color: Colors.blue,
      points: [
        CarPoint(
          position: LatLng(-1.2671967137432802, 36.80382743368107),
          time: DateTime.utc(2025, 9, 19, 8, 0, 0),
        ),
        CarPoint(
          position: LatLng(-1.2714561687422843, 36.808152658068515),
          time: DateTime.utc(2025, 9, 19, 8, 5, 0),
        ),
        CarPoint(
          position: LatLng(-1.276433775908415, 36.81348502573813),
          time: DateTime.utc(2025, 9, 19, 8, 10, 0),
        ),
        CarPoint(
          position: LatLng(-1.2817113819634032, 36.815034476941435),
          time: DateTime.utc(2025, 9, 19, 8, 15, 0),
        ),
        CarPoint(
          position: LatLng(-1.2797103440514344, 36.82054875802763),
          time: DateTime.utc(2025, 9, 19, 8, 20, 0),
        ),
        CarPoint(
          position: LatLng(-1.269454142430596, 36.83157928153062),
          time: DateTime.utc(2025, 9, 19, 8, 25, 0),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Play Back", style: TextStyle(color: kWhite)),
        backgroundColor: kBlue,
        iconTheme: IconThemeData(color: kWhite),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: carRoutes[0].points.last.position,
              initialZoom: 15.0,
              onTap: (_, __) {
                // hide tooltip when tapping map
                setState(() {
                  _selectedPoint = null;
                  _selectedMessage = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.atom',
              ),

              // Draw polylines for each car
              PolylineLayer(
                polylines: carRoutes.map((car) {
                  return Polyline(
                    points: car.points.map((p) => p.position).toList(),
                    strokeWidth: 8.0,
                    color: car.color,
                  );
                }).toList(),
              ),

              // Draw markers
              MarkerLayer(
                markers: [
                  // Pins for each point
                  ...carRoutes.expand(
                    (car) => car.points.map((point) {
                      final localTime = point.time.toLocal();
                      final formatted = DateFormat(
                        "yyyy-MM-dd HH:mm:ss",
                      ).format(localTime);

                      return Marker(
                        point: point.position,
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPoint = point.position;
                              _selectedMessage =
                                  "UTC: ${point.time.toIso8601String()}\nLocal: $formatted";
                            });
                          },
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),

                  // Car marker at last position
                  ...carRoutes.map((car) {
                    final lastPoint = car.points.last;
                    return Marker(
                      point: lastPoint.position,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: car.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Tooltip bubble overlay
          if (_selectedPoint != null && _selectedMessage != null)
            Positioned(
              left: 20,
              right: 20,
              top: 20,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedMessage!,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CarRoute {
  final String name;
  final Color color;
  final List<CarPoint> points;

  CarRoute({required this.name, required this.color, required this.points});
}

class CarPoint {
  final LatLng position;
  final DateTime time; // stored in UTC

  CarPoint({required this.position, required this.time});
}
