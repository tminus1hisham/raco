class DeviceRecord {
  final String spd;
  final String lg;
  final String lt;
  final String rg;
  final String course;
  final DateTime createdAt;

  DeviceRecord({
    required this.spd,
    required this.lg,
    required this.lt,
    required this.rg,
    required this.course,
    required this.createdAt,
  });

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
