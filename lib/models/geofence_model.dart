class GeofenceModel {
  final int id;
  final String latitude;
  final String longitude;
  final int radius;
  final String name;
  final String numberPlate;
  final bool isInsideGeofence;
  final DateTime createdAt;
  final DateTime updatedAt;

  GeofenceModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.name,
    required this.numberPlate,
    required this.isInsideGeofence,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'] ?? 0,
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      radius: json['radius'] ?? 0,
      name: json['name'] ?? '',
      numberPlate: json['numberPlate'] ?? '',
      isInsideGeofence: json['isInsideGeofence'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'name': name,
      'numberPlate': numberPlate,
      'isInsideGeofence': isInsideGeofence,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<GeofenceModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => GeofenceModel.fromJson(json)).toList();
  }
}
