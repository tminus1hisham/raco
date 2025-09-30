import 'package:atom/config/constants.dart';
import 'package:atom/controllers/playback_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

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

  String getMarkerImage(String speed) {
    final spd = double.tryParse(speed) ?? 0.0;

    if (spd == 0) {
      return "assets/blue_car.png"; // parked
    } else if (spd > 40) {
      return "assets/red_car.png"; // overspeed
    } else {
      return "assets/green_car.png"; // moving normally
    }
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
          : speed > 40
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

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
      });
      final String formattedDate = picked.toUtc().toIso8601String();
      controller.fetchHistory(widget.numberPlate, formattedDate);
    }
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
          return Center(child: CircularProgressIndicator());
        }

        if (controller.history.isEmpty) {
          return Center(child: Text("No data for selected date"));
        }

        final points = controller.history.reversed.map((rec) {
          return LatLng(double.parse(rec.lt), double.parse(rec.lg));
        }).toList();

        // Latest vehicle record
        final latestRecord = controller.history.first;

        final latestPoint = LatLng(
          double.parse(latestRecord.lt),
          double.parse(latestRecord.lg),
        );

        final markerImage = getMarkerImage(latestRecord.spd);

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: points.first, initialZoom: 15.0),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.atom',
            ),
            PolylineLayer(
              polylines: _buildColoredPolylines(controller.history),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latestPoint,
                  width: 50,
                  height: 50,
                  child: Image.asset(markerImage), // ✅ Custom marker image
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
