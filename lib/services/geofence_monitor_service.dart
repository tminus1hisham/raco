import 'dart:math';

import 'package:atom/models/geofence_model.dart';
import 'package:atom/services/api_service.dart';
import 'package:flutter/foundation.dart';

/// Monitors a vehicle's real-time position against its active geofences.
///
/// Usage:
/// 1. Call [initializeStates] once after fetching geofences, passing the
///    vehicle's last known position. This sets the initial inside/outside state
///    without triggering any breach events (cold-start safety).
/// 2. Call [updateLocation] on every MQTT location update. The service
///    evaluates each geofence and fires a breach report when the vehicle
///    transitions from inside → outside.
class GeofenceMonitorService {
  /// Minimum number of consecutive out-of-fence readings required before a
  /// breach is declared. Prevents false alarms from GPS jitter at the boundary.
  static const int _requiredConsecutiveOut = 3;

  /// After a breach fires, suppress re-triggering for this duration. Prevents
  /// spam if the vehicle hovers near the boundary.
  static const Duration _debounceDuration = Duration(seconds: 60);

  // geofenceId → is vehicle currently considered inside?
  final Map<int, bool> _insideState = {};

  // geofenceId → consecutive out-of-fence count (resets when vehicle re-enters)
  final Map<int, int> _consecutiveOutCount = {};

  // geofenceId → timestamp of the last breach event dispatched
  final Map<int, DateTime> _lastBreachTime = {};

  // ── Public API ──────────────────────────────────────────────────────────

  /// Sets the initial inside/outside state for every [geofences] entry based on
  /// the vehicle's current [vehicleLat]/[vehicleLng], without sending any
  /// breach notifications. Must be called once after loading geofences.
  void initializeStates(
    List<GeofenceModel> geofences,
    double vehicleLat,
    double vehicleLng,
  ) {
    for (final geofence in geofences) {
      final centerLat = double.tryParse(geofence.latitude) ?? 0.0;
      final centerLng = double.tryParse(geofence.longitude) ?? 0.0;
      final distance = haversineDistance(
        vehicleLat,
        vehicleLng,
        centerLat,
        centerLng,
      );
      _insideState[geofence.id] = distance <= geofence.radius.toDouble();
      _consecutiveOutCount[geofence.id] = 0;
    }
  }

  /// Called on every MQTT location update.
  ///
  /// Evaluates [vehicleLat]/[vehicleLng] against every entry in [geofences].
  /// When a transition from inside → outside is confirmed (after
  /// [_requiredConsecutiveOut] consecutive out-readings), a breach is reported
  /// to the backend via [ApiService.reportGeofenceBreach].
  void updateLocation(
    List<GeofenceModel> geofences,
    double vehicleLat,
    double vehicleLng,
    String numberPlate,
  ) {
    for (final geofence in geofences) {
      final centerLat = double.tryParse(geofence.latitude) ?? 0.0;
      final centerLng = double.tryParse(geofence.longitude) ?? 0.0;
      final distance = haversineDistance(
        vehicleLat,
        vehicleLng,
        centerLat,
        centerLng,
      );
      final isInsideNow = distance <= geofence.radius.toDouble();

      if (isInsideNow) {
        // Reset out-counter and mark as inside
        _consecutiveOutCount[geofence.id] = 0;
        final wasOutside =
            _insideState.containsKey(geofence.id) &&
            !_insideState[geofence.id]!;
        _insideState[geofence.id] = true;

        if (wasOutside) {
          // Vehicle re-entered — log for debugging
          debugPrint('[Geofence] ${geofence.name}: vehicle re-entered');
        }
      } else {
        // Vehicle is outside this geofence
        final outCount = (_consecutiveOutCount[geofence.id] ?? 0) + 1;
        _consecutiveOutCount[geofence.id] = outCount;

        if (outCount >= _requiredConsecutiveOut) {
          final previousState = _insideState[geofence.id];

          if (previousState == null) {
            // Cold start — vehicle was already outside before we started
            // monitoring. Set state without triggering a breach.
            _insideState[geofence.id] = false;
          } else if (previousState == true) {
            // Confirmed transition: inside → outside = BREACH
            _insideState[geofence.id] = false;
            _maybeTriggerBreach(geofence, vehicleLat, vehicleLng, numberPlate);
          }
          // else: vehicle was already outside — no-op
        }
      }
    }
  }

  /// Clears all tracked state. Call when navigating away from the live
  /// location screen or when the vehicle changes.
  void reset() {
    _insideState.clear();
    _consecutiveOutCount.clear();
    _lastBreachTime.clear();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  void _maybeTriggerBreach(
    GeofenceModel geofence,
    double lat,
    double lng,
    String numberPlate,
  ) {
    final now = DateTime.now();
    final lastBreach = _lastBreachTime[geofence.id];
    if (lastBreach != null && now.difference(lastBreach) < _debounceDuration) {
      // Still within debounce window — suppress
      return;
    }

    _lastBreachTime[geofence.id] = now;
    _consecutiveOutCount[geofence.id] = 0;

    debugPrint(
      '[Geofence] BREACH: ${geofence.name} | $numberPlate | '
      'lat=$lat lng=$lng | ${now.toUtc().toIso8601String()}',
    );

    // Fire-and-forget: report to backend which handles FCM dispatch
    ApiService.reportGeofenceBreach(
      geofenceId: geofence.id,
      numberPlate: numberPlate,
      latitude: lat.toString(),
      longitude: lng.toString(),
      exitTime: now.toUtc().toIso8601String(),
    ).catchError((Object e) {
      debugPrint('[Geofence] Failed to report breach: $e');
    });
  }

  // ── Haversine ────────────────────────────────────────────────────────────

  /// Returns great-circle distance in **metres**.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
