class DeviceRecord {
  final String spd;
  final String lg;
  final String lt;
  final String rg;
  final String course;
  final DateTime createdAt;

  /// Pre-parsed coordinate doubles — avoids repeated double.parse() on hot paths.
  final double latD;
  final double lngD;

  DeviceRecord({
    required this.spd,
    required this.lg,
    required this.lt,
    required this.rg,
    required this.course,
    required this.createdAt,
  })  : latD = double.tryParse(lt) ?? 0.0,
        lngD = double.tryParse(lg) ?? 0.0;

  bool get hasValidCoords =>
      latD >= -90 && latD <= 90 && lngD >= -180 && lngD <= 180 &&
      !(latD == 0.0 && lngD == 0.0);

  /// Factory method to create an instance from JSON
  factory DeviceRecord.fromJson(Map<String, dynamic> json) {
    return DeviceRecord(
      spd: json['spd'].toString().trim(),
      lg: json['lg'],
      lt: json['lt'],
      rg: json['rg'],
      course: json['course'].toString().trim(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'spd': spd,
      'lg': lg,
      'lt': lt,
      'rg': rg,
      'course': course,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Parse a list of JSON records
  static List<DeviceRecord> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => DeviceRecord.fromJson(json)).toList();
  }
}
