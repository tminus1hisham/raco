class LocationModel {
  final String latitude;
  final String longitude;
  final int radius;
  final String name;
  final String numberPlate;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.name,
    required this.numberPlate,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      radius: json['radius'] ?? 0,
      name: json['name'] ?? '',
      numberPlate: json['numberPlate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'name': name,
      'numberPlate': numberPlate,
    };
  }
}
