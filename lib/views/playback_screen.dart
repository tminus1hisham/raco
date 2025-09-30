import 'dart:async';
import 'dart:math' as math;

import 'package:atom/config/constants.dart';
import 'package:atom/controllers/playback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PlaybackScreen extends StatefulWidget {
  final String numberPlate;

  PlaybackScreen({required this.numberPlate});

  @override
  _PlaybackScreenState createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  final MapController _mapController = MapController();
  final PlaybackController controller = Get.put(PlaybackController());

  DateTime? _pickedDate;
  Timer? _playbackTimer;
  int _currentIndex = 0;
  bool _isPlaying = false;

  Size getMarkerSize(bool isOnline, int ignitionStatus) {
    if (isOnline && ignitionStatus == 1) {
      return const Size(75, 75); // online and moving
    } else if (!isOnline) {
      return const Size(60, 60); // offline
    } else {
      return const Size(67, 67); // online but idle/stopped
    }
  }

  /// ✅ Calculate bearing between two points
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lon1 = from.longitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final lon2 = to.longitude * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x);
    bearing = bearing * 180 / math.pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// ✅ Get bearing for current position
  double _getCurrentBearing(List history, int currentIndex) {
    // If we have valid course data from the record, use it
    final currentRecord = history[currentIndex];
    final course = double.tryParse(currentRecord.course.toString());

    if (course != null && course >= 0 && course <= 360) {
      return course;
    }

    // Otherwise calculate bearing from previous and next points
    if (currentIndex > 0 && currentIndex < history.length - 1) {
      final prevPoint = LatLng(
        double.parse(history[currentIndex - 1].lt),
        double.parse(history[currentIndex - 1].lg),
      );
      final nextPoint = LatLng(
        double.parse(history[currentIndex + 1].lt),
        double.parse(history[currentIndex + 1].lg),
      );
      return _calculateBearing(prevPoint, nextPoint);
    } else if (currentIndex > 0) {
      // If we're at the end, use the previous point
      final prevPoint = LatLng(
        double.parse(history[currentIndex - 1].lt),
        double.parse(history[currentIndex - 1].lg),
      );
      final currentPoint = LatLng(
        double.parse(currentRecord.lt),
        double.parse(currentRecord.lg),
      );
      return _calculateBearing(prevPoint, currentPoint);
    } else if (currentIndex < history.length - 1) {
      // If we're at the start, use the next point
      final currentPoint = LatLng(
        double.parse(currentRecord.lt),
        double.parse(currentRecord.lg),
      );
      final nextPoint = LatLng(
        double.parse(history[currentIndex + 1].lt),
        double.parse(history[currentIndex + 1].lg),
      );
      return _calculateBearing(currentPoint, nextPoint);
    }

    return 0.0; // Default bearing
  }

  /// ✅ Speed-based marker image
  String getMarkerImage(String speed) {
    final spd = double.tryParse(speed) ?? 0.0;

    if (spd == 0) {
      return "assets/blue_car.png"; // parked
    } else if (spd > 80) {
      return "assets/red_car.png"; // overspeed
    } else {
      return "assets/green_car.png"; // moving
    }
  }

  /// ✅ Determine if vehicle is online (for playback context)
  /// In playback, we can consider it "online" if it's the most recent data point
  /// or based on timestamp comparison
  bool _isVehicleOnline(List history, int currentIndex) {
    // For playback, you might want different logic. Here are some options:

    // Option 1: Consider all historical data as "online" since we're playing it back
    // return true;

    // Option 2: Check if the current point is within a reasonable time window
    final currentRecord = history[currentIndex];
    final currentTime = DateTime.fromMillisecondsSinceEpoch(
      currentRecord.dt * 1000,
    );
    final now = DateTime.now();
    final difference = now.difference(currentTime);

    // Consider online if data is less than 15 minutes old (adjust as needed)
    return difference.inMinutes < 15;

    // Option 3: Use actual online status from your data if available
    // return currentRecord.isOnline ?? true;
  }

  /// ✅ Get ignition status from record
  /// You'll need to adjust this based on your data structure
  int _getIgnitionStatus(dynamic record) {
    // Adjust this based on how ignition status is stored in your data
    // Some common ways:

    // If you have direct ignition field:
    // return record.ignition ?? 0;

    // If ignition is derived from speed:
    final speed = double.tryParse(record.spd.toString()) ?? 0.0;
    return speed > 0 ? 1 : 0;

    // If you have specific ignition field name, use that:
    // return record.ign ?? 0;
  }

  /// ✅ Build colored polylines based on speed
  List<Polyline> _buildColoredPolylines(List history) {
    final polylines = <Polyline>[];

    for (int i = 0; i < history.length - 1; i++) {
      final current = history[i];
      final next = history[i + 1];

      final currentPoint = LatLng(
        double.parse(current.lt),
        double.parse(current.lg),
      );
      final nextPoint = LatLng(double.parse(next.lt), double.parse(next.lg));

      final speed = double.tryParse(current.spd.toString()) ?? 0.0;

      final color = speed == 0
          ? Colors.orange
          : speed > 80
          ? Colors.red
          : Colors.blue;

      polylines.add(
        Polyline(
          points: [currentPoint, nextPoint],
          strokeWidth: 6.0,
          color: color,
        ),
      );
    }

    return polylines;
  }

  /// ✅ Start playback animation
  void _startPlayback(List history) {
    if (_isPlaying) return;
    _isPlaying = true;
    _currentIndex = 0;

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      if (_currentIndex >= history.length - 1) {
        timer.cancel();
        _isPlaying = false;
        return;
      }
      setState(() {
        _currentIndex++;
      });

      final current = history[_currentIndex];
      _mapController.move(
        LatLng(double.parse(current.lt), double.parse(current.lg)),
        _mapController.camera.zoom,
      );
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _isPlaying = false;
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _isPlaying = false;
    setState(() {
      _currentIndex = 0;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _pickedDate = picked);

      final String formattedDate = picked.toUtc().toIso8601String();
      await controller.fetchHistory(widget.numberPlate, formattedDate);

      if (controller.history.isNotEmpty) {
        _stopPlayback();
      }
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Play Back", style: TextStyle(color: kWhite)),
        backgroundColor: kBlue,
        iconTheme: IconThemeData(color: kWhite),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
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

        if (controller.history.isEmpty) {
          return Center(child: Text("No data for selected date"));
        }

        final history = controller.history.reversed.toList();
        final currentRecord = history[_currentIndex];
        final currentPoint = LatLng(
          double.parse(currentRecord.lt),
          double.parse(currentRecord.lg),
        );

        final markerImage = getMarkerImage(currentRecord.spd);

        // Get proper bearing
        final bearing = _getCurrentBearing(history, _currentIndex);

        // Get marker size based on online status and ignition
        final isOnline = _isVehicleOnline(history, _currentIndex);
        final ignitionStatus = _getIgnitionStatus(currentRecord);
        final markerSize = getMarkerSize(isOnline, ignitionStatus);

        String _formatDateTime(DateTime dateTime) {
          final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
          final minute = dateTime.minute.toString().padLeft(2, '0');
          final second = dateTime.second.toString().padLeft(2, '0');
          final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
          return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute:$second $amPm';
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPoint,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.atom',
                ),
                PolylineLayer(polylines: _buildColoredPolylines(history)),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPoint,
                      width: markerSize.width,
                      height: markerSize.height,
                      child: Transform.rotate(
                        angle: bearing * math.pi / 180, // Convert to radians
                        child: Image.asset(markerImage),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Plate: ${currentRecord.rg}",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Text(
                      "Speed: ${currentRecord.spd} km/h",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    Text(
                      "Ignition: ${ignitionStatus == 1 ? 'ON' : 'OFF'}",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    // Text(
                    //   "Bearing: ${bearing.toStringAsFixed(1)}°",
                    //   style: TextStyle(color: Colors.white),
                    // ),
                    Text(
                      "Time: ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(currentRecord.dt * 1000))}",
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            /// ✅ Playback controls
            // Positioned(
            //   bottom: 20,
            //   left: 0,
            //   right: 0,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       FloatingActionButton(
            //         heroTag: "play",
            //         onPressed: () => _startPlayback(history),
            //         backgroundColor: kBlue,
            //         child: Icon(Icons.play_arrow, color: kWhite),
            //       ),
            //       SizedBox(width: 20),
            //       FloatingActionButton(
            //         heroTag: "pause",
            //         onPressed: _pausePlayback,
            //         backgroundColor: kBlue,
            //         child: Icon(Icons.pause, color: kWhite),
            //       ),
            //       SizedBox(width: 20),
            //       FloatingActionButton(
            //         heroTag: "stop",
            //         onPressed: _stopPlayback,
            //         backgroundColor: kBlue,
            //         child: Icon(Icons.stop, color: kWhite),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        );
      }),
    );
  }
}
