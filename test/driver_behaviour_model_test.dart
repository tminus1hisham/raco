import 'package:atom/models/driver_behaviour_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverBehaviourReport', () {
    test('reads a nested summary and event list', () {
      final report = DriverBehaviourReport.fromJson({
        'data': {
          'safetyScore': 86.5,
          'status': 'Safe',
          'overSpeedCount': 2,
          'harshBrakingCount': 1,
          'rapidAccelerationCount': 3,
          'averageSpeed': '42.4 km/h',
          'maxSpeed': 91,
          'totalDistance': '126.8 km',
          'events': [
            {
              'eventType': 'Overspeed',
              'speed': '91',
              'createdAt': '2026-09-12T10:30:00Z',
            },
          ],
        },
      });

      expect(report.safetyScore, 86.5);
      expect(report.rating, 'Safe');
      expect(report.overspeedEvents, 2);
      expect(report.harshBrakingEvents, 1);
      expect(report.rapidAccelerationEvents, 3);
      expect(report.totalEvents, 6);
      expect(report.averageSpeed, 42.4);
      expect(report.topSpeed, 91);
      expect(report.distanceKm, 126.8);
      expect(report.events.single.kind, DriverEventKind.overspeed);
    });

    test('derives fallback metrics from a raw record list', () {
      final report = DriverBehaviourReport.fromJson([
        {'type': 'Harsh braking', 'spd': '30'},
        {'type': 'Rapid acceleration', 'spd': 50},
      ]);

      expect(report.harshBrakingEvents, 1);
      expect(report.rapidAccelerationEvents, 1);
      expect(report.totalEvents, 2);
      expect(report.averageSpeed, 40);
      expect(report.topSpeed, 50);
      expect(report.hasData, isTrue);
    });

    test('treats an empty response as no data', () {
      final report = DriverBehaviourReport.fromJson({});

      expect(report.hasData, isFalse);
      expect(report.totalEvents, 0);
      expect(report.events, isEmpty);
    });

    test('keeps a valid zero-event report visible', () {
      final report = DriverBehaviourReport.fromJson({
        'over_speed_count': 0,
        'reckless_driving_count': 0,
      });

      expect(report.hasData, isTrue);
      expect(report.totalEvents, 0);
      expect(report.overspeedEvents, 0);
      expect(report.recklessDrivingEvents, 0);
    });

    test('maps the production recklessDrivingCount field', () {
      final report = DriverBehaviourReport.fromJson({
        'overSpeedCount': 4,
        'recklessDrivingCount': 2,
      });

      expect(report.overspeedEvents, 4);
      expect(report.recklessDrivingEvents, 2);
      expect(report.totalEvents, 6);
    });
  });
}
