class DriverBehaviourReport {
  final double? safetyScore;
  final String? rating;
  final int overspeedEvents;
  final int recklessDrivingEvents;
  final int harshBrakingEvents;
  final int rapidAccelerationEvents;
  final int totalEvents;
  final double? averageSpeed;
  final double? topSpeed;
  final double? distanceKm;
  final String? reportUrl;
  final List<DriverBehaviourEvent> events;
  final bool responseHasData;

  const DriverBehaviourReport({
    required this.safetyScore,
    required this.rating,
    required this.overspeedEvents,
    required this.recklessDrivingEvents,
    required this.harshBrakingEvents,
    required this.rapidAccelerationEvents,
    required this.totalEvents,
    required this.averageSpeed,
    required this.topSpeed,
    required this.distanceKm,
    required this.reportUrl,
    required this.events,
    this.responseHasData = false,
  });

  bool get hasData =>
      safetyScore != null ||
      rating != null ||
      totalEvents > 0 ||
      averageSpeed != null ||
      topSpeed != null ||
      distanceKm != null ||
      events.isNotEmpty ||
      responseHasData;

  bool get hasTripData =>
      averageSpeed != null || topSpeed != null || distanceKm != null;

  factory DriverBehaviourReport.fromJson(dynamic payload) {
    final root = _asMap(payload);
    final envelope = _firstMap(root, const [
      'data',
      'result',
      'response',
    ]);
    final summary = _firstMap(
      envelope.isEmpty ? root : envelope,
      const [
        'summary',
        'driverBehaviour',
        'driverBehavior',
      ],
    );
    final source = {...root, ...envelope, ...summary};

    final rawEvents = _firstList(source, const [
      'events',
      'violations',
      'records',
      'devices',
      'dataPoints',
      'driverEvents',
      'data',
    ]);
    final eventMaps = rawEvents.whereType<Map>().map(_stringKeyMap).toList();
    final events = eventMaps.map(DriverBehaviourEvent.fromJson).toList();

    final speeds = eventMaps
        .map(
          (item) => _readDouble(item, const [
            'speed',
            'spd',
            'speedKph',
            'speedKmH',
          ]),
        )
        .whereType<double>()
        .toList();

    final overspeed =
        _readInt(source, const [
          'overspeedEvents',
          'overSpeedEvents',
          'overspeedCount',
          'overSpeedCount',
          'overspeed',
          'speedingCount',
        ]) ??
        events.where((event) => event.kind == DriverEventKind.overspeed).length;
    final braking =
        _readInt(source, const [
          'harshBrakingEvents',
          'harshBrakingCount',
          'harshBraking',
          'hardBrakingCount',
          'suddenBrakingCount',
        ]) ??
        events
            .where((event) => event.kind == DriverEventKind.harshBraking)
            .length;
    final reckless =
        _readInt(source, const [
          'recklessDrivingEvents',
          'recklessDrivingCount',
          'recklessDriving',
          'recklessCount',
        ]) ??
        events.where((event) => event.kind == DriverEventKind.reckless).length;
    final acceleration =
        _readInt(source, const [
          'rapidAccelerationEvents',
          'rapidAccelerationCount',
          'rapidAcceleration',
          'harshAccelerationCount',
          'harshAcceleration',
          'suddenAccelerationCount',
        ]) ??
        events
            .where((event) => event.kind == DriverEventKind.rapidAcceleration)
            .length;

    final explicitTotal = _readInt(source, const [
      'totalEvents',
      'eventCount',
      'totalViolations',
      'violationCount',
    ]);
    final countedTotal = overspeed + reckless + braking + acceleration;

    return DriverBehaviourReport(
      safetyScore: _readDouble(source, const [
        'safetyScore',
        'driverScore',
        'performanceScore',
        'score',
      ]),
      rating: _readRating(source),
      overspeedEvents: overspeed,
      recklessDrivingEvents: reckless,
      harshBrakingEvents: braking,
      rapidAccelerationEvents: acceleration,
      totalEvents:
          explicitTotal ?? (countedTotal > 0 ? countedTotal : events.length),
      averageSpeed:
          _readDouble(source, const ['averageSpeed', 'avgSpeed']) ??
          (speeds.isEmpty
              ? null
              : speeds.reduce((a, b) => a + b) / speeds.length),
      topSpeed:
          _readDouble(source, const ['topSpeed', 'maxSpeed', 'maximumSpeed']) ??
          (speeds.isEmpty
              ? null
              : speeds.reduce((a, b) => a > b ? a : b)),
      distanceKm: _readDouble(source, const [
        'distanceKm',
        'totalDistance',
        'distance',
        'distanceTravelled',
        'distanceTraveled',
      ]),
      reportUrl: _readString(source, const ['reportUrl', 'url']),
      events: events,
      responseHasData: _hasRecognizedValue(source),
    );
  }
}

enum DriverEventKind {
  overspeed,
  reckless,
  harshBraking,
  rapidAcceleration,
  other,
}

class DriverBehaviourEvent {
  final DriverEventKind kind;
  final String title;
  final String? occurredAt;
  final String? location;
  final double? speed;

  const DriverBehaviourEvent({
    required this.kind,
    required this.title,
    required this.occurredAt,
    required this.location,
    required this.speed,
  });

  factory DriverBehaviourEvent.fromJson(Map<String, dynamic> json) {
    final rawType =
        _readString(json, const [
          'type',
          'eventType',
          'violationType',
          'name',
          'title',
        ]) ??
        'Driving event';
    final normalized = rawType.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final kind = normalized.contains('overspeed') ||
            normalized.contains('speeding')
        ? DriverEventKind.overspeed
        : normalized.contains('reckless')
        ? DriverEventKind.reckless
        : normalized.contains('brak')
        ? DriverEventKind.harshBraking
        : normalized.contains('accel')
        ? DriverEventKind.rapidAcceleration
        : DriverEventKind.other;

    return DriverBehaviourEvent(
      kind: kind,
      title: rawType,
      occurredAt: _readString(json, const [
        'occurredAt',
        'eventTime',
        'dateTime',
        'timestamp',
        'createdAt',
        'date',
      ]),
      location: _readString(json, const [
        'location',
        'address',
        'place',
      ]),
      speed: _readDouble(json, const [
        'speed',
        'spd',
        'speedKph',
        'speedKmH',
      ]),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return _stringKeyMap(value);
  if (value is List) return {'events': value};
  return const {};
}

Map<String, dynamic> _stringKeyMap(Map value) => value.map(
  (key, dynamic item) => MapEntry(key.toString(), item),
);

Map<String, dynamic> _firstMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  final value = _readValue(json, keys);
  return value is Map ? _stringKeyMap(value) : const {};
}

List<dynamic> _firstList(Map<String, dynamic> json, List<String> keys) {
  final direct = _readValue(json, keys);
  if (direct is List) return direct;

  for (final value in json.values) {
    if (value is Map) {
      final nested = _firstList(_stringKeyMap(value), keys);
      if (nested.isNotEmpty) return nested;
    }
  }
  return const [];
}

dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
    final normalizedKey = _normalizeKey(key);
    for (final entry in json.entries) {
      if (_normalizeKey(entry.key) == normalizedKey && entry.value != null) {
        return entry.value;
      }
    }
  }
  return null;
}

bool _hasRecognizedValue(Map<String, dynamic> json) {
  const keys = [
    'safetyScore',
    'driverScore',
    'performanceScore',
    'score',
    'rating',
    'overspeedEvents',
    'overSpeedCount',
    'recklessDrivingCount',
    'harshBrakingCount',
    'rapidAccelerationCount',
    'harshAccelerationCount',
    'totalEvents',
    'eventCount',
    'averageSpeed',
    'topSpeed',
    'maxSpeed',
    'totalDistance',
  ];
  return _readValue(json, keys) != null;
}

String? _readRating(Map<String, dynamic> json) {
  final rating = _readString(json, const [
    'rating',
    'driverBehaviour',
    'driverBehavior',
    'behaviour',
    'behavior',
  ]);
  if (rating != null) return rating;

  final status = _readString(json, const ['status']);
  const envelopeStatuses = {'success', 'succeeded', 'ok'};
  return status != null && !envelopeStatuses.contains(status.toLowerCase())
      ? status
      : null;
}

String _normalizeKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

String? _readString(Map<String, dynamic> json, List<String> keys) {
  final value = _readValue(json, keys);
  if (value == null || value is Map || value is List) return null;
  final text = value.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  final value = _readValue(json, keys);
  if (value is num) return value.toDouble();
  if (value is String) {
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(value);
    return match == null ? null : double.tryParse(match.group(0)!);
  }
  return null;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readDouble(json, keys);
  return value?.round();
}
