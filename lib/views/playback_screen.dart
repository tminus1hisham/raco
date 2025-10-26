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
  double _playbackSpeed = 0.5; // 0.5x to 3x speed

  DateTime? _playbackStartTime;
  int _playbackStartIndex = 0;

  Size getMarkerSize(bool isOnline, int ignitionStatus) {
    if (isOnline && ignitionStatus == 1) {
      return const Size(40, 40);
    } else if (!isOnline) {
      return const Size(50, 50);
    } else {
      return const Size(57, 57);
    }
  }

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

  double _getCurrentBearing(List history, int currentIndex) {
    final currentRecord = history[currentIndex];
    final course = double.tryParse(currentRecord.course.toString());

    if (course != null && course >= 0 && course <= 360) {
      return course;
    }

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

    return 0.0;
  }

  String getMarkerImage(String speed) {
    final spd = double.tryParse(speed) ?? 0.0;
    return "assets/blue_car.png";
  }

  bool _isVehicleOnline(List history, int currentIndex) {
    final currentRecord = history[currentIndex];
    final currentTime = currentRecord.createdAt is String
        ? DateTime.parse(currentRecord.createdAt)
        : currentRecord.createdAt;
    final now = DateTime.now().toUtc();
    final difference = now.difference(currentTime);
    return difference.inMinutes < 15;
  }

  int _getIgnitionStatus(dynamic record) {
    final speed = double.tryParse(record.spd.toString()) ?? 0.0;
    return speed > 0 ? 1 : 0;
  }

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

  void _startPlayback(List history) {
    if (_isPlaying || history.isEmpty) return;

    setState(() {
      _isPlaying = true;
      _currentIndex = 0;
    });

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (200 ~/ _playbackSpeed)),
      // playbackSpeed affects rate
      (timer) {
        if (!_isPlaying || _currentIndex >= history.length - 1) {
          timer.cancel();
          setState(() => _isPlaying = false);
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
      },
    );
  }

  void _updatePlaybackPosition(List history) {
    if (_playbackStartTime == null) return;

    final elapsedSeconds =
        DateTime.now().difference(_playbackStartTime!).inMilliseconds / 1000.0;
    final totalPlaybackTime = _calculateTotalPlaybackTime(history);
    final progress = (elapsedSeconds * _playbackSpeed) / totalPlaybackTime;

    final newIndex =
        (_playbackStartIndex +
                (progress * (history.length - 1 - _playbackStartIndex)))
            .toInt();

    if (newIndex != _currentIndex && newIndex < history.length) {
      setState(() {
        _currentIndex = newIndex.clamp(0, history.length - 1);
      });

      // Smooth map movement
      final current = history[_currentIndex];
      _mapController.move(
        LatLng(double.parse(current.lt), double.parse(current.lg)),
        _mapController.camera.zoom,
      );
    }
  }

  double _calculateTotalPlaybackTime(List history) {
    if (history.length < 2) return 1.0;

    // Calculate total time based on actual timestamps if available
    final first = history.first;
    final last = history.last;

    if (first.createdAt != null && last.createdAt != null) {
      final startTime = first.createdAt is String
          ? DateTime.parse(first.createdAt)
          : first.createdAt;
      final endTime = last.createdAt is String
          ? DateTime.parse(last.createdAt)
          : last.createdAt;

      return endTime.difference(startTime).inSeconds.toDouble();
    }

    // Fallback: estimate based on average time between points
    return (history.length * 30).toDouble(); // Assume 30 seconds per point
  }

  // void _startPlayback(List history) {
  //   if (_isPlaying) return;
  //   setState(() => _isPlaying = true);
  //   _currentIndex = 0;
  //
  //   _playbackTimer?.cancel();
  //
  //   // Use a fixed fast interval and control speed by skipping frames
  //   _playbackTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
  //     if (_currentIndex >= history.length - 1) {
  //       timer.cancel();
  //       setState(() => _isPlaying = false);
  //       return;
  //     }
  //
  //     // Calculate how many frames to skip based on speed
  //     final skipFrames = (_playbackSpeed * 2).round();
  //
  //     setState(() {
  //       _currentIndex = math.min(
  //         _currentIndex + skipFrames,
  //         history.length - 1,
  //       );
  //     });
  //
  //     final current = history[_currentIndex];
  //     _mapController.move(
  //       LatLng(double.parse(current.lt), double.parse(current.lg)),
  //       _mapController.camera.zoom,
  //     );
  //   });
  // }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resumePlayback(List history) {
    if (_isPlaying || history.isEmpty) return;

    setState(() => _isPlaying = true);

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      Duration(milliseconds: (200 ~/ _playbackSpeed)),
      (timer) {
        if (!_isPlaying || _currentIndex >= history.length - 1) {
          timer.cancel();
          setState(() => _isPlaying = false);
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
      },
    );
  }

  // void _resumePlayback(List history) {
  //   if (_isPlaying) return;
  //   setState(() => _isPlaying = true);
  //
  //   _playbackTimer?.cancel();
  //
  //   _playbackTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
  //     if (_currentIndex >= history.length - 1) {
  //       timer.cancel();
  //       setState(() => _isPlaying = false);
  //       return;
  //     }
  //
  //     final skipFrames = (_playbackSpeed * 2).round();
  //
  //     setState(() {
  //       _currentIndex = math.min(
  //         _currentIndex + skipFrames,
  //         history.length - 1,
  //       );
  //     });
  //
  //     final current = history[_currentIndex];
  //     _mapController.move(
  //       LatLng(double.parse(current.lt), double.parse(current.lg)),
  //       _mapController.camera.zoom,
  //     );
  //   });
  // }

  // void _updatePlaybackSpeed(double newSpeed) {
  //   setState(() => _playbackSpeed = newSpeed);
  //   // No need to restart - the timer will pick up the new speed on next tick
  // }

  void _updatePlaybackSpeed(double newSpeed) {
    // When speed changes, reset the playback timing
    if (_isPlaying) {
      setState(() {
        _playbackSpeed = newSpeed;
        _playbackStartTime = DateTime.now();
        _playbackStartIndex = _currentIndex;
      });
    } else {
      setState(() => _playbackSpeed = newSpeed);
    }
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _currentIndex = 0;
      _playbackStartTime = null;
      _playbackStartIndex = 0;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kBlue, onPrimary: kWhite),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _pickedDate = picked);
      final String formattedDate = picked
          .add(const Duration(days: 1))
          .toUtc()
          .toIso8601String();

      await controller.fetchHistory(widget.numberPlate, formattedDate);
      if (controller.history.isNotEmpty) _stopPlayback();
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} $hour:$minute:$second $amPm';
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Playback",
          style: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kBlue,
        iconTheme: IconThemeData(color: kWhite),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Container(
            color: Colors.white,
            child: Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: kBlue,
                size: 50,
              ),
            ),
          );
        }

        if (controller.history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 20),
                Text(
                  "No playback data available",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 10),
                Text(
                  "Select a date to view vehicle history",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: Icon(Icons.calendar_today, size: 20),
                  label: Text(
                    _pickedDate == null ? "Select Date" : "Change Date",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: kWhite,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final history = controller.history.reversed.toList();
        final currentRecord = history[_currentIndex];
        final currentPoint = LatLng(
          double.parse(currentRecord.lt),
          double.parse(currentRecord.lg),
        );
        final markerImage = getMarkerImage(currentRecord.spd);
        final bearing = _getCurrentBearing(history, _currentIndex);
        final isOnline = _isVehicleOnline(history, _currentIndex);
        final ignitionStatus = _getIgnitionStatus(currentRecord);
        final markerSize = getMarkerSize(isOnline, ignitionStatus);

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
                        angle: (bearing + 180) * math.pi / 180,
                        child: Image.asset(markerImage),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Info Card
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentRecord.rg,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ignitionStatus == 1
                                  ? Colors.green[100]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ignitionStatus == 1 ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: ignitionStatus == 1
                                    ? Colors.green[800]
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              icon: Icons.speed,
                              label: "Speed",
                              value: "${currentRecord.spd} km/h",
                            ),
                          ),
                          // Expanded(
                          //   child: _InfoItem(
                          //     icon: Icons.access_time,
                          //     label: "Time",
                          //     value: _formatDateTime(
                          //       DateTime.fromMillisecondsSinceEpoch(
                          //         currentRecord.dt * 1000,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Control Panel
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Speed Control Slider
                      Row(
                        children: [
                          Icon(
                            Icons.slow_motion_video,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: kBlue,
                                inactiveTrackColor: Colors.grey[300],
                                thumbColor: kBlue,
                                overlayColor: kBlue.withOpacity(0.2),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                value: _playbackSpeed,
                                min: 0.5,
                                max: 3.0,
                                divisions: 5,
                                label: '${_playbackSpeed.toStringAsFixed(1)}x',
                                onChanged: (value) =>
                                    _updatePlaybackSpeed(value),
                              ),
                            ),
                          ),
                          Icon(
                            Icons.fast_forward,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_playbackSpeed.toStringAsFixed(1)}x',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Playback Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ControlButton(
                            icon: Icons.calendar_today,
                            onPressed: () => _pickDate(context),
                            color: kBlue,
                          ),
                          _ControlButton(
                            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                            onPressed: () => _isPlaying
                                ? _pausePlayback()
                                : (_currentIndex == 0
                                      ? _startPlayback(history)
                                      : _resumePlayback(history)),
                            color: kBlue,
                            isLarge: true,
                          ),
                          _ControlButton(
                            icon: Icons.stop,
                            onPressed: _stopPlayback,
                            color: Colors.red[400]!,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isLarge;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(isLarge ? 30 : 25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isLarge ? 30 : 25),
        child: Container(
          width: isLarge ? 60 : 50,
          height: isLarge ? 60 : 50,
          child: Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
        ),
      ),
    );
  }
}
