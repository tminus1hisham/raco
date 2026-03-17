import 'dart:math' as math;

class GpsDataCleaner {
  // Maximum realistic speed in km/h (adjust based on vehicle type)
  static const double maxRealisticSpeed = 180.0;

  // Maximum acceleration in m/s² (0 to 100km/h in ~3 seconds = ~9.3 m/s²)
  static const double maxAcceleration = 15.0;

  // Minimum significant movement in meters (filters stationary drift)
  static const double minSignificantMovement = 5.0;

  // Distance threshold for outlier detection (in meters)
  static const double maxDistanceJump = 500.0;

  /// Main cleaning function - applies multiple filters
  static List<dynamic> cleanGpsData(List<dynamic> rawHistory) {
    if (rawHistory.isEmpty) return rawHistory;

    List<dynamic> cleaned = List.from(rawHistory);

    // Step 1: Remove invalid coordinates
    cleaned = _removeInvalidCoordinates(cleaned);

    // Step 2: Remove impossible speed jumps
    cleaned = _filterBySpeed(cleaned);

    // Step 3: Remove distance outliers
    cleaned = _filterDistanceOutliers(cleaned);

    // Step 4: Filter stationary drift
    cleaned = _filterStationaryDrift(cleaned);

    // Step 5: Apply Kalman-like smoothing
    cleaned = _applySimpleSmoothing(cleaned);

    return cleaned;
  }

  /// Remove points with invalid or missing coordinates
  static List<dynamic> _removeInvalidCoordinates(List<dynamic> history) {
    return history.where((record) {
      final lat = double.tryParse(record.lt.toString());
      final lng = double.tryParse(record.lg.toString());

      if (lat == null || lng == null) return false;

      // Check if coordinates are within valid ranges
      return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    }).toList();
  }

  /// Filter out points that would require impossible speeds
  static List<dynamic> _filterBySpeed(List<dynamic> history) {
    if (history.length < 2) return history;

    List<dynamic> filtered = [history[0]];

    for (int i = 1; i < history.length; i++) {
      final prev = filtered.last;
      final current = history[i];

      final distance = _calculateDistance(
        double.parse(prev.lt),
        double.parse(prev.lg),
        double.parse(current.lt),
        double.parse(current.lg),
      );

      // Calculate time difference in hours
      final prevTime = DateTime.parse(prev.createdAt.toString());
      final currentTime = DateTime.parse(current.createdAt.toString());
      final timeDiff = currentTime.difference(prevTime).inSeconds / 3600.0;

      if (timeDiff > 0) {
        final speed = distance / timeDiff; // km/h

        // Keep point if speed is realistic
        if (speed <= maxRealisticSpeed) {
          filtered.add(current);
        }
      } else {
        // If timestamps are same, keep the point
        filtered.add(current);
      }
    }

    return filtered;
  }

  /// Filter out sudden distance jumps (outliers)
  static List<dynamic> _filterDistanceOutliers(List<dynamic> history) {
    if (history.length < 2) return history;

    List<dynamic> filtered = [history[0]];

    for (int i = 1; i < history.length; i++) {
      final prev = filtered.last;
      final current = history[i];

      final distance = _calculateDistance(
        double.parse(prev.lt),
        double.parse(prev.lg),
        double.parse(current.lt),
        double.parse(current.lg),
      );

      // Convert to meters
      final distanceMeters = distance * 1000;

      // Keep point if distance jump is reasonable
      if (distanceMeters <= maxDistanceJump) {
        filtered.add(current);
      }
    }

    return filtered;
  }

  /// Remove small movements when vehicle is stationary
  static List<dynamic> _filterStationaryDrift(List<dynamic> history) {
    if (history.length < 2) return history;

    List<dynamic> filtered = [history[0]];

    for (int i = 1; i < history.length; i++) {
      final prev = filtered.last;
      final current = history[i];

      final speed = double.tryParse(current.spd.toString()) ?? 0.0;
      final prevSpeed = double.tryParse(prev.spd.toString()) ?? 0.0;

      // If both speeds are 0, check if movement is significant
      if (speed < 1.0 && prevSpeed < 1.0) {
        final distance = _calculateDistance(
          double.parse(prev.lt),
          double.parse(prev.lg),
          double.parse(current.lt),
          double.parse(current.lg),
        );

        final distanceMeters = distance * 1000;

        // Only add if movement is significant or speed changes
        if (distanceMeters >= minSignificantMovement) {
          filtered.add(current);
        }
      } else {
        filtered.add(current);
      }
    }

    return filtered;
  }

  /// Apply simple smoothing (moving average for coordinates)
  static List<dynamic> _applySimpleSmoothing(List<dynamic> history) {
    if (history.length < 3) return history;

    // Use a window of 3 points for smoothing
    List<dynamic> smoothed = [history[0]]; // Keep first point as-is

    for (int i = 1; i < history.length - 1; i++) {
      final current = history[i];

      // Create a modified record (you'll need to adjust based on your data structure)
      // This is a simplified example - adapt to your actual record structure
      var smoothedRecord = current;
      // Note: You may need to create a copy and update the coordinates
      // depending on how your record objects work

      smoothed.add(smoothedRecord);
    }

    smoothed.add(history.last); // Keep last point as-is

    return smoothed;
  }

  /// Calculate distance between two coordinates in kilometers
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371.0; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Advanced: Kalman Filter implementation (optional, more complex)
  static List<dynamic> applyKalmanFilter(List<dynamic> history) {
    if (history.length < 2) return history;

    // Kalman filter parameters
    double processNoise = 0.001; // Q - how much we trust our model
    double measurementNoise = 0.1; // R - how much we trust measurements
    double estimationError = 1.0; // P - initial uncertainty

    List<dynamic> filtered = [];

    // Initialize with first point
    double latEstimate = double.parse(history[0].lt);
    double lngEstimate = double.parse(history[0].lg);
    filtered.add(history[0]);

    for (int i = 1; i < history.length; i++) {
      final current = history[i];
      final latMeasurement = double.parse(current.lt);
      final lngMeasurement = double.parse(current.lg);

      // Prediction step (assume no movement model, just maintain position)
      double latPrediction = latEstimate;
      double lngPrediction = lngEstimate;
      double predictionError = estimationError + processNoise;

      // Update step
      double kalmanGainLat =
          predictionError / (predictionError + measurementNoise);
      double kalmanGainLng =
          predictionError / (predictionError + measurementNoise);

      latEstimate =
          latPrediction + kalmanGainLat * (latMeasurement - latPrediction);
      lngEstimate =
          lngPrediction + kalmanGainLng * (lngMeasurement - lngPrediction);

      estimationError = (1 - kalmanGainLat) * predictionError;

      // Note: You'll need to create updated records with filtered coordinates
      // This is simplified - adjust based on your data structure
      filtered.add(current);
    }

    return filtered;
  }

  /// Simplify path using Douglas-Peucker algorithm
  static List<dynamic> simplifyPath(List<dynamic> history, double epsilon) {
    if (history.length < 3) return history;

    // Find the point with maximum distance from line segment
    double maxDistance = 0;
    int maxIndex = 0;

    final start = history.first;
    final end = history.last;

    for (int i = 1; i < history.length - 1; i++) {
      final point = history[i];
      final distance = _perpendicularDistance(
        double.parse(point.lt),
        double.parse(point.lg),
        double.parse(start.lt),
        double.parse(start.lg),
        double.parse(end.lt),
        double.parse(end.lg),
      );

      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance is greater than epsilon, recursively simplify
    if (maxDistance > epsilon) {
      final left = simplifyPath(history.sublist(0, maxIndex + 1), epsilon);
      final right = simplifyPath(history.sublist(maxIndex), epsilon);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [start, end];
    }
  }

  /// Calculate perpendicular distance from point to line segment
  static double _perpendicularDistance(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final dx = x2 - x1;
    final dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      return math.sqrt((px - x1) * (px - x1) + (py - y1) * (py - y1));
    }

    final t = ((px - x1) * dx + (py - y1) * dy) / (dx * dx + dy * dy);
    final tClamped = math.max(0, math.min(1, t));

    final nearestX = x1 + tClamped * dx;
    final nearestY = y1 + tClamped * dy;

    return math.sqrt(
      (px - nearestX) * (px - nearestX) + (py - nearestY) * (py - nearestY),
    );
  }
}
